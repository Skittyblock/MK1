// Context.m

#import "Context.h"
#import "Tweak.h"
#import "Util.h"
#import <AVFoundation/AVFoundation.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import <objc/runtime.h>
#import <notify.h>
#import <signal.h>
#import <unistd.h>
#import "XMLHttpRequest.h"
#import "JSPromise.h"

// Setup JSContext functions
// Main function implementations
void setupContext() {
	NSMutableDictionary <NSString *, NSTimer *> *timeouts = [[NSMutableDictionary alloc] init];
	NSMutableDictionary <NSString *, NSTimer *> *intervals = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *bluetoothDevices = [[NSMutableDictionary alloc] init];
	NSMutableDictionary <NSString *, MTAlarm *> *alarms = [[NSMutableDictionary alloc] init];

	// Alert
	/* TODO: alerts should use a window placed above everything else instead of getting the key window
			 should be some control on global state, as currenly if a script assigns a constant another script will have an error reassigning to it
			 this could be fixed by having a 'MK1.<SCRIPTNAME<.exports' to export variables for use in other scripts, and all other variable being kept inside the script
	
	 		 the context should've ideally used JSExport to sort the different categories into classes, but i did not know JSExport existed when starting this */
	ctx[@"alert"] = ^(JSValue *jtitle, JSValue *jmsg) {
		NSString *title = toStringCheckNull(jtitle);
		NSString *msg = toStringCheckNull(jmsg);

		UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;
		
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
 
		UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
		
		[alert addAction:okAction];
		[vc presentViewController:alert animated:YES completion:nil];
	};

	// RocketBootstrap
	ctx[@"sendRocketBootstrapMessage"] = ^(NSString *center, NSString *message, NSDictionary *userInfo) {
		static CPDistributedMessagingCenter *c = nil;
		c = [CPDistributedMessagingCenter centerNamed:center];
		rocketbootstrap_distributedmessagingcenter_apply(c);
		return [c sendMessageAndReceiveReplyName:message userInfo:userInfo];
	};

	// Reachability
	ctx[@"toggleReachability"] = ^{
		[[objc_getClass("SBReachabilityManager") sharedInstance] setReachabilityEnabled:YES];
		[[objc_getClass("SBReachabilityManager") sharedInstance] toggleReachability];
	};

	// Shell
	ctx[@"shellrun"] = ^(NSString *command, JSValue *cb) {
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:@"/bin/sh"];
		[task setArguments:@[@"-c", command]];

		NSPipe *stdoutPipe = [NSPipe pipe];
		[task setStandardOutput:stdoutPipe];

		NSPipe *stderrPipe = [NSPipe pipe];
		[task setStandardError:stderrPipe];

		task.terminationHandler = ^(NSTask *task) {
			if(![cb isObject]) return;
			dispatch_async(dispatch_get_main_queue(), ^{
				NSNumber *status = [NSNumber numberWithInteger:task.terminationStatus];
				NSString *stdout = [[NSString alloc] initWithData:[[stdoutPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
				NSString *stderr = [[NSString alloc] initWithData:[[stderrPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
				[cb callWithArguments:@[status, stdout, stderr]];
			});
		};
		[task launch];
	};

	// Current app info
	ctx[@"currentApp"] = @{
		@"isSpringBoard": ^{
			return [userAgent springBoardIsActive];
		},

		@"bundleID": ^{
			return [[springBoard _accessibilityFrontMostApplication] bundleIdentifier];
		},

		@"name": ^{
			return [[springBoard _accessibilityFrontMostApplication] displayName];
		}
	};

	// System UI info
	// TODO: don't use keyWindow
	ctx[@"systemUI"] = @{
		@"isControlCenterShowing": ^{
			return [[[UIApplication sharedApplication] keyWindow] isKindOfClass:objc_getClass("SBControlCenterWindow")];
		},

		@"isHomeScreenShowing": ^{
			return [[[UIApplication sharedApplication] keyWindow] isKindOfClass:objc_getClass("SBHomeScreenWindow")];
		},

		@"isCoverSheetShowing": ^{
			return [[[UIApplication sharedApplication] keyWindow] isKindOfClass:objc_getClass("SBCoverSheetWindow")];
		}
	};

	// Brightness
	ctx[@"brightness"] = @{
		@"getLevel": ^{
			return [UIScreen mainScreen].brightness;
		},

		@"setLevel": ^(float level) {
			[[objc_getClass("SBBrightnessController") sharedBrightnessController] setBrightnessLevel:level];
		}
	};

	// Cellular
	ctx[@"cellularData"] = @{
		@"isEnabled": ^{
			return [objc_getClass("PSCellularDataSettingsDetail") isEnabled];
		},

		@"setEnabled": ^(BOOL enabled) {
			[objc_getClass("PSCellularDataSettingsDetail") setEnabled:enabled];
		}
	};

	// Volume
	ctx[@"volume"] = @{
		@"getRinger": ^{
			float vol;
			[[objc_getClass("AVSystemController") sharedAVSystemController] getVolume:&vol forCategory:@"Ringtone"];
			return vol;
		},

		@"setRinger": ^(float vol) {
			[[objc_getClass("AVSystemController") sharedAVSystemController] setVolumeTo:vol forCategory:@"Ringtone"];
		},

		@"getMedia": ^{
			float vol;
			[[objc_getClass("AVSystemController") sharedAVSystemController] getVolume:&vol forCategory:@"Audio/Video"];
			return vol;
		},

		@"setMedia": ^(float vol) {
			[[objc_getClass("AVSystemController") sharedAVSystemController] setVolumeTo:vol forCategory:@"Audio/Video"];
		}
	};
	
	// Wi-Fi
	ctx[@"wifi"] = @{
		@"isEnabled": ^{
			return [wifiMan wiFiEnabled];
		},

		@"networkName": ^{
			return [wifiMan currentNetworkName];
		},

		@"signalRSSI": ^{
			return [wifiMan signalStrengthRSSI];
		},

		@"setEnabled": ^(BOOL enabled) {
			[wifiMan setWiFiEnabled:enabled];
		}
	};


	// Alarms
	ctx[@"alarm"] = @{
		@"getTitle": ^(NSString *ID) {
			if (alarms[ID]) return alarms[ID].displayTitle;
			else return @"";
		},

		@"getHour": ^(NSString *ID) {
			if (alarms[ID]) return alarms[ID].hour;
			else return (unsigned long long)NULL;
		},

		@"getMinute": ^(NSString *ID) {
			if (alarms[ID]) return alarms[ID].minute;
			else return (unsigned long long)NULL;
		},

		@"isEnabled": ^(NSString *ID) {
			if (alarms[ID]) return alarms[ID].enabled;
			else return NO;
		},

		@"isSnoozed": ^(NSString *ID) {
			if (alarms[ID]) return alarms[ID].snoozed;
			else return NO;
		},

		@"getNextFireDate": ^(NSString *ID) {
			if (alarms[ID]) return alarms[ID].nextFireDate;
			else return (NSDate *)nil;
		},

		@"setEnabled": ^(NSString *ID, BOOL enabled) {
			if (alarms[ID]) {
				alarms[ID].enabled = enabled;
				[alarmManager updateAlarm:alarms[ID]];	
			}
		},

		@"setHour": ^(NSString *ID, unsigned long long hour) {
			if (alarms[ID]) {
				alarms[ID].hour = hour;
				[alarmManager updateAlarm:alarms[ID]];
			}
		},

		@"setMinute": ^(NSString *ID, unsigned long long minute) {
			if (alarms[ID]) {
				alarms[ID].minute = minute;
				[alarmManager updateAlarm:alarms[ID]];
			}
		},

		@"snooze": ^(NSString *ID) {
			if (alarms[ID]) {
				[alarmManager snoozeAlarmWithIdentifier:ID];
			}
		}
	};

	ctx[@"allAlarms"] = ^{
		for (unsigned long long i = 0; i < [alarmManager alarmCount]; i++) {
			MTAlarm *alarm = [alarmManager alarmAtIndex:i];
			alarms[[alarm alarmIDString]] = alarm;
		}
		return [alarms allKeys];
	};


	// Bluetooth
	ctx[@"bluetooth"] = @{
		@"isEnabled": ^{
			return [[objc_getClass("BluetoothManager") sharedInstance] enabled];
		},

		@"setEnabled": ^(BOOL enabled) {
			[[objc_getClass("BluetoothManager") sharedInstance] setEnabled:enabled];
		},

		@"connectedDevices": ^{
			NSMutableArray *ret = [NSMutableArray array];
			NSArray *devices = [[objc_getClass("BluetoothManager") sharedInstance] connectedDevices];
			for (BluetoothDevice *device in devices) {
				bluetoothDevices[[device scoUID]] = device;
				[ret addObject:[device scoUID]];
			}
			return ret;
		},

		@"pairedDevices": ^{
			NSMutableArray *ret = [NSMutableArray array];
			NSArray *devices = [[objc_getClass("BluetoothManager") sharedInstance] pairedDevices];
			for (BluetoothDevice *device in devices) {
				bluetoothDevices[[device scoUID]] = device;
				[ret addObject:[device scoUID]];
			}
			return ret;
		}
	};

	ctx[@"bluetoothDevice"] = @{
		@"name": ^(NSString *dID) {
			if (bluetoothDevices[dID]) return [bluetoothDevices[dID] name];
			else return (id)nil;
		},

		@"address": ^(NSString *dID) {
			if (bluetoothDevices[dID]) return [(BluetoothDevice *)bluetoothDevices[dID] address];
			else return (id)nil;
		},

		@"connected": ^(NSString *dID) {
			if (bluetoothDevices[dID]) return [bluetoothDevices[dID] connected];
			else return NO;
		},

		@"disconnect": ^(NSString *dID) {
			if (bluetoothDevices[dID]) [bluetoothDevices[dID] disconnect];
		},

		@"connect": ^(NSString *dID) {
			if (bluetoothDevices[dID]) [bluetoothDevices[dID] connect];
		},

		@"batteryLevel": ^(NSString *dID) {
			if (bluetoothDevices[dID]) return [(BluetoothDevice *)bluetoothDevices[dID] batteryLevel];
			else return -1;
		},

		@"vendorID": ^(NSString *dID) {
			if (bluetoothDevices[dID]) return [bluetoothDevices[dID] vendorId];
			else return (unsigned)0;
		},

		@"paired": ^(NSString *dID) {
			if (bluetoothDevices[dID]) return [bluetoothDevices[dID] paired];
			else return NO;
		},

		@"productID": ^(NSString *dID) {
			if (bluetoothDevices[dID]) return [bluetoothDevices[dID] productId];
			else return (unsigned)0;
		},

		@"unpair": ^(NSString *dID) {
			if (bluetoothDevices[dID]) [bluetoothDevices[dID] unpair];
		},
	};

	// Confirm alerts
	ctx[@"confirm"] = ^(JSValue *jtitle, JSValue *jmsg, JSValue *cb) {
		NSString *title = toStringCheckNull(jtitle);
		NSString *msg = toStringCheckNull(jmsg);

		UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
 
		UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
		handler:^(UIAlertAction * action) {
			[cb callWithArguments:@[@YES]];
		}];

		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
		handler:^(UIAlertAction * action) {
			[cb callWithArguments:@[@NO]];
		}];

		[alert addAction:cancelAction];
		[alert addAction:okAction];
		alert.preferredAction = okAction;
		[vc presentViewController:alert animated:YES completion:nil];
	};

	// Alert menu
	ctx[@"menu"] = ^(JSValue *jtitle, JSValue *jmsg, NSArray<NSString *> *options, JSValue *cb) {
		NSString *title = toStringCheckNull(jtitle);
		NSString *msg = toStringCheckNull(jmsg);

		UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
 
		[options enumerateObjectsUsingBlock:^(NSString *opt, NSUInteger idx, BOOL *stop) {
			UIAlertAction* action = [UIAlertAction actionWithTitle:opt style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
				[cb callWithArguments:@[[NSNumber numberWithUnsignedInteger:idx]]];
			}];

			[alert addAction:action];
		}];

		[vc presentViewController:alert animated:YES completion:nil];
	};

	// Prompt alert
	ctx[@"prompt"] = ^(JSValue *jtitle, JSValue *jmsg, JSValue *cb) {
		NSString *title = toStringCheckNull(jtitle);
		NSString *msg = toStringCheckNull(jmsg);

		UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
 
		UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
		handler:^(UIAlertAction *action) {
			NSString *text = [alert textFields][0].text;
			[cb callWithArguments:@[text]];
		}];

		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
			[cb callWithArguments:@[@NO]];
		}];

		[alert addTextFieldWithConfigurationHandler:nil];

		[alert addAction:cancelAction];
		[alert addAction:okAction];
		alert.preferredAction = okAction;
		[vc presentViewController:alert animated:YES completion:nil];
	};

	// Media player
	ctx[@"media"] = @{
		@"play": ^{
			MRMediaRemoteSendCommand(MRMediaRemoteCommandPlay, nil);
		},

		@"pause": ^{
			MRMediaRemoteSendCommand(MRMediaRemoteCommandPause, nil);
		},

		@"stop": ^{
			MRMediaRemoteSendCommand(MRMediaRemoteCommandStop, nil);
		},

		@"nextTrack": ^{
			MRMediaRemoteSendCommand(MRMediaRemoteCommandNextTrack, nil);
		},

		@"previousTrack": ^{
			MRMediaRemoteSendCommand(MRMediaRemoteCommandPreviousTrack, nil);
		},

		// FIXME: this is horrible
		@"getNowPlayingInfo": ^(JSValue *cb) {
			if (![cb isObject]) return;

			MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef cfinfo) {
				[cb callWithArguments: @[[JSValue valueWithObject:(__bridge NSDictionary *)cfinfo inContext:ctx]]];
			});
		}
	};

	// Device info
	ctx[@"device"] = @{
		@"name": ^{
			return [UIDevice currentDevice].name;
		},

		@"systemName": ^{
			return [UIDevice currentDevice].systemName;
		},

		@"systemVersion": ^{
			return [UIDevice currentDevice].systemVersion;
		},

		@"model": ^{
			return [UIDevice currentDevice].model;
		},

		@"identifierForVendor": ^{
			return [[UIDevice currentDevice].identifierForVendor UUIDString];
		},

		@"orientation": ^{
			return [springBoard activeInterfaceOrientation];
		},

		@"isPortrait": ^{
			return ([springBoard activeInterfaceOrientation] == UIInterfaceOrientationPortrait);
		},

		@"isLandscape": ^{
			return ([springBoard activeInterfaceOrientation] == UIInterfaceOrientationLandscapeRight || [springBoard activeInterfaceOrientation] == UIInterfaceOrientationLandscapeLeft);
		},

		@"isLocked": ^{
			return [userAgent deviceIsLocked];
		},

		@"isScreenOn": ^{
			return [userAgent isScreenOn];
		},

		@"batteryLevel": ^{
			return [UIDevice currentDevice].batteryLevel;
		},

		@"batteryState": ^{
			return [UIDevice currentDevice].batteryState;
		},

		@"shutdown": ^{
			[[objc_getClass("FBSystemService") sharedInstance] shutdownWithOptions:0];
		},

		@"reboot": ^{
			[[objc_getClass("FBSystemService") sharedInstance] shutdownAndReboot:1];
		},

		@"safemode": ^{
			kill(getpid(), SIGABRT);
		},

		@"lock": ^{ // TODO lock but dont dim and add seperate lock+dim action
			[userAgent lockAndDimDevice];
		},

		@"respring": ^{
			[[objc_getClass("FBSystemService") sharedInstance] exitAndRelaunch:YES];
		}

	};

	// VPN
	ctx[@"vpn"] = @{
		@"isConnected": ^{
			return vpnConnected;
		},

		@"setEnabled": ^(BOOL enabled) {
			[vpnController setVPNActive:enabled];
		}
	};

	// Flashlight
	ctx[@"flashlight"] = @{
		@"getLevel": ^{
			return flashlight.flashlightLevel;
		},
		@"setLevel": ^(float level) {
			[flashlight setFlashlightLevel:level withError:nil];
		}
	};

	// Open URL
	ctx[@"openURL"] = ^(NSString *url) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
	};

	// Open application
	ctx[@"openApp"] = ^(NSString *bundleID) {
		[[UIApplication sharedApplication] launchApplicationWithIdentifier:bundleID suspended:NO];
	};

	// Text to speech
	ctx[@"textToSpeech"] = ^(NSString *text) {
		AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
		AVSpeechSynthesizer *syn = [[AVSpeechSynthesizer alloc] init];
		[syn speakUtterance:utterance];
	};

	// Timeout functions
	ctx[@"setTimeout"] = ^(JSValue *cb, double ms) {
		NSString *_id = [[NSUUID UUID] UUIDString];
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:ms/1000 repeats:NO block:^(NSTimer *timer) {
			[cb callWithArguments:@[]];
			timeouts[_id] = NULL;
		}];
		timeouts[_id] = timer;
		return _id;
	};

	ctx[@"clearTimeout"] = ^(NSString *_id) {
		if (timeouts[_id]) {
			[timeouts[_id] invalidate];
			timeouts[_id] = NULL;
		}
	};

	// Interval functions
	ctx[@"setInterval"] = ^(JSValue *cb, double ms) {
		NSString *_id = [[NSUUID UUID] UUIDString];
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:ms/1000 repeats:YES block:^(NSTimer *timer) {
			[cb callWithArguments:@[]];
		}];
		intervals[_id] = timer;
		return _id;
	};

	ctx[@"clearInterval"] = ^(NSString *_id) {
		if (intervals[_id]) {
			[intervals[_id] invalidate];
			intervals[_id] = NULL;
		}
	};

	// Low power mode
	ctx[@"lpm"] = @{
		@"setEnabled": ^(bool enabled) {
			[[objc_getClass("_CDBatterySaver") sharedInstance] setMode:enabled];
		},

		@"isEnabled": ^{
			return [[objc_getClass("_CDBatterySaver") sharedInstance] getPowerMode];
		}
	};

	// Airplane mode
	ctx[@"airplaneMode"] = @{
		@"isEnabled": ^{
			return [[[objc_getClass("RadiosPreferences") alloc] init] airplaneMode];
		},

		@"setEnabled": ^(BOOL enabled) {
			[[[objc_getClass("RadiosPreferences") alloc] init] setAirplaneMode:enabled];
		}
	};

	// Orientation lock
	ctx[@"orientationLock"] = @{
		@"setEnabled": ^(BOOL enabled) {
			if (enabled) {
				[[objc_getClass("SBOrientationLockManager") sharedInstance] lock];
			} else {
				[[objc_getClass("SBOrientationLockManager") sharedInstance] unlock];
			}
		},

		@"isEnabled": ^{
			return [[objc_getClass("SBOrientationLockManager") sharedInstance] isUserLocked];
		}
	};

	// Dark mode
	ctx[@"systemStyle"] = @{
		@"toggle": ^{
			[[objc_getClass("UIUserInterfaceStyleArbiter") sharedInstance] toggleCurrentStyle];
		},

		@"isDark": ^{
			return (bool)([[objc_getClass("UIUserInterfaceStyleArbiter") sharedInstance] currentStyle]-1);
		}
	};

	// Console
	ctx[@"console"] = @{
		@"log": ^(NSString *txt) {
			MK1Log(MK1LogInfo, txt);
		},

		@"error": ^(NSString *txt) {
			MK1Log(MK1LogError, txt);
		},

		@"info": ^(NSString *txt) {
			MK1Log(MK1LogInfo, txt);
		},

		@"warn": ^(NSString *txt) {
			MK1Log(MK1LogWarn, txt);
		}
	};

	// File management
	ctx[@"file"] = @{
		@"read": ^(NSString *path) {
			NSError *error;
			NSString *file = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
			if (error) {
				alertError([error localizedDescription]);
				return (NSString *)nil;
			} else {
				return file;
			}
		},

		@"readPlist": ^(NSString *path) {
			NSError *error;
			NSDictionary *o = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", path]] error:&error];
			if (error) {
				alertError([error localizedDescription]);
				return @{};
			}
			return o;
		},

		@"writePlist": ^(NSString *path, NSDictionary *data) {
			NSError *error;
			[data writeToURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", path]] error:&error];
			if (error) alertError([error localizedDescription]);
		},

		// prefsd or whatever doesnt refresh the prefs while the process is running unless you do something like this
		@"writePreferencesPlist": ^(NSString *domain, NSDictionary *data) {
			CFStringRef appId = (__bridge CFStringRef)domain;
			if (!CFPreferencesAppSynchronize(appId)) return alertError(@"Error while synchronizing preferences");
			for (id key in data) {
				if (![key isKindOfClass:[NSString class]]) continue;
				CFStringRef cfKey = (__bridge CFStringRef)key;
				CFPropertyListRef val = (__bridge CFPropertyListRef)data[key];
				CFPreferencesSetAppValue(cfKey, val, appId);
			}

			if (!CFPreferencesAppSynchronize(appId)) return alertError(@"Error while synchronizing preferences");
		},

		@"write": ^(NSString *path, NSString *data) {
			NSError *error;
			[data writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&error];
			if (error) alertError([error localizedDescription]);
		}
	};

	// Screenshot
	ctx[@"takeScreenshot"] = ^{
		[[objc_getClass("SBCombinationHardwareButtonActions") alloc] performTakeScreenshotAction];
	};

	// Darwin notifications
	ctx[@"sendDarwinNotif"] = ^(NSString *notif) {
		return CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)notif, NULL, NULL, false);
	};

	// Clipboard
	ctx[@"clipboard"] = @{
		@"get": ^{
			return UIPasteboard.generalPasteboard.string;
		},

		@"set": ^(NSString *string) {
			UIPasteboard.generalPasteboard.string = string;
		}
	};

	// MK1 info/actions
	ctx[@"MK1"] = @{
		@"version": @MK1VERSION,
		@"commit": @MK1GITHASH,
		@"scriptDataDir": @"/Library/MK1/ScriptData/",
		@"copyright": @"Copyright (c) Castyte 2020. All Rights Reserved.\nModified work copyright (c) Skitty 2020.",

		@"setAlertOnError": ^(BOOL set){
			setupLogger(set);
		},

		@"runScript": ^(NSString *script, NSString *arg) {
			if (arg) ctx[@"MK1_ARG"] = arg;
			runScriptWithName(script);
		}, 

		@"runTrigger": ^(NSString *trigger, NSString *arg) {
			if (arg) ctx[@"MK1_ARG"] = arg;
			activateTrigger(trigger);
		},

		// an easter egg dedicated to uwu who came up with the name 'MK1'
		@"uwu": ^{
			NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://pbs.twimg.com/media/EUaCY0VXkAIY6g6.jpg"]];
			if (!data) return @"";
			UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:data]];
			imageView.frame = CGRectMake(0, 0, 100, 80);
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			[[[UIApplication sharedApplication] keyWindow] addSubview:imageView];
			return @"Image Source: https://twitter.com";
		},

		@"DEBUG":
			#if DEBUG
			@YES,
			#else
			@NO,
			#endif
	};

	ctx[@"XMLHttpRequest"] = [XMLHttpRequest class];

	ctx[@"Promise"] = [JSPromise class];

	// JavaScript fetch(url, options) which returns a Promise.
	// Supports method, body, and headers for options. TODO: implement more
	ctx[@"fetch"] = ^(NSString *link, NSDictionary *options) {
		JSPromise *promise = [[JSPromise alloc] init];

		promise.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer *timer) {
			[timer invalidate];

			NSURL *url = [NSURL URLWithString:link];
			if (url) {
				NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
				req.HTTPMethod = @"GET";
				if (options) {
					if (options[@"method"]) req.HTTPMethod = options[@"method"];
					if (options[@"body"]) req.HTTPBody = options[@"body"];
					if (options[@"headers"]) {
						NSDictionary *headers = options[@"headers"];
						for (NSString *header in headers.allKeys) {
							[req setValue:headers[header] forHTTPHeaderField:header];
						}
					}
				}

				[[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
					NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					dispatch_async(dispatch_get_main_queue(), ^{
						if (error) {
							[promise fail:error.localizedDescription];
						} else if (data && string) {
							[promise success:string];
						} else {
							[promise fail:[link stringByAppendingString:@" is empty"]];
						}
					});
				}] resume];
			} else {
				dispatch_async(dispatch_get_main_queue(), ^{
					[promise fail:[link stringByAppendingString:@" is not url"]];
				});
			}
		}];

		return promise;
	};
}
