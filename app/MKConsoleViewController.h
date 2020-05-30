// MKConsoleViewController.h

@interface MKConsoleViewController : UIViewController <UITextViewDelegate>

@property (strong, nonatomic) UITextView *textView;

- (void)clearLog;
- (void)updateConsole;

@end
