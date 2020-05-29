// MK1 Application - Copyright (c) 2020 Castyte. All rights reserved.

#import "MKAppDelegate.h"
#import "MKRootViewController.h"
#import "MKConsoleViewController.h"
#import "../src/Headers/CPDistributedMessagingCenter.h"
#import <rocketbootstrap/rocketbootstrap.h>
#import "../src/Headers/UIProgressHUD.h"

// this is disgusting. turn back if you value your life.

UIProgressHUD *hud;

void alertError(NSString *msg){
	dispatch_async(dispatch_get_main_queue(), ^{
		if(hud) [hud hide];

		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
									message:msg preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
			handler:^(UIAlertAction * action) {}];

		[alert addAction:okAction];
		[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
	});
}


@implementation MKAppDelegate

-(void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_rootViewController = [[MKRootViewController alloc] init];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options{
	if(![url.scheme isEqualToString:@"mk1"]) return NO;
	NSDictionary *userInfo;
	if(url.pathComponents.count > 2) userInfo = @{@"name": url.pathComponents[1], @"arg": url.lastPathComponent};
	else userInfo = @{@"name": url.lastPathComponent};
	if([url.host isEqualToString:@"runscript"]){
		static CPDistributedMessagingCenter *c = nil;
		c = [CPDistributedMessagingCenter centerNamed:@"com.castyte.mk1"];
		rocketbootstrap_distributedmessagingcenter_apply(c);
		[c sendMessageName:@"runscript" userInfo:userInfo];
	} else if([url.host isEqualToString:@"runtrigger"]){
		static CPDistributedMessagingCenter *c = nil;
		c = [CPDistributedMessagingCenter centerNamed:@"com.castyte.mk1"];
		rocketbootstrap_distributedmessagingcenter_apply(c);
		[c sendMessageName:@"runtrigger" userInfo:userInfo];
	} else if([url.host isEqualToString:@"ext-script"]){
		[self handleExtScript:url];
	}
	if(options && options[UIApplicationOpenURLOptionsSourceApplicationKey]
		&& [options[UIApplicationOpenURLOptionsSourceApplicationKey] isEqualToString:@"com.apple.shortcuts"]){
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"shortcuts://callback"] options:@{} completionHandler:nil];
		}
	return YES;
}


-(void)handleExtScript:(NSURL *)url{
	NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
	NSMutableDictionary<NSString *, NSString *> *queryParams = [NSMutableDictionary<NSString *, NSString *> new];
	for (NSURLQueryItem *queryItem in [urlComponents queryItems]) {
		if (queryItem.value == nil) continue;
		[queryParams setObject:queryItem.value forKey:queryItem.name];
	}

	if(queryParams.count < 3 || !queryParams[@"id"] || !queryParams[@"name"] || !queryParams[@"trigger"]){
		alertError(@"The URL Scheme is missing required parameters");
	}

	UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Add external script?"
								message:[NSString stringWithFormat:@"Do you want to add the external script '%@'?\n\nScripts are not verified! Get scripts from trusted sources and check them before running.", queryParams[@"name"]] preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
	UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
	handler:^(UIAlertAction * action) {
		hud = [[UIProgressHUD alloc] initWithFrame:CGRectZero];
		[hud setText:@"Loading"];
		[hud showInView:self.rootViewController.view];

		// NOTE FIXME --- the original script server has gone down, a user in eggcord has put up another server. ideally the domain should be configurable.
		// same domain is in the scripts view controller
		NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://XXX.REPLACEME.XXX/s/c/%@", queryParams[@"id"]]]];
		[[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
			if(((NSHTTPURLResponse *)response).statusCode != 200){
				dispatch_async(dispatch_get_main_queue(), ^{
					alertError(@"Unable to get script data.");
				});
				return;
			}

			NSString *scriptPath = [NSString stringWithFormat:@"/Library/MK1/Scripts/ext-%@.js", queryParams[@"name"]];
			
			if([[NSFileManager defaultManager] fileExistsAtPath:scriptPath isDirectory:nil]){
				dispatch_async(dispatch_get_main_queue(), ^{
					alertError([NSString stringWithFormat:@"You already have a script at '%@'", scriptPath]);
				});
				return;
			}

			NSError *werror;
			[data writeToFile:scriptPath options:NSDataWritingAtomic error:&werror];
			if(werror){
				dispatch_async(dispatch_get_main_queue(), ^{
					alertError([werror localizedDescription]);
				});
				return;
			}

			NSData *jsonData = [NSData dataWithContentsOfFile:@"/Library/MK1/scripts.json"];
			NSError *jerror;
			NSDictionary *dict1 = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jerror];
			if(jerror){
				dispatch_async(dispatch_get_main_queue(), ^{
					alertError([jerror localizedDescription]);
				});
				return;
			}
			NSMutableDictionary *dict = [dict1 mutableCopy];

			NSMutableArray *array = [NSMutableArray array];
			NSArray *arr1 = dict[queryParams[@"trigger"]];
			if(arr1) array = [arr1 mutableCopy];
			[array addObject:[NSString stringWithFormat:@"ext-%@", queryParams[@"name"]]];
			
			[dict setObject:array forKey:queryParams[@"trigger"]];


			NSError *j2error; 
			NSData *json2Data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&j2error];
			if(j2error){
				dispatch_async(dispatch_get_main_queue(), ^{
					alertError([j2error localizedDescription]);
				});
				return;
			}

			NSError *w2error;
			[json2Data writeToFile:@"/Library/MK1/scripts.json" options:NSDataWritingAtomic error:&w2error];
			if(w2error){
				dispatch_async(dispatch_get_main_queue(), ^{
					alertError([w2error localizedDescription]);
				});
				return;
			}


			dispatch_async(dispatch_get_main_queue(), ^{
				[hud hide];

				UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Success"
											message:@"Script successfully added.\nYou may need to respring to apply changes." preferredStyle:UIAlertControllerStyleAlert];

				UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
					handler:^(UIAlertAction * action) {}];

				[alert addAction:okAction];
				[self.rootViewController presentViewController:alert animated:YES completion:nil];
				static CPDistributedMessagingCenter *c = nil;
				c = [CPDistributedMessagingCenter centerNamed:@"com.castyte.mk1"];
				rocketbootstrap_distributedmessagingcenter_apply(c);
				[c sendMessageName:@"updateScripts" userInfo:nil];
				[self.rootViewController.scriptsVC refreshScripts];
			});
		}] resume];
	}];
	[alert addAction:noAction];
	[alert addAction:yesAction];
	[vc presentViewController:alert animated:YES completion:nil];	
}

@end