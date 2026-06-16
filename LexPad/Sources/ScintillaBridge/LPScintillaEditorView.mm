#import "LPScintillaEditorView.h"

#import <Scintilla/ScintillaView.h>
#import <Scintilla/Scintilla.h>
#import <Scintilla/ILexer.h>
#import "SciLexer.h"
#import "Lexilla.h"

static BOOL gScintillaEngineAvailable = NO;

@interface LPScintillaEditorView () <ScintillaNotificationProtocol>
@property (nonatomic, strong) ScintillaView *editor;
@property (nonatomic, assign) BOOL suppressChangeNotification;
@property (nonatomic, assign) BOOL codeFoldingEnabled;
@property (nonatomic, assign) BOOL showChangeHistoryEnabled;
@property (nonatomic, assign) BOOL darkModeActive;
@property (nonatomic, strong, nullable) NSColor *editorBackground;
@property (nonatomic, assign) NSInteger lastReportedLine;
@property (nonatomic, assign) NSInteger lastReportedColumn;
@property (nonatomic, assign) NSInteger lastReportedScrollLine;
@property (nonatomic, assign) BOOL autoCompletionEnabled;
@property (nonatomic, assign) NSInteger autoCompletionMinLength;
@property (nonatomic, assign) BOOL braceMatchingEnabled;
@property (nonatomic, assign) BOOL showLineNumbersEnabled;
@property (nonatomic, assign) int lastLineNumberMarginWidth;
@end

static const int kMarkStyleBase = 10;
static const int kMarkStyleCount = 5;

static const int kChangeUnsavedMarker = 20;
static const int kChangeSavedMarker = 21;

static NSColor *colorFromTuple(double r, double g, double b) {
    return [NSColor colorWithRed:r green:g blue:b alpha:1];
}

static NSColor *colorForMarkStyle(int style) {
    switch (style) {
        case 1: return [NSColor systemRedColor];
        case 2: return [NSColor systemGreenColor];
        case 3: return [NSColor systemBlueColor];
        case 4: return [NSColor systemCyanColor];
        case 5: return [NSColor systemOrangeColor];
        default: return [NSColor systemBlueColor];
    }
}

static NSColor *mutedLineNumberColor(NSColor *foreground, BOOL darkMode) {
    return [foreground colorWithAlphaComponent:darkMode ? 0.45 : 0.55];
}

static long scintillaPackedRGBFromColor(NSColor *color) {
    NSColor *deviceColor = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    long red = (long)lround(deviceColor.redComponent * 255.0);
    long green = (long)lround(deviceColor.greenComponent * 255.0);
    long blue = (long)lround(deviceColor.blueComponent * 255.0);
    return (blue << 16) + (green << 8) + red;
}

static void applyCaretAndLineHighlight(ScintillaView *editor, NSColor *foreground, NSColor *background) {
    NSColor *caretColor = foreground;
    CGFloat fr = 0, fg = 0, fb = 0, br = 0, bg = 0, bb = 0;
    NSColor *fgRGB = [foreground colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    NSColor *bgRGB = [background colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    [fgRGB getRed:&fr green:&fg blue:&fb alpha:NULL];
    [bgRGB getRed:&br green:&bg blue:&bb alpha:NULL];
    double fgLum = 0.299 * fr + 0.587 * fg + 0.114 * fb;
    double bgLum = 0.299 * br + 0.587 * bg + 0.114 * bb;
    if (fabs(fgLum - bgLum) < 0.15) {
        caretColor = bgLum < 0.45 ? [NSColor whiteColor] : [NSColor blackColor];
    }

    // SCI_SETCARETFORE / SCI_SETCARETWIDTH / SCI_SETCARETSTYLE use wParam (not lParam).
    long caretRGB = scintillaPackedRGBFromColor(caretColor);
    [editor message:SCI_SETCARETFORE wParam:caretRGB lParam:0];
    [editor setGeneralProperty:SCI_SETCARETWIDTH value:2];
    [editor setGeneralProperty:SCI_SETCARETSTYLE value:CARETSTYLE_LINE];

    NSColor *lineTint = bgLum < 0.45 ? [NSColor whiteColor] : [NSColor blackColor];
    long lineRGB = scintillaPackedRGBFromColor(lineTint);
    [editor message:SCI_SETCARETLINEVISIBLE wParam:1 lParam:0];
    [editor message:SCI_SETCARETLINEBACK wParam:lineRGB lParam:0];
    [editor message:SCI_SETCARETLINEBACKALPHA wParam:28 lParam:0];
}

@implementation LPScintillaEditorView

+ (void)load {
    @try {
        ScintillaView *probe = [[ScintillaView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)];
        gScintillaEngineAvailable = probe != nil;
        (void)probe;
    } @catch (...) {
        gScintillaEngineAvailable = NO;
    }
}

+ (BOOL)isEngineAvailable {
    return gScintillaEngineAvailable;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _braceMatchingEnabled = YES;
        _columnSelectionMode = NO;
        _autoCompletionEnabled = YES;
        _autoCompletionMinLength = 3;
        _editor = [[ScintillaView alloc] initWithFrame:self.bounds];
        _editor.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        _editor.delegate = self;
        [self addSubview:_editor];

        [_editor setGeneralProperty:SCI_SETMULTIPLESELECTION parameter:0 value:1];
        [_editor setGeneralProperty:SCI_SETADDITIONALSELECTIONTYPING parameter:0 value:1];

        NSEventMask mask = NSEventMaskLeftMouseDown | NSEventMaskFlagsChanged;
        [NSEvent addLocalMonitorForEventsMatchingMask:mask handler:^NSEvent *(NSEvent *event) {
            if (event.type == NSEventTypeFlagsChanged) {
                [self updateSelectionModeForEvent:event];
                return event;
            }
            if (event.type == NSEventTypeLeftMouseDown &&
                (event.modifierFlags & NSEventModifierFlagCommand) &&
                [self.window.firstResponder isKindOfClass:[NSClipView class]]) {
                NSPoint pt = [_editor.scrollView.contentView convertPoint:event.locationInWindow fromView:nil];
                long pos = [_editor getGeneralProperty:SCI_POSITIONFROMPOINT parameter:(long)pt.x extra:(long)pt.y];
                if (pos >= 0) {
                    [_editor message:SCI_ADDSELECTION wParam:pos lParam:pos];
                    return nil;
                }
            }
            if (event.type == NSEventTypeLeftMouseDown &&
                (event.modifierFlags & NSEventModifierFlagOption)) {
                self.columnSelectionMode = YES;
                [self applySelectionMode];
            }
            return event;
        }];

        [self configureAppearanceWithFontSize:13 wordWrap:YES showLineNumbers:YES darkMode:NO tabSize:4 useSpacesForTab:YES codeFolding:YES showChangeHistory:YES themeName:@"classic" virtualSpaceEnabled:NO themeColors:nil];
    }
    return self;
}

- (void)updateSelectionModeForEvent:(NSEvent *)event {
    if (!(event.modifierFlags & NSEventModifierFlagOption) && self.columnSelectionMode) {
        self.columnSelectionMode = NO;
        [self applySelectionMode];
    }
}

- (void)applySelectionMode {
    long mode = self.columnSelectionMode ? SC_SEL_RECTANGLE : SC_SEL_STREAM;
    [_editor setGeneralProperty:SCI_SETSELECTIONMODE parameter:0 value:mode];
}

- (NSScrollView *)scrollView {
    return _editor.scrollView;
}

- (NSString *)string {
    return _editor.string ?: @"";
}

- (void)setString:(NSString *)string {
    if ([self.string isEqualToString:string ?: @""]) return;
    self.suppressChangeNotification = YES;
    [_editor setString:string ?: @""];
    self.suppressChangeNotification = NO;
    [self updateLineNumberMarginWidth];
}

- (BOOL)isEditable {
    return _editor.isEditable;
}

- (void)setEditable:(BOOL)editable {
    [_editor setEditable:editable];
}

- (NSRange)selectedRange {
    return [_editor selectedRange];
}

- (void)setSelectedRange:(NSRange)range {
    [_editor message:SCI_SETSELECTIONSTART wParam:range.location];
    [_editor message:SCI_SETSELECTIONEND wParam:NSMaxRange(range)];
}

- (void)addSelectionRange:(NSRange)range {
    long caret = NSMaxRange(range);
    long anchor = range.location;
    [_editor message:SCI_ADDSELECTION wParam:caret lParam:anchor];
}

- (void)selectNextOccurrenceMatchCase:(BOOL)matchCase wholeWord:(BOOL)wholeWord {
    NSString *text = self.string ?: @"";
    NSRange sel = self.selectedRange;
    if (sel.length == 0) {
        sel = [self wordRangeAtPosition:sel.location inText:text];
        if (sel.length == 0) return;
        [self setSelectedRange:sel];
    }
    NSString *needle = [text substringWithRange:sel];
    NSUInteger searchAfter = NSMaxRange(sel);
    NSRange found = [self findOccurrenceOf:needle
                                     inText:text
                                      after:searchAfter
                                  matchCase:matchCase
                                  wholeWord:wholeWord
                                 wrapAround:YES];
    if (found.location == NSNotFound) return;
    [self addSelectionRange:found];
}

- (NSRange)wordRangeAtPosition:(NSUInteger)position inText:(NSString *)text {
    if (text.length == 0) return NSMakeRange(NSNotFound, 0);
    NSUInteger start = position;
    NSUInteger end = position;
    NSCharacterSet *set = [NSCharacterSet alphanumericCharacterSet];
    NSMutableCharacterSet *wordSet = [set mutableCopy];
    [wordSet addCharactersInString:@"_"];
    while (start > 0) {
        unichar ch = [text characterAtIndex:start - 1];
        if (![wordSet characterIsMember:ch]) break;
        start--;
    }
    while (end < text.length) {
        unichar ch = [text characterAtIndex:end];
        if (![wordSet characterIsMember:ch]) break;
        end++;
    }
    if (end <= start) return NSMakeRange(NSNotFound, 0);
    return NSMakeRange(start, end - start);
}

- (BOOL)isWholeWordRange:(NSRange)range inText:(NSString *)text {
    NSCharacterSet *set = [NSCharacterSet alphanumericCharacterSet];
    NSMutableCharacterSet *wordSet = [set mutableCopy];
    [wordSet addCharactersInString:@"_"];
    if (range.location > 0) {
        unichar ch = [text characterAtIndex:range.location - 1];
        if ([wordSet characterIsMember:ch]) return NO;
    }
    NSUInteger end = NSMaxRange(range);
    if (end < text.length) {
        unichar ch = [text characterAtIndex:end];
        if ([wordSet characterIsMember:ch]) return NO;
    }
    return YES;
}

- (NSRange)findOccurrenceOf:(NSString *)needle
                     inText:(NSString *)text
                      after:(NSUInteger)searchAfter
                  matchCase:(BOOL)matchCase
                  wholeWord:(BOOL)wholeWord
                 wrapAround:(BOOL)wrapAround {
    NSStringCompareOptions opts = matchCase ? 0 : NSCaseInsensitiveSearch;
    NSRange tail = NSMakeRange(MIN(searchAfter, text.length), text.length - MIN(searchAfter, text.length));
    NSRange found = [self scanFor:needle inText:text range:tail options:opts wholeWord:wholeWord];
    if (found.location != NSNotFound) return found;
    if (!wrapAround || searchAfter == 0) return NSMakeRange(NSNotFound, 0);
    NSRange head = NSMakeRange(0, MIN(searchAfter, text.length));
    return [self scanFor:needle inText:text range:head options:opts wholeWord:wholeWord];
}

- (NSRange)scanFor:(NSString *)needle
            inText:(NSString *)text
             range:(NSRange)range
           options:(NSStringCompareOptions)options
         wholeWord:(BOOL)wholeWord {
    NSUInteger start = range.location;
    NSUInteger end = NSMaxRange(range);
    while (start < end) {
        NSRange search = NSMakeRange(start, end - start);
        NSRange found = [text rangeOfString:needle options:options range:search];
        if (found.location == NSNotFound) break;
        if (!wholeWord || [self isWholeWordRange:found inText:text]) return found;
        start = found.location + MAX(found.length, 1);
    }
    return NSMakeRange(NSNotFound, 0);
}

- (void)applyGutterDividerMarginFoldActive:(BOOL)foldActive {
    if (foldActive && self.codeFoldingEnabled) {
        [_editor setGeneralProperty:SCI_SETMARGINTYPEN parameter:1 value:SC_MARGIN_SYMBOL];
        [_editor setGeneralProperty:SCI_SETMARGINMASKN parameter:1 value:SC_MASK_FOLDERS];
        [_editor setGeneralProperty:SCI_SETMARGINSENSITIVEN parameter:1 value:1];
        return;
    }
    [_editor setGeneralProperty:SCI_SETMARGINTYPEN parameter:1 value:SC_MARGIN_FORE];
    [_editor setGeneralProperty:SCI_SETMARGINWIDTHN parameter:1 value:1];
    [_editor setGeneralProperty:SCI_SETMARGINMASKN parameter:1 value:0];
    [_editor setGeneralProperty:SCI_SETMARGINSENSITIVEN parameter:1 value:0];
    if (self.editorBackground) {
        [_editor setColorProperty:SCI_SETMARGINBACKN parameter:1 value:self.editorBackground];
    }
}

- (void)configureAppearanceWithFontSize:(CGFloat)fontSize
                               wordWrap:(BOOL)wordWrap
                        showLineNumbers:(BOOL)showLineNumbers
                               darkMode:(BOOL)darkMode
                                tabSize:(NSInteger)tabSize
                         useSpacesForTab:(BOOL)useSpacesForTab
                            codeFolding:(BOOL)codeFolding
                       showChangeHistory:(BOOL)showChangeHistory
                               themeName:(NSString *)themeName
                      virtualSpaceEnabled:(BOOL)virtualSpaceEnabled
                            themeColors:(NSDictionary *)themeColors {
    self.darkModeActive = darkMode;
    self.codeFoldingEnabled = codeFolding;
    self.showChangeHistoryEnabled = showChangeHistory;

    [_editor suspendDrawing:YES];

    [_editor setStringProperty:SCI_STYLESETFONT parameter:STYLE_DEFAULT value:@"Menlo"];
    [_editor setGeneralProperty:SCI_STYLESETSIZE parameter:STYLE_DEFAULT value:(long)fontSize];
    [_editor setGeneralProperty:SCI_STYLECLEARALL parameter:0 value:0];

    NSColor *foreground = darkMode ? [NSColor colorWithWhite:0.92 alpha:1] : [NSColor textColor];
    NSColor *background = darkMode ? [NSColor colorWithWhite:0.11 alpha:1] : [NSColor textBackgroundColor];
    NSColor *comment = darkMode ? [NSColor colorWithRed:0.42 green:0.47 blue:0.53 alpha:1] : [NSColor colorWithRed:0 green:0.53 blue:0 alpha:1];
    NSColor *keyword = darkMode ? [NSColor colorWithRed:0.67 green:0.39 blue:0.98 alpha:1] : [NSColor colorWithRed:0.55 green:0 blue:0.75 alpha:1];
    NSColor *stringColor = darkMode ? [NSColor colorWithRed:0.98 green:0.43 blue:0.42 alpha:1] : [NSColor colorWithRed:0.77 green:0.10 blue:0.09 alpha:1];
    NSColor *numberColor = darkMode ? [NSColor colorWithRed:0.82 green:0.60 blue:0.32 alpha:1] : [NSColor colorWithRed:0.11 green:0.21 blue:0.85 alpha:1];

    if (themeColors.count > 0) {
        NSArray *bg = themeColors[@"bg"];
        NSArray *fg = themeColors[@"fg"];
        NSArray *kw = themeColors[@"kw"];
        NSArray *cm = themeColors[@"cm"];
        NSArray *st = themeColors[@"st"];
        NSArray *nu = themeColors[@"nu"];
        if (bg.count == 3 && fg.count == 3) {
            background = colorFromTuple([bg[0] doubleValue], [bg[1] doubleValue], [bg[2] doubleValue]);
            foreground = colorFromTuple([fg[0] doubleValue], [fg[1] doubleValue], [fg[2] doubleValue]);
            if (kw.count == 3) keyword = colorFromTuple([kw[0] doubleValue], [kw[1] doubleValue], [kw[2] doubleValue]);
            if (cm.count == 3) comment = colorFromTuple([cm[0] doubleValue], [cm[1] doubleValue], [cm[2] doubleValue]);
            if (st.count == 3) stringColor = colorFromTuple([st[0] doubleValue], [st[1] doubleValue], [st[2] doubleValue]);
            if (nu.count == 3) numberColor = colorFromTuple([nu[0] doubleValue], [nu[1] doubleValue], [nu[2] doubleValue]);
        }
    }
    NSColor *foldFore = darkMode ? [NSColor colorWithWhite:0.65 alpha:1] : [NSColor secondaryLabelColor];

    self.editorBackground = background;
    [_editor setColorProperty:SCI_STYLESETBACK parameter:STYLE_DEFAULT value:background];
    [_editor setColorProperty:SCI_SETSELBACK parameter:1 value:[NSColor selectedTextBackgroundColor]];

    for (int style = 0; style <= 63; style++) {
        [_editor setColorProperty:SCI_STYLESETFORE parameter:style value:foreground];
        [_editor setColorProperty:SCI_STYLESETBACK parameter:style value:background];
    }
    int commentStyles[] = {SCE_C_COMMENT, SCE_C_COMMENTLINE, SCE_C_COMMENTDOC, SCE_C_COMMENTLINEDOC, SCE_C_COMMENTDOCKEYWORD, SCE_C_COMMENTDOCKEYWORDERROR};
    for (size_t i = 0; i < sizeof(commentStyles) / sizeof(commentStyles[0]); i++) {
        [_editor setColorProperty:SCI_STYLESETFORE parameter:commentStyles[i] value:comment];
    }
    int keywordStyles[] = {SCE_C_WORD, SCE_C_WORD2, SCE_C_PREPROCESSOR};
    for (size_t i = 0; i < sizeof(keywordStyles) / sizeof(keywordStyles[0]); i++) {
        [_editor setColorProperty:SCI_STYLESETFORE parameter:keywordStyles[i] value:keyword];
    }
    int stringStyles[] = {SCE_C_STRING, SCE_C_CHARACTER, SCE_C_STRINGEOL};
    for (size_t i = 0; i < sizeof(stringStyles) / sizeof(stringStyles[0]); i++) {
        [_editor setColorProperty:SCI_STYLESETFORE parameter:stringStyles[i] value:stringColor];
    }
    [_editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_NUMBER value:numberColor];

    [_editor setGeneralProperty:SCI_SETTABWIDTH parameter:0 value:tabSize];
    [_editor setGeneralProperty:SCI_SETINDENT parameter:0 value:tabSize];
    [_editor setGeneralProperty:SCI_SETUSETABS parameter:0 value:useSpacesForTab ? 0 : 1];
    [_editor setGeneralProperty:SCI_SETWRAPMODE parameter:0 value:wordWrap ? SC_WRAP_WORD : SC_WRAP_NONE];
    self.showLineNumbersEnabled = showLineNumbers;
    self.lastLineNumberMarginWidth = -1;
    [_editor setGeneralProperty:SCI_SETMARGINLEFT parameter:0 value:0];
    [_editor setGeneralProperty:SCI_SETMARGINTYPEN parameter:0 value:showLineNumbers ? SC_MARGIN_NUMBER : SC_MARGIN_BACK];
    [_editor setColorProperty:SCI_STYLESETFORE parameter:STYLE_LINENUMBER value:mutedLineNumberColor(foreground, darkMode)];
    [_editor setColorProperty:SCI_STYLESETBACK parameter:STYLE_LINENUMBER value:background];
    [_editor setColorProperty:SCI_SETMARGINBACKN parameter:0 value:background];
    [self updateLineNumberMarginWidth];

    applyCaretAndLineHighlight(_editor, foreground, background);

    if (codeFolding) {
        [self applyGutterDividerMarginFoldActive:NO];
        // Width becomes 14 when a fold-capable lexer is applied (setLexerLanguage).
        for (int i = SC_MARKNUM_FOLDEREND; i <= SC_MARKNUM_FOLDEROPEN; i++) {
            [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:i value:SC_MARK_EMPTY];
        }
        [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDER value:SC_MARK_PLUS];
        [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEROPEN value:SC_MARK_MINUS];
        [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERSUB value:SC_MARK_EMPTY];
        [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERTAIL value:SC_MARK_EMPTY];
        [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEREND value:SC_MARK_EMPTY];
        [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERMIDTAIL value:SC_MARK_EMPTY];
        for (int i = SC_MARKNUM_FOLDER; i <= SC_MARKNUM_FOLDEROPEN; i++) {
            [_editor setColorProperty:SCI_MARKERSETFORE parameter:i value:foldFore];
            [_editor setColorProperty:SCI_MARKERSETBACK parameter:i value:background];
        }
        [_editor setGeneralProperty:SCI_SETFOLDFLAGS parameter:0 value:SC_FOLDFLAG_LINEAFTER_CONTRACTED];
        // wParam must be 1 for OptionalColour to accept the custom colour (0 = system default).
        [_editor setColorProperty:SCI_SETFOLDMARGINCOLOUR parameter:1 value:background];
        [_editor setColorProperty:SCI_SETFOLDMARGINHICOLOUR parameter:1 value:background];
    } else {
        [self applyGutterDividerMarginFoldActive:NO];
    }

    // Bookmark / mark margin (margin 2) — 5 colored styles
    int markMask = 0;
    for (int i = 0; i < kMarkStyleCount; i++) {
        int marker = kMarkStyleBase + i;
        markMask |= (1 << marker);
    }
    [_editor setGeneralProperty:SCI_SETMARGINTYPEN parameter:2 value:SC_MARGIN_SYMBOL];
    [_editor setGeneralProperty:SCI_SETMARGINWIDTHN parameter:2 value:0];
    [_editor setGeneralProperty:SCI_SETMARGINMASKN parameter:2 value:markMask];
    [_editor setGeneralProperty:SCI_SETMARGINSENSITIVEN parameter:2 value:1];
    [_editor setColorProperty:SCI_SETMARGINBACKN parameter:2 value:background];
    for (int i = 0; i < kMarkStyleCount; i++) {
        int marker = kMarkStyleBase + i;
        int style = i + 1;
        [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:marker value:SC_MARK_BOOKMARK];
        NSColor *markColor = colorForMarkStyle(style);
        [_editor setColorProperty:SCI_MARKERSETFORE parameter:marker value:markColor];
        [_editor setColorProperty:SCI_MARKERSETBACK parameter:marker value:background];
    }

    int changeMask = (1 << kChangeUnsavedMarker) | (1 << kChangeSavedMarker);
    [_editor setGeneralProperty:SCI_SETMARGINTYPEN parameter:3 value:SC_MARGIN_SYMBOL];
    [_editor setGeneralProperty:SCI_SETMARGINWIDTHN parameter:3 value:0];
    [_editor setGeneralProperty:SCI_SETMARGINMASKN parameter:3 value:changeMask];
    [_editor setColorProperty:SCI_SETMARGINBACKN parameter:3 value:background];
    [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:kChangeUnsavedMarker value:SC_MARK_FULLRECT];
    [_editor setGeneralProperty:SCI_MARKERDEFINE parameter:kChangeSavedMarker value:SC_MARK_FULLRECT];
    [_editor setColorProperty:SCI_MARKERSETBACK parameter:kChangeUnsavedMarker value:[NSColor systemOrangeColor]];
    [_editor setColorProperty:SCI_MARKERSETBACK parameter:kChangeSavedMarker value:[NSColor systemGreenColor]];

    long vopts = virtualSpaceEnabled ? (SCVS_RECTANGULARSELECTION | SCVS_USERACCESSIBLE) : 0;
    [_editor setGeneralProperty:SCI_SETVIRTUALSPACEOPTIONS parameter:0 value:vopts];

    [self applySelectionMode];
    [self configureAutoComplete];
    [self applyMarginBackgrounds];
    [_editor suspendDrawing:NO];
}

- (void)configureAutoComplete {
    [_editor setGeneralProperty:SCI_AUTOCSETIGNORECASE parameter:0 value:1];
    [_editor message:SCI_AUTOCSETDROPRESTOFWORD wParam:1 lParam:0];
    [_editor message:SCI_AUTOCSETCHOOSESINGLE wParam:0 lParam:0];
    [_editor setStringProperty:SCI_AUTOCSETFILLUPS parameter:0 value:@" (_[]{}<>:;,.#"];
}

- (void)setAutoCompletionEnabled:(BOOL)enabled minimumLength:(NSInteger)minLength {
    self.autoCompletionEnabled = enabled;
    self.autoCompletionMinLength = MAX(1, minLength);
}

- (void)setLexerLanguage:(NSString *)lexillaName {
    [self setLexerLanguage:lexillaName keywords:nil];
}

- (void)setLexerLanguage:(NSString *)lexillaName keywords:(NSArray<NSString *> *)keywords {
    if (lexillaName.length == 0) {
        [_editor setReferenceProperty:SCI_SETILEXER parameter:0 value:nullptr];
        if (self.codeFoldingEnabled) {
            [self applyGutterDividerMarginFoldActive:NO];
            [self applyMarginBackgrounds];
        }
        return;
    }

    Scintilla::ILexer5 *lexer = CreateLexer(lexillaName.UTF8String);
    if (!lexer) {
        lexer = CreateLexer("cpp");
    }
    [_editor setReferenceProperty:SCI_SETILEXER parameter:0 value:lexer];
    if (self.codeFoldingEnabled) {
        [self applyGutterDividerMarginFoldActive:YES];
        [_editor setLexerProperty:@"fold" value:@"1"];
        [_editor setGeneralProperty:SCI_SETMARGINWIDTHN parameter:1 value:14];
        if (self.editorBackground) {
            [_editor setColorProperty:SCI_SETFOLDMARGINCOLOUR parameter:1 value:self.editorBackground];
            [_editor setColorProperty:SCI_SETFOLDMARGINHICOLOUR parameter:1 value:self.editorBackground];
        }
        [self applyMarginBackgrounds];
    } else {
        [self applyGutterDividerMarginFoldActive:NO];
    }
    if (keywords.count > 0) {
        NSString *joined = [keywords componentsJoinedByString:@" "];
        [_editor setStringProperty:SCI_SETKEYWORDS parameter:0 value:joined];
        if (keywords.count > 0) {
            NSString *secondary = keywords.count > 1 ? joined : @"";
            (void)secondary;
        }
    }
    [_editor setGeneralProperty:SCI_COLOURISE parameter:0 value:-1];
}

- (void)showAutoCompleteWithItems:(NSArray<NSString *> *)items {
    if (items.count == 0) return;
    long pos = [_editor getGeneralProperty:SCI_GETCURRENTPOS];
    long start = [_editor message:SCI_WORDSTARTPOSITION wParam:pos lParam:1];
    int len = (int)MAX(0, pos - start);
    NSString *list = [items componentsJoinedByString:@" "];
    const char *utf8 = list.UTF8String;
    [_editor message:SCI_AUTOCSHOW wParam:len lParam:(sptr_t)(intptr_t)utf8];
}

- (void)goToLine:(NSInteger)line {
    if (line < 1) return;
    long targetLine = (long)(line - 1);
    long pos = [_editor getGeneralProperty:SCI_POSITIONFROMLINE parameter:targetLine];
    [_editor message:SCI_GOTOPOS wParam:pos];
    [_editor message:SCI_SETSEL wParam:pos lParam:pos];
}

- (void)foldAll {
    [_editor message:SCI_FOLDALL wParam:SC_FOLDACTION_CONTRACT lParam:0];
}

- (void)unfoldAll {
    [_editor message:SCI_FOLDALL wParam:SC_FOLDACTION_EXPAND lParam:0];
}

- (void)setOverwriteMode:(BOOL)overwrite {
    [_editor setGeneralProperty:SCI_SETOVERTYPE parameter:0 value:overwrite ? 1 : 0];
}

- (void)applySearchHighlights:(NSArray<NSValue *> *)ranges {
    [_editor message:SCI_SETINDICATORCURRENT wParam:0];
    [_editor message:SCI_INDICATORCLEARRANGE wParam:0 lParam:[_editor getGeneralProperty:SCI_GETLENGTH]];
    NSColor *highlight = [[NSColor systemYellowColor] colorWithAlphaComponent:0.35];
    [_editor setColorProperty:SCI_INDICSETFORE parameter:0 value:highlight];
    [_editor setGeneralProperty:SCI_INDICSETUNDER parameter:0 value:1];
    [_editor setGeneralProperty:SCI_INDICSETSTYLE parameter:0 value:INDIC_FULLBOX];

    for (NSValue *value in ranges) {
        NSRange range = value.rangeValue;
        if (NSMaxRange(range) <= (NSUInteger)[_editor getGeneralProperty:SCI_GETLENGTH]) {
            [_editor message:SCI_INDICATORFILLRANGE wParam:range.location lParam:range.length];
        }
    }
}

- (void)applyMarginBackgrounds {
    if (!self.editorBackground) return;
    NSColor *background = self.editorBackground;
    for (int margin = 0; margin <= 3; margin++) {
        [_editor setColorProperty:SCI_SETMARGINBACKN parameter:margin value:background];
    }
}

- (void)updateLineNumberMarginWidth {
    if (!self.showLineNumbersEnabled) {
        if (self.lastLineNumberMarginWidth != 0) {
            self.lastLineNumberMarginWidth = 0;
            [_editor setGeneralProperty:SCI_SETMARGINWIDTHN parameter:0 value:0];
        }
        return;
    }

    long lineCount = [_editor getGeneralProperty:SCI_GETLINECOUNT];
    int digits = 1;
    long n = MAX(lineCount, 1);
    while (n >= 10) {
        digits++;
        n /= 10;
    }

    NSMutableString *widest = [NSMutableString stringWithCapacity:digits];
    for (int i = 0; i < digits; i++) {
        [widest appendString:@"8"];
    }
    long textWidth = [_editor message:SCI_TEXTWIDTH wParam:STYLE_LINENUMBER lParam:(sptr_t)widest.UTF8String];
    int width = (int)MAX(22, textWidth + 6);
    if (width == self.lastLineNumberMarginWidth) return;
    self.lastLineNumberMarginWidth = width;
    [_editor setGeneralProperty:SCI_SETMARGINWIDTHN parameter:0 value:width];
}

- (void)applyChangeHistory:(NSArray *)entries {
    [_editor message:SCI_MARKERDELETEALL wParam:kChangeUnsavedMarker lParam:0];
    [_editor message:SCI_MARKERDELETEALL wParam:kChangeSavedMarker lParam:0];
    long lineCount = [_editor getGeneralProperty:SCI_GETLINECOUNT];
    for (NSDictionary *entry in entries) {
        NSNumber *lineNum = entry[@"line"];
        NSNumber *stateNum = entry[@"state"];
        if (!lineNum || !stateNum) continue;
        long line = (long)lineNum.integerValue - 1;
        int marker = stateNum.intValue == 2 ? kChangeSavedMarker : kChangeUnsavedMarker;
        if (line >= 0 && line < lineCount) {
            [_editor message:SCI_MARKERADD wParam:line lParam:marker];
        }
    }
    long width = (self.showChangeHistoryEnabled && entries.count > 0) ? 8 : 0;
    [_editor setGeneralProperty:SCI_SETMARGINWIDTHN parameter:3 value:width];
    [self applyMarginBackgrounds];
}

- (void)applyLineMarks:(NSArray *)marks {
    for (int i = 0; i < kMarkStyleCount; i++) {
        [_editor message:SCI_MARKERDELETEALL wParam:(kMarkStyleBase + i) lParam:0];
    }
    long lineCount = [_editor getGeneralProperty:SCI_GETLINECOUNT];
    for (NSDictionary *entry in marks) {
        NSNumber *lineNum = entry[@"line"];
        NSNumber *styleNum = entry[@"style"];
        if (!lineNum || !styleNum) continue;
        long line = (long)lineNum.integerValue - 1;
        int style = styleNum.intValue;
        if (style < 1 || style > kMarkStyleCount) style = 3;
        int marker = kMarkStyleBase + (style - 1);
        if (line >= 0 && line < lineCount) {
            [_editor message:SCI_MARKERADD wParam:line lParam:marker];
        }
    }
    long width = marks.count > 0 ? 14 : 0;
    [_editor setGeneralProperty:SCI_SETMARGINWIDTHN parameter:2 value:width];
    [self applyMarginBackgrounds];
}

- (void)applyBookmarks:(NSArray<NSNumber *> *)lines {
    NSMutableArray<NSDictionary *> *marks = [NSMutableArray array];
    for (NSNumber *num in lines) {
        [marks addObject:@{@"line": num, @"style": @3}];
    }
    [self applyLineMarks:marks];
}

- (NSInteger)firstVisibleLine {
    return (NSInteger)[_editor getGeneralProperty:SCI_GETFIRSTVISIBLELINE] + 1;
}

- (void)scrollToFirstVisibleLine:(NSInteger)line {
    if (line < 1) return;
    long target = (long)(line - 1);
    long current = [_editor getGeneralProperty:SCI_GETFIRSTVISIBLELINE];
    long delta = target - current;
    if (delta != 0) {
        [_editor message:SCI_LINESCROLL wParam:0 lParam:delta];
    }
}

- (void)setReadOnlyMode:(BOOL)readOnly {
    [_editor setEditable:!readOnly];
    [_editor setGeneralProperty:SCI_SETREADONLY parameter:0 value:readOnly ? 1 : 0];
}

- (void)updateBraceMatching {
    if (!self.braceMatchingEnabled) {
        [_editor message:SCI_BRACEHIGHLIGHT wParam:-1 lParam:-1];
        return;
    }
    long pos = [_editor getGeneralProperty:SCI_GETCURRENTPOS];
    long match = [_editor message:SCI_BRACEMATCH wParam:pos lParam:0];
    if (match >= 0) {
        [_editor message:SCI_BRACEHIGHLIGHT wParam:pos lParam:match];
    } else {
        long before = pos > 0 ? pos - 1 : pos;
        match = [_editor message:SCI_BRACEMATCH wParam:before lParam:0];
        if (match >= 0) {
            [_editor message:SCI_BRACEHIGHLIGHT wParam:before lParam:match];
        } else {
            [_editor message:SCI_BRACEHIGHLIGHT wParam:-1 lParam:-1];
        }
    }
}

- (void)applySmartHighlights:(NSArray<NSValue *> *)ranges {
    [_editor message:SCI_SETINDICATORCURRENT wParam:1];
    [_editor message:SCI_INDICATORCLEARRANGE wParam:0 lParam:[_editor getGeneralProperty:SCI_GETLENGTH]];
    NSColor *highlight = [[NSColor systemBlueColor] colorWithAlphaComponent:0.22];
    [_editor setColorProperty:SCI_INDICSETFORE parameter:1 value:highlight];
    [_editor setGeneralProperty:SCI_INDICSETUNDER parameter:1 value:0];
    [_editor setGeneralProperty:SCI_INDICSETSTYLE parameter:1 value:INDIC_FULLBOX];
    for (NSValue *value in ranges) {
        NSRange range = value.rangeValue;
        if (NSMaxRange(range) <= (NSUInteger)[_editor getGeneralProperty:SCI_GETLENGTH]) {
            [_editor message:SCI_INDICATORFILLRANGE wParam:range.location lParam:range.length];
        }
    }
}

- (void)applySpellCheckHighlights:(NSArray<NSValue *> *)ranges {
    [_editor message:SCI_SETINDICATORCURRENT wParam:2];
    [_editor message:SCI_INDICATORCLEARRANGE wParam:0 lParam:[_editor getGeneralProperty:SCI_GETLENGTH]];
    [_editor setColorProperty:SCI_INDICSETFORE parameter:2 value:[NSColor systemRedColor]];
    [_editor setGeneralProperty:SCI_INDICSETUNDER parameter:2 value:1];
    [_editor setGeneralProperty:SCI_INDICSETSTYLE parameter:2 value:INDIC_SQUIGGLE];
    for (NSValue *value in ranges) {
        NSRange range = value.rangeValue;
        if (NSMaxRange(range) <= (NSUInteger)[_editor getGeneralProperty:SCI_GETLENGTH]) {
            [_editor message:SCI_INDICATORFILLRANGE wParam:range.location lParam:range.length];
        }
    }
}

- (void)showCalltip:(NSString *)text atPosition:(long)position {
    if (text.length == 0) return;
    const char *utf8 = text.UTF8String;
    [_editor message:SCI_CALLTIPSHOW wParam:position lParam:(sptr_t)(intptr_t)utf8];
}

- (void)setBraceMatchingEnabled:(BOOL)enabled {
    if (_braceMatchingEnabled == enabled) return;
    _braceMatchingEnabled = enabled;
    if (!enabled) {
        [_editor message:SCI_BRACEHIGHLIGHT wParam:-1 lParam:-1];
    }
}

#pragma mark - ScintillaNotificationProtocol

- (void)notification:(SCNotification *)notification {
    if (!notification) return;
    switch (notification->nmhdr.code) {
        case SCN_MODIFIED: {
            if (self.suppressChangeNotification) break;
            if (notification->modificationType & (SC_MOD_INSERTTEXT | SC_MOD_DELETETEXT | SC_MOD_BEFOREINSERT | SC_MOD_BEFOREDELETE)) {
                [self updateLineNumberMarginWidth];
                [self.editorDelegate scintillaEditorTextDidChange:self];
            }
            break;
        }
        case SCN_UPDATEUI: {
            long pos = [_editor getGeneralProperty:SCI_GETCURRENTPOS];
            long line = [_editor getGeneralProperty:SCI_LINEFROMPOSITION parameter:pos];
            long column = [_editor getGeneralProperty:SCI_GETCOLUMN parameter:pos];
            NSInteger reportLine = line + 1;
            NSInteger reportColumn = column + 1;
            if (reportLine != self.lastReportedLine || reportColumn != self.lastReportedColumn) {
                self.lastReportedLine = reportLine;
                self.lastReportedColumn = reportColumn;
                [self updateBraceMatching];
                [self.editorDelegate scintillaEditorSelectionDidChange:self line:reportLine column:reportColumn];
            }
            if (notification->updated & SC_UPDATE_V_SCROLL) {
                NSInteger scrollLine = (NSInteger)[_editor getGeneralProperty:SCI_GETFIRSTVISIBLELINE] + 1;
                if (scrollLine != self.lastReportedScrollLine) {
                    self.lastReportedScrollLine = scrollLine;
                    [self.editorDelegate scintillaEditorDidScroll:self firstVisibleLine:scrollLine];
                }
            }
            break;
        }
        case SCN_CHARADDED: {
            unichar ch = notification->ch;
            if (ch == '(') {
                [self updateBraceMatching];
            }
            if (!self.autoCompletionEnabled) break;
            if (!((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || ch == '_')) break;
            long pos = [_editor getGeneralProperty:SCI_GETCURRENTPOS];
            long start = [_editor message:SCI_WORDSTARTPOSITION wParam:pos lParam:1];
            if ((pos - start) < self.autoCompletionMinLength) break;
            if ([self.editorDelegate respondsToSelector:@selector(scintillaEditorAutoCompleteRequested:)]) {
                [self.editorDelegate scintillaEditorAutoCompleteRequested:self];
            }
            break;
        }
        default:
            break;
    }
}

@end
