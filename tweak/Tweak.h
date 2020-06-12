// Tweak.h

#import <JavaScriptCore/JavaScriptCore.h>
#import <MediaRemote/MediaRemote.h>

#import <AppSupport/AppSupport.h>
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

void updateScripts();

extern JSContext *ctx;
extern NSDictionary *scripts;
extern BOOL springBoardReady;
extern SBUserAgent *userAgent;
extern SpringBoard *springBoard;
extern SBWiFiManager *wifiMan;
extern BOOL vpnConnected;
extern VPNBundleController *vpnController;
extern AVFlashlight *flashlight;
extern int bluetoothConnectedHack;
extern MTAlarmManager *alarmManager;
