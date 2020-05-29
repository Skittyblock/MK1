@interface MKConsoleViewController : UIViewController <UITextViewDelegate>
@property (strong, nonatomic) UITextView *textView;
-(void)clearLog;
@end