//
// ScintillaBridge — ObjC++ wrapper (Phase 0 stub)
//
// When Xcode is available, link against Scintilla.framework built from:
//   Vendor/scintilla/cocoa/Scintilla
//
// This header exposes a Swift-friendly API without importing C++ headers.

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Phase 0 placeholder. Replaced by ScintillaView subclass in Phase 1.
@interface LPScintillaEditorView : NSView

@property (nonatomic, copy) NSString *string;
@property (nonatomic, getter=isEditable) BOOL editable;

- (void)setLexerLanguage:(NSString *)languageName;
- (NSInteger)findAllMatchesForPattern:(NSString *)pattern isRegex:(BOOL)isRegex;

@end

NS_ASSUME_NONNULL_END
