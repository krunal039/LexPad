#import "LPScintillaEditorView.h"

@implementation LPScintillaEditorView {
    NSTextView *_fallbackTextView;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _fallbackTextView = [[NSTextView alloc] initWithFrame:self.bounds];
        _fallbackTextView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        _fallbackTextView.font = [NSFont monospacedSystemFontOfSize:NSFont.systemFontSize weight:NSFontWeightRegular];
        [self addSubview:_fallbackTextView];
    }
    return self;
}

- (NSString *)string {
    return _fallbackTextView.string;
}

- (void)setString:(NSString *)string {
    _fallbackTextView.string = string;
}

- (BOOL)isEditable {
    return _fallbackTextView.editable;
}

- (void)setEditable:(BOOL)editable {
    _fallbackTextView.editable = editable;
}

- (void)setLexerLanguage:(NSString *)languageName {
    (void)languageName;
    // TODO: Lexilla CreateLexer + SCI_SETILEXER when Scintilla framework is linked.
}

- (NSInteger)findAllMatchesForPattern:(NSString *)pattern isRegex:(BOOL)isRegex {
    (void)pattern;
    (void)isRegex;
    // TODO: SCI_FINDTEXTFULL when Scintilla framework is linked.
    return 0;
}

@end
