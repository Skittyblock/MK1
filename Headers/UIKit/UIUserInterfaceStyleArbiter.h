// UIUserInterfaceStyleArbiter.h

@interface UIUserInterfaceStyleArbiter
+ (id)sharedInstance;
- (void)toggleCurrentStyle;
- (long long)currentStyle;
@end
