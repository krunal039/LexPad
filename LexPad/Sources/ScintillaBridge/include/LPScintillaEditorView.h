//
// ScintillaBridge — ObjC++ wrapper around ScintillaView + Lexilla
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LPScintillaEditorDelegate <NSObject>
@optional
- (void)scintillaEditorTextDidChange:(id)sender;
- (void)scintillaEditorSelectionDidChange:(id)sender line:(NSInteger)line column:(NSInteger)column;
- (void)scintillaEditorDidScroll:(id)sender firstVisibleLine:(NSInteger)line;
- (void)scintillaEditorAutoCompleteRequested:(id)sender;
@end

@interface LPScintillaEditorView : NSView

@property (nonatomic, copy) NSString *string;
@property (nonatomic, getter=isEditable) BOOL editable;
@property (nonatomic, weak, nullable) id<LPScintillaEditorDelegate> editorDelegate;
@property (nonatomic, readonly) NSScrollView *scrollView;
@property (nonatomic, assign) BOOL columnSelectionMode;

+ (BOOL)isEngineAvailable;

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
                            themeColors:(nullable NSDictionary *)themeColors;

- (void)addSelectionRange:(NSRange)range;
- (void)selectNextOccurrenceMatchCase:(BOOL)matchCase wholeWord:(BOOL)wholeWord;

- (void)setLexerLanguage:(nullable NSString *)lexillaName keywords:(nullable NSArray<NSString *> *)keywords;
- (void)showAutoCompleteWithItems:(NSArray<NSString *> *)items;
- (void)setAutoCompletionEnabled:(BOOL)enabled minimumLength:(NSInteger)minLength;
- (void)goToLine:(NSInteger)line;
- (void)applySearchHighlights:(NSArray<NSValue *> *)ranges;
- (void)setSelectedRange:(NSRange)range;
- (NSRange)selectedRange;
- (void)foldAll;
- (void)unfoldAll;
- (void)setOverwriteMode:(BOOL)overwrite;
- (void)applyBookmarks:(NSArray<NSNumber *> *)lines;
- (void)applyLineMarks:(NSArray *)marks;
- (void)applyChangeHistory:(NSArray *)entries;
- (NSInteger)firstVisibleLine;
- (void)scrollToFirstVisibleLine:(NSInteger)line;
- (void)setReadOnlyMode:(BOOL)readOnly;
- (void)updateBraceMatching;
- (void)applySmartHighlights:(NSArray<NSValue *> *)ranges;
- (void)applySpellCheckHighlights:(NSArray<NSValue *> *)ranges;
- (void)showCalltip:(NSString *)text atPosition:(long)position;
- (void)setBraceMatchingEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
