// SBTelephonyManager.h

@interface SBTelephonyManager : NSObject
+ (instancetype)sharedTelephonyManager;
- (bool)isUsingVPNConnection;
@end
