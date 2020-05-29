// FBSystemService.h

@interface FBSystemService
+ (id)sharedInstance;
- (void)shutdownAndReboot:(int)n;
- (void)shutdownWithOptions:(long)o;
- (void)exitAndRelaunch:(BOOL)b;
@end
