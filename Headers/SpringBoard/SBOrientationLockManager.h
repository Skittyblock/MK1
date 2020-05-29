// SBOrientationLockManager.h

@interface SBOrientationLockManager
+ (id)sharedInstance;
- (void)lock;
- (void)unlock;
- (BOOL)isUserLocked;
@end
