// MKAppDelegate.h

#import "MKScriptsViewController.h"

void alertError(NSString *msg);

@class MKRootViewController, UIProgressHUD;

@interface MKAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MKRootViewController *rootViewController;
@property (nonatomic, strong) UIProgressHUD *hud;

@end
