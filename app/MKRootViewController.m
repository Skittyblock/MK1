// MKRootViewController.m

#import "MKRootViewController.h"
#import "MKConsoleViewController.h"
#import "MKScriptsViewController.h"

@implementation MKRootViewController

- (void)loadView {
	[super loadView];

	NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
	NSMutableArray *navControllers = [[NSMutableArray alloc] init];

	// FIXME: tab bar images that don't require iOS 13
	self.scriptsVC = [[MKScriptsViewController alloc] init];
	self.scriptsVC.title = @"Scripts";
	self.scriptsVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.scriptsVC.title image:[[UIImage imageNamed:@"archivebox"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] tag:0];
	[viewControllers addObject:self.scriptsVC];

	MKConsoleViewController *consoleVC = [[MKConsoleViewController alloc] init];
	consoleVC.title = @"Console";
	consoleVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:consoleVC.title image:[[UIImage imageNamed:@"doc.plaintext"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] tag:1];
	[viewControllers addObject:consoleVC];
	
	for (UIViewController *vc in viewControllers) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
		navController.navigationBar.translucent = YES;
		[navControllers addObject:navController];
	}

	[self setViewControllers:navControllers];
}

@end
