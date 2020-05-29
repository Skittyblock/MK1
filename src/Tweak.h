#import <JavaScriptCore/JavaScriptCore.h>
#import "Headers/NCNotificationContent.h"


@interface NCNotificationRequest
-(NCNotificationContent *)content;
-(NSDate *)timestamp;
@end

@interface SBUserAgent
-(_Bool)deviceIsLocked;
-(_Bool)springBoardIsActive;
-(_Bool)isScreenOn;
-(void)lockAndDimDevice;
@end

@interface SpringBoard : UIApplication
-(id)_accessibilityFrontMostApplication;
-(long long)activeInterfaceOrientation;
@end

@interface _UIStatusBar : UIView
@end

@interface SBWiFiManager
-(BOOL)wiFiEnabled;
-(int)signalStrengthRSSI;
-(id)currentNetworkName;
-(void)_powerStateDidChange;
-(void)setWiFiEnabled:(BOOL)arg1;
-(BOOL)isPowered;
@end

@interface BluetoothManager
+(id)sharedInstance;
-(BOOL)enabled;
-(void)setEnabled:(BOOL)e;
-(id)connectedDevices;
-(id)pairedDevices;
@end

@interface SBReachabilityManager
+(id)sharedInstance;
-(void)toggleReachability;
-(void)setReachabilityEnabled:(BOOL)arg1;
@end

@interface BluetoothDevice
-(id)scoUID;
-(id)name;
-(id)address;
-(BOOL)connected;
-(void)disconnect;
-(void)connect;
-(int)batteryLevel;
-(unsigned)vendorId;
-(BOOL)paired;
-(unsigned)productId;
-(void)unpair;
@end


@interface FBSystemService
+(id)sharedInstance;
-(void)shutdownAndReboot:(int)n;
-(void)shutdownWithOptions:(long)o;
-(void)exitAndRelaunch:(BOOL)b;
@end

@interface SBTelephonyManager : NSObject
+ (instancetype)sharedTelephonyManager;
-(bool)isUsingVPNConnection;
@end

@interface VPNBundleController
-(id)initWithParentListController:(id)l;
-(void)setVPNActive:(BOOL)a;
@end

@interface UIApplication (egg___FuckUIAppAllMyHomiesLoveSpringBoard)
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end

@interface AVFlashlight
-(float)flashlightLevel;
-(void)setFlashlightLevel:(float)l withError:(NSError *)e;
@end

@interface _CDBatterySaver
+(id)sharedInstance;
-(long long)getPowerMode;
-(long long)setMode:(long long)m;
@end

@interface SBOrientationLockManager
+(id)sharedInstance;
-(void)lock;
-(void)unlock;
-(BOOL)isUserLocked;
@end

@interface UIUserInterfaceStyleArbiter
+(id)sharedInstance;
-(void)toggleCurrentStyle;
-(long long)currentStyle;
@end

@interface RadiosPreferences
-(BOOL)airplaneMode;
-(void)setAirplaneMode:(BOOL)arg1;
@end

@interface SBCombinationHardwareButtonActions
-(void)performTakeScreenshotAction;
@end

@interface SBVolumeControl
+(id)sharedInstance;
-(float)_effectiveVolume;
-(void)toggleMute;
-(void)increaseVolume;
-(void)decreaseVolume;
@end

@interface PSCellularDataSettingsDetail
+(void) setEnabled:(BOOL)arg1;
+(BOOL) isEnabled;
@end

@interface AVSystemController
+(id)sharedAVSystemController;
-(BOOL)getVolume:(float*)arg1 forCategory:(id)arg2;
-(BOOL)setVolumeTo:(float)arg1 forCategory:(id)arg2;
@end

@interface SBBrightnessController
+(id)sharedBrightnessController;
-(void)setBrightnessLevel:(float)l;
@end

@interface MTAlarmManager

-(unsigned long long)alarmCount;
-(id)alarmAtIndex:(unsigned long long)arg1;
-(id)updateAlarm:(id)arg1;
-(id)snoozeAlarmWithIdentifier:(id)arg1;
@end

@interface MTAlarm

@property (nonatomic,readonly) NSString * displayTitle; 
@property (assign,nonatomic) unsigned long long hour;
@property (assign,nonatomic) unsigned long long minute;
@property (assign,getter=isEnabled,nonatomic) BOOL enabled;
@property (getter=isSnoozed,nonatomic,readonly) BOOL snoozed;
@property (nonatomic,readonly) NSDate * nextFireDate;
-(id)alarmIDString;
@end

enum MK1LogType {
    MK1LogInfo, MK1LogWarn, MK1LogDebug, MK1LogError
};

void runScriptWithName(NSString *name);
void setupContext();
void setupLogger(BOOL alertOnError);
void runAllForTrigger(NSString *trigger);
void setupHardActions();
void alertError(NSString *msg);
void MK1Log(enum MK1LogType type, NSString *str);
void initContextIfNeeded();
NSString *toStringCheckNull(JSValue *val);

UIWindow *veryRootWindow;
UIViewController *veryRootVC;

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