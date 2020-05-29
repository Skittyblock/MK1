#import "MKScriptsViewController.h"

@class MKRootViewController, UIProgressHUD;

@interface MKAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MKRootViewController *rootViewController;
@end

void alertError(NSString *msg);