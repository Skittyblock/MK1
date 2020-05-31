# MK1 DOCUMENTATION
Better documentation will be coming soon, but here is the original for now.

# General Information
Scripts are stored as `/Library/MK1/Scripts/SCRIPT_NAME.js`  
The trigger that the scripts run on is defined in a JSON file at `/Library/MK1/scripts.json`  
The structure if this file is as follows:
```json
{
	"TRIGGER_NAME": [
		"SCRIPT_NAME",
		"OTHER_SCRIPT_NAME"
	]
}
```  
The trigger name is the part before the '.js' in the scripts folder.  
You must respring for changes to `scripts.json` to take affect.  
  
## Other ways to trigger scripts
*Here arg is an optional argument which is passed into the script and saved in the `MK1_ARG` variable*   
You can run scripts or open the MK1 App using it's URL Scheme: `mk1://runscript/<scriptname>/[arg]`   
You can run triggers using the same URL Scheme: `mk1://runtrigger/<triggername>/[arg]`  
You can use the includes cli tool: `mk1 <runscript | runtrigger> <name> [arg]`  
   
Using the control center module with the trigger `CONTROLCENTER-MODULE` (Seperate package)  
Using XenHTML with the same URL Schemes as above, using `href`, `window.location` or others (seperate package)     
  
## Sharing scripts
Script can be easily shared using the MK1 App. Simply select a script and choose the 'Share Script' option. This will upload the script and generate a unique URL where it can be shared publicly for other people to get your script.  
  
## Other Notes
If you are writing scripts on iOS make sure you disable `Smart Punctuation` in `Settings > General > Keyboard` or you will get errors when using quotes.  
If you want to exit a script prematurely you can throw an exception with the string `MK1_EXIT`. (eg: `throw "MK1_EXIT"`)    
    
# Triggers
  
HWBUTTON-VOLUP  
HWBUTTON-VOLDOWN  
HWBUTTON-VOLUP+VOLDOWN    
HWBUTTON-POWER  
HWBUTTON-HOME  
HWBUTTON-HOME+VOLUP  
HWBUTTON-HOME+VOLDOWN 
HWBUTTON-HOME+POWER  
HWBUTTON-RINGERTOGGLE  
HWBUTTON-TOUCHID  
  
STATUSBAR-SINGLETAP  
STATUSBAR-DOUBLETAP  
STATUSBAR-LONGPRESS  
STATUSBAR-SWIPELEFT  
STATUSBAR-SWIPERIGHT  
   
BATTERY-STATECHANGE  
BATTERY-LEVELCHANGE  
BATTERY-LEVEL20  
BATTERY-LEVEL50  
  
WIFI-ENABLED  
WIFI-DISABLED  
WIFI-NETWORKCHANGE  
  
BLUETOOTH-CONNECTEDCHANGE  *Triggered when the connected bluetooth device changes*  
  
VPN-CONNECTED  
VPN-DISCONNECTED  
  
APPLICATION-LAUNCH  
  
DEVICE-DARKMODETOGGLE  
DEVICE-SHAKE  
DEVICE-LOCK  
DEVICE-UNLOCK  
  
MEDIA-NOWPLAYINGCHANGE
  
VOLUME-MEDIACHANGE  
VOLUME-RINGERCHANGE  
    
CONTROLCENTER-MODULE *requires seperate package*  

NOTIFICATION-RECEIVE   
*this one is special - it sets variables when fired: NOTIFICATION_HEADER, NOTIFICATION_TITLE, NOTIFICATION_MESSAGE, NOTIFICATION_SUBTITLE, NOTIFICATION_TOPIC*
  
# Actions
  
## Uncategorised
TimeoutID setTimeout(Function cb(), Number ms)  
IntervalID setInterval(Function cb(), Number ms)  
void clearTimeout(TimeoutID timeout)  
void clearInterval(IntervalID interval)  
  
void alert(String title, String msg) 
    *Shows a system alert dialog with the title and message (both optional)*  

void confirm(String title, String msg, Function cb(bool choice))  
    *Shows a confirmation dialog to the user with options "OK" or "Cancel"*  
    *If the user chooses "Ok" then the choice argument in the callback function is set to true, otherwise false*  
  
void prompt(String title String msg, Function cb(String text))  
    *Shows a text box for the user to enter text*  
    *Text is sent to the callback function in the text argument*  
  
void menu(String title, String msg, Array<String> options, Function cb(Number choice))  
    *Shows a menu of options for the user to choose*    
    *Options defined in the options array with format: `["Option 1", "Option 2"]` etc. (can have any number of options)*    
    *The option the user chooses is sent to the callback function in the choice argument as the index of the option they chose (eg. Option 1 would be 0)*  
  
  
void shellrun(String command, Function cb(Number exitStatus, String stdout, String stderr))     
void openURL(String url)  
void openApp(String bundleID)  
void sendDarwinNotif(String notif)  
void takeScreenshot()  
Object sendRocketBootstrapMessage(String center, String message, Object userInfo)  
void textToSpeech(String text)  
void toggleReachability() *Only on supported devices*  
  
## Console
*Text sent to the console is viewable inside the MK1 App or at `/tmp/MK1.log`*  
void console.log(String text)  
void console.info(String text)  
void console.warn(String text)  
void console.error(String text)  
  
# Clipboard
String clipboard.get()  
void clipboard.set(String s)  
   
## Current App
bool currentApp.isSpringBoard()  
String currentApp.bundleID()  
String currentApp.name()  
  
## Volume
Number volume.getRinger()  *Float between 0 and 1*  
void volume.setRinger(Number vol)  
Number volume.getMedia()  
void volume.setMedia(Number vol)  
    
## Media
void media.play()  
void media.pause()  
void media.stop()  
void media.nextTrack()  
void media.previousTrack()  

void media.getNowPlayingInfo(Function cb(Object info))  
    *This returns an object with information to the callback*  
    *Keys in this object can be found here: https://pastebin.com/6AUsirtX *    
    *If no media is playing then info will be null*  
    *When the media is paused kMRMediaRemoteNowPlayingInfoPlaybackRate is 0.*  
    
## Wifi
bool wifi.isEnabled()  
void wifi.setEnabled(bool enabled)  
String wifi.networkName()  
String wifi.signalRSSI()  
  
## Bluetooth  
bool bluetooth.isEnabled()  
void bluetooth.setEnabled(bool enabled)  
Array<BTDeviceID> bluetooth.connectedDevices()  *Returns an array of unique device ID's which can be used in the 'Bluetooth Device' functions*  
Array<BTDeviceID> bluetooth.pairedDevices()  
  
## Bluetooth Device
String bluetoothDevice.name(BTDeviceID id)  
String bluetoothDevice.address(BTDeviceID id)  
bool bluetoothDevice.paired(BTDeviceID id)  
void bluetoothDevice.unpair(BTDeviceID id)  
bool bluetoothDevice.connected(BTDeviceID id)  
void bluetoothDevice.connect(BTDeviceID id)  
void bluetoothDevice.disconnect(BTDeviceID id)  
Number bluetoothDevice.batteryLevel(BTDeviceID id)  *Integer between 0 and 100*
Number bluetoothDevice.vendorID(BTDeviceID id)  
Number bluetoothDevice.productID(BTDeviceID id)  
    
## Device 
*Most of these methods are from UIDevice, see detailed docs here: https://developer.apple.com/documentation/uikit/uidevice*  
String device.name()  
String device.systemName()  
String device.systemVersion()  
String device.model()  
String device.identifierForVendor()  
Number device.orientation()  
bool device.isPortrait()  
bool device.isLandscape()  
Number device.batteryLevel()  *Float between 0 and 100*  
Number device.batteryState()  *1 = not charging, 2 = charging*  
void device.shutdown()  
void device.reboot()  
void device.safemode()  
void device.lock()  
void device.respring()  
bool device.isLocked()  
bool device.screenIsOn()  
  
## System UI
bool systemUI.isControlCenterShowing()  
bool systemUI.isHomeScreenShowing()  
bool systemUI.isCoverSheetShowing()  *(Lockscreen or notification center)*  
  
## Brightness
Number brightness.getLevel()  *Float between 0 and 1*
void brightness.setLevel(Number level)  

## VPN
bool vpn.isConnected()  
void vpn.setEnabled(bool enabled)  
  
## Flashlight
Number flashlight.getLevel()  *Float between 0 and 1*  
void flashlight.setLevel(Number level)  
  
## LPM (Low Power Mode)
bool lpm.isEnabled()  
void lpm.setEnabled(bool enabled)  
  
## Orientation Lock
bool orientationLock.isEnabled()  
void orientationLock.setEnabled(bool enabled)  
  
## System Style
bool systemStyle.isDark()  
void systemStyle.toggle()  
  
## File
String file.read(String path)  *Must have the correct permissions to read/write files.*  
void file.write(String path, String data)  *It is recommended to only write files to `MK1.scriptDataDir`*    
Object file.readPlist(String path)  *Read a plist file into a javascript object*  
void file.writePlist(String path, Object data)   
void file.writePreferencesPlist(String domain, Object data) *Required for preferences to update without restarting (in conjunction with sendDarwinNotif)  
    
## Alarms
Array<AlarmID> allAlarms()  *This is an global function unlike the others and is not a property of alarm*  
  
String alarm.getTitle(AlarmID id)  
Number alarm.getHour(AlarmID id)  
Number alarm.getMinute(AlarmID id)  
bool alarm.isEnabled(AlarmID id)  
bool alarm.isSnoozed(AlarmID id)  
Date alarm.getNextFireDate(AlarmID id)  
void alarm.setEnabled(AlarmID id, bool enabled)  
void alarm.setHour(AlarmID id, Number hour)  
void alarm.setMinute(AlarmID id, Number minute)  
void alarm.snooze(AlarmID id)  
  
## Airplane Mode
bool airplaneMode.isEnabled()  
void airplaneMode.setEnabled(bool enabled)  
  
## Cellular Data
bool cellularData.isEnabled()  
void cellularData.setEnabled(bool enabled)  
  
## MK1
void MK1.runScript(String scriptName, String arg)  *Arg saved in MK1_ARG variable*
void MK1.runTrigger(String triggerName, String arg)  
String MK1.version  
String MK1.commit  
String MK1.copyright  
String MK1.scriptDataDir  
void MK1.setAlertOnError(bool alertOnError)  *Disables showing a UI alert upon an error/exception*  
  
# RocketBootstrap Interface
MK1 has a RocketBootrap center which can be used to run scripts or triggers.  
The center name is `com.castyte.mk1`  
There are 2 messages available: `runscript` and `runtrigger`. Both accept the following userInfo dictionary:

```json
    {
        "name": "The name of the script/trigger to run",
        "arg": "Argument passed to the script(s) and stored in MK1_ARG variable. (Optional)"
    }
```  
   
# Extensions

## Hard Actions
Hard actions are actions written in Objective-C to add a function to be used in scripts.  
They are dynamic libraries which should be located at `/Library/MK1/Extensions/HardActions/`. 
They should have a filename in the format: `<name>.dylib`.  
The name will be used to add the function do javascript as `ext.<name>()`.  
Hard actions should look something like:  
```objc
id MK1Action(NSArray *args){

}
```  
The library must have a function with this signature which will be called whenever the function is called from javascript.   
The args array contains the function arguments used in javascript, converted to their objective-c object counterparts.  
EG: JavaScript `Number` becomes `NSNumber *` and JavaScript `String` becomes `NSString *`.  
The function must return an `id` type.  
   
# Credits
Copyright (c) Castyte 2020  
Modified work copyright (c) Skitty 2020  
MK1 was originally created and developed by Castyte (Twitter: @castyte)  
Development has been continued by Skitty (Twitter: @Skittyblock)  
Some action contributions by Tr1Fecta (Twitter: @FectaTr1)  
RocketBootstrap by Ryan Petrich (Twitter: @rpetrich)  
CCSupport by opa334 (Twitter: @opa334dev)  *Used in the Control Center addon*  
XenHTML by machstick (Twitter: @machstick)  *Used in the XenHTML addon*  