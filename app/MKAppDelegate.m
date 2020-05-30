// MKAppDelegate.m

#import "MKAppDelegate.h"
#import "MKRootViewController.h"
#import "MKConsoleViewController.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import <UIKit/UIKit+Private.h>

void alertError(NSString *msg) {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

		[alert addAction:okAction];
		[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
	});
}

@implementation MKAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_rootViewController = [[MKRootViewController alloc] init];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

// URL scheme
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options{
	if (![url.scheme isEqualToString:@"mk1"]) return NO;

	NSDictionary *userInfo;
	if (url.pathComponents.count > 2) userInfo = @{@"name": url.pathComponents[1], @"arg": url.lastPathComponent};
	else userInfo = @{@"name": url.lastPathComponent};

	if ([url.host isEqualToString:@"runscript"]) {
		static CPDistributedMessagingCenter *c = nil;
		c = [CPDistributedMessagingCenter centerNamed:@"xyz.skitty.mk1"];
		rocketbootstrap_distributedmessagingcenter_apply(c);
		[c sendMessageName:@"runscript" userInfo:userInfo];
	} else if([url.host isEqualToString:@"runtrigger"]) {
		static CPDistributedMessagingCenter *c = nil;
		c = [CPDistributedMessagingCenter centerNamed:@"xyz.skitty.mk1"];
		rocketbootstrap_distributedmessagingcenter_apply(c);
		[c sendMessageName:@"runtrigger" userInfo:userInfo];
	} else if([url.host isEqualToString:@"ext-script"]) {
		[self handleExtScript:url];
	}

	if (options && options[UIApplicationOpenURLOptionsSourceApplicationKey] && [options[UIApplicationOpenURLOptionsSourceApplicationKey] isEqualToString:@"com.apple.shortcuts"]){
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"shortcuts://callback"] options:@{} completionHandler:nil];
	}

	return YES;
}

// Add external script
- (void)handleExtScript:(NSURL *)url {
	NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
	NSMutableDictionary<NSString *, NSString *> *queryParams = [NSMutableDictionary<NSString *, NSString *> new];
	for (NSURLQueryItem *queryItem in [urlComponents queryItems]) {
		if (queryItem.value == nil) continue;
		[queryParams setObject:queryItem.value forKey:queryItem.name];
	}

	if (queryParams.count < 3 || !queryParams[@"id"] || !queryParams[@"name"] || !queryParams[@"trigger"]) {
		alertError(@"The URL Scheme is missing required parameters");
	}

	UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Add external script?" message:[NSString stringWithFormat:@"Do you want to add the external script '%@'?\n\nScripts are not verified! Get scripts from trusted sources and check them before running.", queryParams[@"name"]] preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
	[alert addAction:noAction];

	UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault
	handler:^(UIAlertAction *action) {
		self.hud = [[UIProgressHUD alloc] initWithFrame:CGRectZero];
		[self.hud setText:@"Loading"];
		[self.hud showInView:self.rootViewController.view];

		NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://mk1.skitty.xyz/s/c/%@", queryParams[@"id"]]]];
		[[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			if (((NSHTTPURLResponse *)response).statusCode != 200) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.hud hide];
					alertError(@"Unable to get script data.");
				});
				return;
			}

			NSString *scriptPath = [NSString stringWithFormat:@"/Library/MK1/Scripts/ext-%@.js", queryParams[@"name"]];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath isDirectory:nil]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.hud hide];
					alertError([NSString stringWithFormat:@"You already have a script at '%@'", scriptPath]);
				});
				return;
			}

			NSError *writeError;
			[data writeToFile:scriptPath options:NSDataWritingAtomic error:&writeError];
			if (writeError) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.hud hide];
					alertError([writeError localizedDescription]);
				});
				return;
			}

			NSData *jsonData = [NSData dataWithContentsOfFile:@"/Library/MK1/scripts.json"];
			NSError *jsonError;
			NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
			if (jsonError) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.hud hide];
					alertError([jsonError localizedDescription]);
				});
				return;
			}

			NSMutableDictionary *mutableDict = [dict mutableCopy];
			NSMutableArray *array = [NSMutableArray array];
			NSArray *arr1 = mutableDict[queryParams[@"trigger"]];
			if (arr1) array = [arr1 mutableCopy];
			[array addObject:[NSString stringWithFormat:@"ext-%@", queryParams[@"name"]]];
			
			[mutableDict setObject:array forKey:queryParams[@"trigger"]];

			NSData *json2Data = [NSJSONSerialization dataWithJSONObject:mutableDict options:NSJSONWritingPrettyPrinted error:&jsonError];
			if (jsonError) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.hud hide];
					alertError([jsonError localizedDescription]);
				});
				return;
			}

			[json2Data writeToFile:@"/Library/MK1/scripts.json" options:NSDataWritingAtomic error:&writeError];
			if (writeError) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.hud hide];
					alertError([writeError localizedDescription]);
				});
				return;
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				[self.hud hide];

				UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Script successfully added.\nYou may need to respring to apply changes." preferredStyle:UIAlertControllerStyleAlert];

				UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
				[alert addAction:okAction];

				[self.rootViewController presentViewController:alert animated:YES completion:nil];

				static CPDistributedMessagingCenter *c = nil;
				c = [CPDistributedMessagingCenter centerNamed:@"xyz.skitty.mk1"];
				rocketbootstrap_distributedmessagingcenter_apply(c);
				[c sendMessageName:@"updateScripts" userInfo:nil];

				[self.rootViewController.scriptsVC refreshScripts];
			});
		}] resume];
	}];
	[alert addAction:yesAction];

	[vc presentViewController:alert animated:YES completion:nil];	
}

@end
