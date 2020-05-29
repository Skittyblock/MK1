// SBVolumeControl.h

@interface SBVolumeControl
+ (id)sharedInstance;
- (float)_effectiveVolume;
- (void)toggleMute;
- (void)increaseVolume;
- (void)decreaseVolume;
@end
