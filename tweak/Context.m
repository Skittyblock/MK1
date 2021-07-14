// Context.m

#import "Context.h"
#import "Util.h"

#import <AVFoundation/AVFoundation.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import <AVFoundation/AVFoundation+Private.h>
#import <BluetoothManager/BluetoothManager.h>
#import <Celestial/Celestial.h>
#import <CoreDuet/CoreDuet.h>
#import <Foundation/Foundation+Private.h>
#import <FrontBoard/FrontBoard.h>
#import <MediaTimer/MediaTimer.h>
#import <SpringBoard/SpringBoard+Extra.h>
#import <UIKit/UIKit+Private.h>
#import <UserNotificationsKit/UserNotificationsKit.h>
#import <VPNPreferences/VPNPreferences.h>

#import "../Headers/AppSupport/AppSupport.h"
#import "../Headers/Preferences/PSCellularDataSettingsDetail.h"
#import <objc/runtime.h>
#import <notify.h>
#import <signal.h>
#import <unistd.h>

// Setup JSContext functions
// Main function implementations
// TODO: This is disgusting and needs to be cleaned up asap
void setupContext(JSContext *ctx) {
	NSMutableDictionary *bluetoothDevices = [[NSMutableDictionary alloc] init];
	NSMutableDictionary <NSString *, MTAlarm *> *alarms = [[NSMutableDictionary alloc] init];

	// RocketBootstrap
	ctx[@"sendRocketBootstrapMessage"] = ^(NSString *center, NSString *message, NSDictionary *userInfo) {
		static CPDistributedMessagingCenter *c = nil;
		c = [CPDistributedMessagingCenter centerNamed:center];
		rocketbootstrap_distributedmessagingcenter_apply(c);
		return [c sendMessageAndReceiveReplyName:message userInfo:userInfo];
	};

	// Reachability
	ctx[@"toggleReachability"] = ^{
		[[NSClassFromString(@"SBReachabilityManager") sharedInstance] setReachabilityEnabled:YES];
		[[NSClassFromString(@"SBReachabilityManager") sharedInstance] toggleReachability];
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
			return [[[UIApplication sharedApplication] keyWindow] isKindOfClass:NSClassFromString(@"SBControlCenterWindow")];
		},

		@"isHomeScreenShowing": ^{
			return [[[UIApplication sharedApplication] keyWindow] isKindOfClass:NSClassFromString(@"SBHomeScreenWindow")];
		},

		@"isCoverSheetShowing": ^{
			return [[[UIApplication sharedApplication] keyWindow] isKindOfClass:NSClassFromString(@"SBCoverSheetWindow")];
		}
	};

	// Brightness
	ctx[@"brightness"] = @{
		@"getLevel": ^{
			return [UIScreen mainScreen].brightness;
		},

		@"setLevel": ^(float level) {
			[[NSClassFromString(@"SBBrightnessController") sharedBrightnessController] setBrightnessLevel:level];
		}
	};

	// Cellular
	ctx[@"cellularData"] = @{
		@"isEnabled": ^{
			return [NSClassFromString(@"PSCellularDataSettingsDetail") isEnabled];
		},

		@"setEnabled": ^(BOOL enabled) {
			[NSClassFromString(@"PSCellularDataSettingsDetail") setEnabled:enabled];
		}
	};

	// Volume
	ctx[@"volume"] = @{
		@"getRinger": ^{
			float vol;
			[[NSClassFromString(@"AVSystemController") sharedAVSystemController] getVolume:&vol forCategory:@"Ringtone"];
			return vol;
		},

		@"setRinger": ^(float vol) {
			[[NSClassFromString(@"AVSystemController") sharedAVSystemController] setVolumeTo:vol forCategory:@"Ringtone"];
		},

		@"getMedia": ^{
			float vol;
			[[NSClassFromString(@"AVSystemController") sharedAVSystemController] getVolume:&vol forCategory:@"Audio/Video"];
			return vol;
		},

		@"setMedia": ^(float vol) {
			[[NSClassFromString(@"AVSystemController") sharedAVSystemController] setVolumeTo:vol forCategory:@"Audio/Video"];
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
			return [[NSClassFromString(@"BluetoothManager") sharedInstance] enabled];
		},

		@"setEnabled": ^(BOOL enabled) {
			[(BluetoothManager *)[NSClassFromString(@"BluetoothManager") sharedInstance] setEnabled:enabled];
		},

		@"connectedDevices": ^{
			NSMutableArray *ret = [NSMutableArray array];
			NSArray *devices = [[NSClassFromString(@"BluetoothManager") sharedInstance] connectedDevices];
			for (BluetoothDevice *device in devices) {
				bluetoothDevices[[device scoUID]] = device;
				[ret addObject:[device scoUID]];
			}
			return ret;
		},

		@"pairedDevices": ^{
			NSMutableArray *ret = [NSMutableArray array];
			NSArray *devices = [[NSClassFromString(@"BluetoothManager") sharedInstance] pairedDevices];
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
			else return @"";
		},

		@"address": ^(NSString *dID) {
			if (bluetoothDevices[dID]) return [(BluetoothDevice *)bluetoothDevices[dID] address];
			else return @"";
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
			[[NSClassFromString(@"FBSystemService") sharedInstance] shutdownWithOptions:0];
		},

		@"reboot": ^{
			[[NSClassFromString(@"FBSystemService") sharedInstance] shutdownAndReboot:1];
		},

		@"safemode": ^{
			kill(getpid(), SIGABRT);
		},

		@"lock": ^{ // TODO lock but dont dim and add seperate lock+dim action
			[userAgent lockAndDimDevice];
		},

		@"respring": ^{
			[[NSClassFromString(@"FBSystemService") sharedInstance] exitAndRelaunch:YES];
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

	// Low power mode
	ctx[@"lpm"] = @{
		@"setEnabled": ^(bool enabled) {
			[[NSClassFromString(@"_CDBatterySaver") sharedInstance] setMode:enabled];
		},

		@"isEnabled": ^{
			return [[NSClassFromString(@"_CDBatterySaver") sharedInstance] getPowerMode];
		}
	};

	// Airplane mode
	ctx[@"airplaneMode"] = @{
		@"isEnabled": ^{
			return [[[NSClassFromString(@"RadiosPreferences") alloc] init] airplaneMode];
		},

		@"setEnabled": ^(BOOL enabled) {
			[[[NSClassFromString(@"RadiosPreferences") alloc] init] setAirplaneMode:enabled];
		}
	};

	// Orientation lock
	ctx[@"orientationLock"] = @{
		@"setEnabled": ^(BOOL enabled) {
			if (enabled) {
				[[NSClassFromString(@"SBOrientationLockManager") sharedInstance] lock];
			} else {
				[[NSClassFromString(@"SBOrientationLockManager") sharedInstance] unlock];
			}
		},

		@"isEnabled": ^{
			return [[NSClassFromString(@"SBOrientationLockManager") sharedInstance] isUserLocked];
		}
	};

	// Dark mode
	ctx[@"systemStyle"] = @{
		@"toggle": ^{
			[[NSClassFromString(@"UIUserInterfaceStyleArbiter") sharedInstance] toggleCurrentStyle];
		},

		@"isDark": ^{
			return (bool)([[NSClassFromString(@"UIUserInterfaceStyleArbiter") sharedInstance] currentStyle]-1);
		}
	};
	
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
		[[NSClassFromString(@"SBCombinationHardwareButtonActions") alloc] performTakeScreenshotAction];
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
			// setupLogger(set);
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
}
