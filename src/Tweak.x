// MK1 - Copyright (c) 2020 Castyte. All rights reserved.

#import "Tweak.h"
#include "Util.mm"
#import <dlfcn.h>
#import "Headers/CPDistributedMessagingCenter.h"
#import <rocketbootstrap/rocketbootstrap.h>
#import <MediaRemote/MediaRemote.h>
#include "Context.mm"


%hook SpringBoard

-(id)init{
	springBoard = %orig;
	return springBoard;
}

-(BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)arg1{
	
	BOOL up = NO;
	BOOL down = NO;
	BOOL lock = NO;
	BOOL home = NO;
	BOOL touchID = NO;
	
	for(UIPress* press in arg1.allPresses.allObjects){
		if(press.force != 1) continue;
		if (press.type == 102){ // UP
			up = YES;
		} else if(press.type == 103){ // DOWN
			down = YES;
		} else if(press.type == 104){ // LOCK
			lock = YES;
		} else if(press.type == 101){ // HOME
			home = YES;
		} else if(press.type == 100){ // TOUCHID
			touchID = YES;
		}
	}
	

	if(home){
		if(up){
			runAllForTrigger(@"HWBUTTON-HOME+VOLUP");
		} else if(down){
			runAllForTrigger(@"HWBUTTON-HOME+VOLDOWN");
		} else if(lock){
			runAllForTrigger(@"HWBUTTON-HOME+POWER");
		} else {
			runAllForTrigger(@"HWBUTTON-HOME");
		}
	} else if(up){
		if(down){
			runAllForTrigger(@"HWBUTTON-VOLUP+VOLDOWN");
		} else {
			runAllForTrigger(@"HWBUTTON-VOLUP");
		}
	} else if(down){
		runAllForTrigger(@"HWBUTTON-VOLDOWN");
	} else if(lock){
		runAllForTrigger(@"HWBUTTON-POWER");
	} else if(touchID){
		runAllForTrigger(@"HWBUTTON-TOUCHID");
	}
	
	return %orig;
}


-(void)applicationDidFinishLaunching:(id)application{
	%orig;

	springBoardReady = YES;
	if(triggerHasScripts(@"BATTERY-LEVELCHANGE") || triggerHasScripts(@"BATTERY-LEVEL20") || triggerHasScripts(@"BATTERY-LEVEL50")){
		[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryLevelChanged) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
	}
}

%new

-(void)batteryLevelChanged{
	if(triggerHasScripts(@"BATTERY-LEVELCHANGE")) runAllForTrigger(@"BATTERY-LEVELCHANGE");
	if(triggerHasScripts(@"BATTERY-LEVEL20") || triggerHasScripts(@"BATTERY-LEVEL50")){ // FIXME idk what to do about these LEVELXX triggers, they are retarded
		if((int)[UIDevice currentDevice].batteryLevel == 20) runAllForTrigger(@"BATTERY-LEVEL20");
		else if((int)[UIDevice currentDevice].batteryLevel == 50) runAllForTrigger(@"BATTERY-LEVEL50");
	}
}

%end



%hook UIViewController // TODO what in the shit

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
	%orig;
    if(motion == UIEventSubtypeMotionShake){
    	runAllForTrigger(@"DEVICE-SHAKE");
    }
}


%end


%hook SBUserAgent

-(id)init{
	userAgent = %orig;
	return userAgent;
}

%end

%hook SBWiFiManager

-(id)init{
	wifiMan = %orig;
	return wifiMan;
}

-(void)_powerStateDidChange{
	%orig;
	if(!springBoardReady) return;
	dispatch_async(dispatch_get_main_queue(), ^{
		if([self wiFiEnabled]){
			runAllForTrigger(@"WIFI-ENABLED");
		} else {
			runAllForTrigger(@"WIFI-DISABLED");
		}
	});
}


-(void)_linkDidChange{
	%orig;
	if(!springBoardReady) return;
	dispatch_async(dispatch_get_main_queue(), ^{
		runAllForTrigger(@"WIFI-NETWORKCHANGE");
	});
}

%end



%hook UIUserInterfaceStyleArbiter

-(void)userInterfaceStyleModeDidChange:(id)arg1{
	%orig;
	dispatch_async(dispatch_get_main_queue(), ^{
		runAllForTrigger(@"DEVICE-DARKMODETOGGLE");
	});
}

%end

%hook BluetoothManager

-(void)_connectedStatusChanged{
	%orig;
	dispatch_async(dispatch_get_main_queue(), ^{
		int count = [[[%c(BluetoothManager) sharedInstance] connectedDevices] count];
		if(bluetoothConnectedHack == count) return;
		bluetoothConnectedHack = count;
		runAllForTrigger(@"BLUETOOTH-CONNECTEDCHANGE");
	});
}

%end


%hook _UIStatusBar // this is disguting but it works ig

-(void)didMoveToWindow{
	UITapGestureRecognizer *doubleTap;

	if(triggerHasScripts(@"STATUSBAR-LONGPRESS")){
		[self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(mk1longPressed)]];
	}

	if(triggerHasScripts(@"STATUSBAR-DOUBLETAP")){
		doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mk1doubleTapped)];
		doubleTap.numberOfTapsRequired = 2;
		[self addGestureRecognizer:doubleTap];
	}

	if(triggerHasScripts(@"STATUSBAR-SINGLETAP")){
		UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mk1singleTapped)];
		singleTap.numberOfTapsRequired = 1;
		if(triggerHasScripts(@"STATUSBAR-DOUBLETAP")) [singleTap requireGestureRecognizerToFail:doubleTap];
		[self addGestureRecognizer:singleTap];
	}

	if(triggerHasScripts(@"STATUSBAR-SWIPELEFT")){
		UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(mk1swipedLeft)];
		swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
		[self addGestureRecognizer:swipeLeft];
	}

	if(triggerHasScripts(@"STATUSBAR-SWIPERIGHT")){
		UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(mk1swipedRight)];
		swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
		[self addGestureRecognizer:swipeRight];
	}
}


%new

-(void)mk1swipedLeft{
	runAllForTrigger(@"STATUSBAR-SWIPELEFT");
}

%new

-(void)mk1swipedRight{
	runAllForTrigger(@"STATUSBAR-SWIPERIGHT");
}


%new

-(void)mk1singleTapped{
	runAllForTrigger(@"STATUSBAR-SINGLETAP");
}

%new

-(void)mk1doubleTapped{
	runAllForTrigger(@"STATUSBAR-DOUBLETAP");
}

%new

-(void)mk1longPressed{
	runAllForTrigger(@"STATUSBAR-LONGPRESS");
}

%end

%hook MTAlarmManager

-(id)init{
	alarmManager = %orig;
	return alarmManager;
}

%end

%hook _UIBatteryView

-(void)setChargingState:(long long)arg1 {
	%orig;
	if(springBoardReady) runAllForTrigger(@"BATTERY-STATECHANGE");
}

%end

%hook SBStatusBarStateAggregator // hacky but it works

-(void)_updateVPNItem{
    %orig;
    SBTelephonyManager *telephonyManager = (SBTelephonyManager *)[%c(SBTelephonyManager) sharedTelephonyManager];

    if ([telephonyManager isUsingVPNConnection]){
		vpnConnected = YES;
		runAllForTrigger(@"VPN-CONNECTED");
	}

	if (![telephonyManager isUsingVPNConnection] && vpnConnected){
		vpnConnected = NO;
		runAllForTrigger(@"VPN-DISCONNECTED");
	}
}

%end

%hook NCNotificationDispatcher

-(void)postNotificationWithRequest:(NCNotificationRequest *)req{
	%orig;
	if(triggerHasScripts(@"NOTIFICATION-RECEIVE")){
		if([[NSDate date] timeIntervalSinceDate:[req timestamp]] > 5) return;
		NCNotificationContent *content = [req content];
		initContextIfNeeded();
		ctx[@"NOTIFICATION_HEADER"] = content.header;
		ctx[@"NOTIFICATION_TITLE"] = content.title;
		ctx[@"NOTIFICATION_MESSAGE"] = content.message;
		ctx[@"NOTIFICATION_SUBTITLE"] = content.subtitle;
		ctx[@"NOTIFICATION_TOPIC"] = content.topic;
		runAllForTrigger(@"NOTIFICATION-RECEIVE");
	}
}

%end


%hook AVFlashlight

-(id)init{
	flashlight = %orig;
	return flashlight;
}

%end

%hook SBApplication

-(void)_processDidLaunch:(id)arg{
	%orig;
	runAllForTrigger(@"APPLICATION-LAUNCH");
}

%end


%hook SBLockScreenManager

-(void)_finishUIUnlockFromSource:(int)source withOptions:(id)options{
	%orig;
	runAllForTrigger(@"DEVICE-UNLOCK");
}

-(BOOL)_lockUI{
	if(springBoardReady) runAllForTrigger(@"DEVICE-LOCK");
	return %orig;
}

%end

void updateScripts(){
	NSError *dError;
    NSData *data = [NSData dataWithContentsOfFile:@"/Library/MK1/scripts.json" options:kNilOptions error:&dError];
    if(dError){
    	MK1Log(MK1LogError, [dError localizedDescription]);
    	scripts = @{};
    	return;
    }

    NSError *jError;
	scripts = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jError];
	if(jError){
		MK1Log(MK1LogError, [jError localizedDescription]);
		scripts = @{};
	}

}


// TODO should probably put this shit somewhere else
@interface MYMessagingCenter : NSObject {
	CPDistributedMessagingCenter * _messagingCenter;
}
@end

@implementation MYMessagingCenter

+ (void)load {
	[self sharedInstance];
}

+ (instancetype)sharedInstance {
	static dispatch_once_t once = 0;
	__strong static id sharedInstance = nil;
	dispatch_once(&once, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

- (instancetype)init {
	if ((self = [super init])) {
		_messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.castyte.mk1"];
		rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);

		[_messagingCenter runServerOnCurrentThread];
		[_messagingCenter registerForMessageName:@"runscript" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
		[_messagingCenter registerForMessageName:@"runtrigger" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
		[_messagingCenter registerForMessageName:@"updateScripts" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
	}

	return self;
}

- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	if([name isEqualToString:@"runscript"] && userInfo[@"name"]){
		initContextIfNeeded();
		if(userInfo[@"arg"]) ctx[@"MK1_ARG"] = userInfo[@"arg"];
		runScriptWithName(userInfo[@"name"]);
	} else if([name isEqualToString:@"runtrigger"] && userInfo[@"name"]){
		initContextIfNeeded();
		if(userInfo[@"arg"]) ctx[@"MK1_ARG"] = userInfo[@"arg"];
		runAllForTrigger(userInfo[@"name"]);
	} else if([name isEqualToString:@"updateScripts"]){
		updateScripts();
	}
	return @{};
}

@end


%ctor{
	@autoreleasepool {
		updateScripts();

		dlopen("/System/Library/PreferenceBundles/VPNPreferences.bundle/VPNPreferences", RTLD_LAZY);
		vpnController = [[%c(VPNBundleController) alloc] initWithParentListController:nil];


		[[NSNotificationCenter defaultCenter] addObserverForName:@"SBRingerChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *notif){
			if(springBoardReady) runAllForTrigger(@"HWBUTTON-RINGERTOGGLE");
		}];

		[[NSNotificationCenter defaultCenter] addObserverForName:@"SBMediaNowPlayingChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *notif){
			if(springBoardReady) runAllForTrigger(@"MEDIA-NOWPLAYINGCHANGE");
		}];

		[[NSNotificationCenter defaultCenter] addObserverForName:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil queue:nil usingBlock:^(NSNotification *notif){
			if(!springBoardReady) return;

			if([notif.userInfo[@"AVSystemController_AudioCategoryNotificationParameter"] isEqualToString:@"Audio/Video"]){
				runAllForTrigger(@"VOLUME-MEDIACHANGE");
			} else if([notif.userInfo[@"AVSystemController_AudioCategoryNotificationParameter"] isEqualToString:@"Ringtone"]){
				runAllForTrigger(@"VOLUME-RINGERCHANGE");
			}

		}];
	}
}

