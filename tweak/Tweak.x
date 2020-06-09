// MK1 - Copyright (c) 2020 Castyte. All rights reserved.
// Modified work copyright (c) 2020 Skitty.

#import "Tweak.h"
#import "Util.h"
#import <dlfcn.h>

// Variables
// TODO: Store these in a better way
JSContext *ctx;
NSDictionary *scripts;
BOOL springBoardReady;
SBUserAgent *userAgent;
SpringBoard *springBoard;
SBWiFiManager *wifiMan;
BOOL vpnConnected;
VPNBundleController *vpnController;
AVFlashlight *flashlight;
int bluetoothConnectedHack;
MTAlarmManager *alarmManager;

// Hooks
// Detect button presses, enable battery monitoring
%hook SpringBoard

- (id)init {
	springBoard = %orig;
	return springBoard;
}

- (BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)arg1 {
	BOOL volUp = NO;
	BOOL volDown = NO;
	BOOL lock = NO;
	BOOL home = NO;
	BOOL touchID = NO;
	
	for (UIPress *press in arg1.allPresses.allObjects) {
		if (press.force != 1) continue;
		if (press.type == 102) { // Volume up
			volUp = YES;
		} else if(press.type == 103) { // Volume down
			volDown = YES;
		} else if(press.type == 104) { // Lock
			lock = YES;
		} else if(press.type == 101) { // Home
			home = YES;
		} else if(press.type == 100) { // Touch ID
			touchID = YES;
		}
	}

	if (home) {
		if (volUp) {
			activateTrigger(@"HWBUTTON-HOME+VOLUP");
		} else if (volDown) {
			activateTrigger(@"HWBUTTON-HOME+VOLDOWN");
		} else if (lock) {
			activateTrigger(@"HWBUTTON-HOME+POWER");
		} else {
			activateTrigger(@"HWBUTTON-HOME");
		}
	} else if (volUp) {
		if (volDown) {
			activateTrigger(@"HWBUTTON-VOLUP+VOLDOWN");
		} else {
			activateTrigger(@"HWBUTTON-VOLUP");
		}
	} else if (volDown) {
		activateTrigger(@"HWBUTTON-VOLDOWN");
	} else if (lock) {
		activateTrigger(@"HWBUTTON-POWER");
	} else if (touchID) {
		activateTrigger(@"HWBUTTON-TOUCHID");
	}
	
	return %orig;
}

- (void)applicationDidFinishLaunching:(id)application {
	%orig;

	springBoardReady = YES;
	if (triggerHasScripts(@"BATTERY-LEVELCHANGE") || triggerHasScripts(@"BATTERY-LEVEL20") || triggerHasScripts(@"BATTERY-LEVEL50")) {
		[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryLevelChanged) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
	}
}

%new
- (void)batteryLevelChanged {
	if (triggerHasScripts(@"BATTERY-LEVELCHANGE")) activateTrigger(@"BATTERY-LEVELCHANGE");
	if (triggerHasScripts(@"BATTERY-LEVEL20") || triggerHasScripts(@"BATTERY-LEVEL50")) { // TODO: somehow allow LEVELXX triggers
		if ((int)[UIDevice currentDevice].batteryLevel == 20) activateTrigger(@"BATTERY-LEVEL20");
		else if ((int)[UIDevice currentDevice].batteryLevel == 50) activateTrigger(@"BATTERY-LEVEL50");
	}
}

%end

// Detect shaking
%hook UIViewController

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	%orig;
    if (motion == UIEventSubtypeMotionShake) {
    	activateTrigger(@"DEVICE-SHAKE");
    }
}

%end

// Store SBUserAgent
%hook SBUserAgent

- (id)init {
	userAgent = %orig;
	return userAgent;
}

%end

// Wi-Fi activation state and network change triggers
%hook SBWiFiManager

- (id)init {
	wifiMan = %orig;
	return wifiMan;
}

- (void)_powerStateDidChange {
	%orig;
	if (!springBoardReady) return;
	dispatch_async(dispatch_get_main_queue(), ^{
		if ([self wiFiEnabled]) {
			activateTrigger(@"WIFI-ENABLED");
		} else {
			activateTrigger(@"WIFI-DISABLED");
		}
	});
}

- (void)_linkDidChange {
	%orig;
	if (!springBoardReady) return;
	dispatch_async(dispatch_get_main_queue(), ^{
		activateTrigger(@"WIFI-NETWORKCHANGE");
	});
}

%end

// Dark mode toggle trigger
%hook UIUserInterfaceStyleArbiter

- (void)userInterfaceStyleModeDidChange:(id)arg1 {
	%orig;
	dispatch_async(dispatch_get_main_queue(), ^{
		activateTrigger(@"DEVICE-DARKMODETOGGLE");
	});
}

%end

// Bluetooth connected tigger
%hook BluetoothManager

- (void)_connectedStatusChanged {
	%orig;
	dispatch_async(dispatch_get_main_queue(), ^{
		int count = [[[%c(BluetoothManager) sharedInstance] connectedDevices] count];
		if (bluetoothConnectedHack == count) return;
		bluetoothConnectedHack = count;
		activateTrigger(@"BLUETOOTH-CONNECTEDCHANGE");
	});
}

%end

// Status bar gestures
%hook _UIStatusBar

- (void)didMoveToWindow {
	UITapGestureRecognizer *doubleTap;

	if (triggerHasScripts(@"STATUSBAR-LONGPRESS")) {
		[self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(mk1longPressed)]];
	}

	if (triggerHasScripts(@"STATUSBAR-DOUBLETAP")) {
		doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mk1doubleTapped)];
		doubleTap.numberOfTapsRequired = 2;
		[self addGestureRecognizer:doubleTap];
	}

	if (triggerHasScripts(@"STATUSBAR-SINGLETAP")) {
		UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mk1singleTapped)];
		singleTap.numberOfTapsRequired = 1;
		if(triggerHasScripts(@"STATUSBAR-DOUBLETAP")) [singleTap requireGestureRecognizerToFail:doubleTap];
		[self addGestureRecognizer:singleTap];
	}

	if (triggerHasScripts(@"STATUSBAR-SWIPELEFT")) {
		UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(mk1swipedLeft)];
		swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
		[self addGestureRecognizer:swipeLeft];
	}

	if (triggerHasScripts(@"STATUSBAR-SWIPERIGHT")) {
		UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(mk1swipedRight)];
		swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
		[self addGestureRecognizer:swipeRight];
	}
}

%new
- (void)mk1swipedLeft {
	activateTrigger(@"STATUSBAR-SWIPELEFT");
}

%new
- (void)mk1swipedRight {
	activateTrigger(@"STATUSBAR-SWIPERIGHT");
}

%new
- (void)mk1singleTapped {
	activateTrigger(@"STATUSBAR-SINGLETAP");
}

%new
- (void)mk1doubleTapped {
	activateTrigger(@"STATUSBAR-DOUBLETAP");
}

%new
- (void)mk1longPressed {
	activateTrigger(@"STATUSBAR-LONGPRESS");
}

%end

// Store alarm manager
%hook MTAlarmManager

- (id)init{
	alarmManager = %orig;
	return alarmManager;
}

%end

// Battery charging trigger
%hook _UIBatteryView

- (void)setChargingState:(long long)arg1 {
	%orig;
	if (springBoardReady) activateTrigger(@"BATTERY-STATECHANGE");
}

%end

// VPN state triggers
%hook SBStatusBarStateAggregator

- (void)_updateVPNItem {
    %orig;
    SBTelephonyManager *telephonyManager = (SBTelephonyManager *)[%c(SBTelephonyManager) sharedTelephonyManager];

    if ([telephonyManager isUsingVPNConnection]) {
		vpnConnected = YES;
		activateTrigger(@"VPN-CONNECTED");
	}

	if (![telephonyManager isUsingVPNConnection] && vpnConnected) {
		vpnConnected = NO;
		activateTrigger(@"VPN-DISCONNECTED");
	}
}

%end

// Notification trigger and variable storage
%hook NCNotificationDispatcher

- (void)postNotificationWithRequest:(NCNotificationRequest *)req {
	%orig;
	if (triggerHasScripts(@"NOTIFICATION-RECEIVE")) {
		if ([[NSDate date] timeIntervalSinceDate:[req timestamp]] > 5) return;
		NCNotificationContent *content = [req content];
		initContextIfNeeded();
		ctx[@"NOTIFICATION_HEADER"] = content.header;
		ctx[@"NOTIFICATION_TITLE"] = content.title;
		ctx[@"NOTIFICATION_MESSAGE"] = content.message;
		ctx[@"NOTIFICATION_SUBTITLE"] = content.subtitle;
		ctx[@"NOTIFICATION_TOPIC"] = content.topic;
		activateTrigger(@"NOTIFICATION-RECEIVE");
	}
}

%end

// Store AVFlashlight
%hook AVFlashlight

- (id)init {
	flashlight = %orig;
	return flashlight;
}

%end

// Application launch trigger
%hook SBApplication

- (void)_processDidLaunch:(id)arg {
	%orig;
	activateTrigger(@"APPLICATION-LAUNCH");
}

%end

// Unlock/lock trigger
%hook SBLockScreenManager

- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
	%orig;
	activateTrigger(@"DEVICE-UNLOCK");
}

- (BOOL)_lockUI {
	if (springBoardReady) activateTrigger(@"DEVICE-LOCK");
	return %orig;
}

%end

// Update scripts
void updateScripts() {
    NSString *path = @"/Library/MK1/scripts.plist";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict writeToFile:path atomically:YES];
    }

	NSDictionary *scriptsPlist = [NSDictionary dictionaryWithContentsOfFile:path];
	NSMutableDictionary *mutableScripts = [NSMutableDictionary dictionary];
	
	for (NSString *script in scriptsPlist) {
		for (NSString *trigger in scriptsPlist[script][@"triggers"]) {
			if (![[mutableScripts allKeys] containsObject:trigger]) mutableScripts[trigger] = [NSMutableArray array];
			if (![mutableScripts[trigger] containsObject:script]) [mutableScripts[trigger] addObject:script];
		}
	}

	scripts = [mutableScripts copy];
}

// Constructor
%ctor {
	@autoreleasepool {
		updateScripts();

		dlopen("/System/Library/PreferenceBundles/VPNPreferences.bundle/VPNPreferences", RTLD_LAZY);
		vpnController = [[%c(VPNBundleController) alloc] initWithParentListController:nil];

		// Ringer toggle trigger
		[[NSNotificationCenter defaultCenter] addObserverForName:@"SBRingerChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *notif){
			if (springBoardReady) activateTrigger(@"HWBUTTON-RINGERTOGGLE");
		}];

		// Now playing change trigger
		[[NSNotificationCenter defaultCenter] addObserverForName:@"SBMediaNowPlayingChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *notif){
			if (springBoardReady) activateTrigger(@"MEDIA-NOWPLAYINGCHANGE");
		}];

		// Volume change notification
		[[NSNotificationCenter defaultCenter] addObserverForName:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil queue:nil usingBlock:^(NSNotification *notif){
			if (!springBoardReady) return;

			if ([notif.userInfo[@"AVSystemController_AudioCategoryNotificationParameter"] isEqualToString:@"Audio/Video"]) {
				activateTrigger(@"VOLUME-MEDIACHANGE");
			} else if([notif.userInfo[@"AVSystemController_AudioCategoryNotificationParameter"] isEqualToString:@"Ringtone"]) {
				activateTrigger(@"VOLUME-RINGERCHANGE");
			}
		}];
	}
}
