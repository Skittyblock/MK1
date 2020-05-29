// SBWiFiManager.h

@interface SBWiFiManager
- (BOOL)wiFiEnabled;
- (int)signalStrengthRSSI;
- (id)currentNetworkName;
- (void)_powerStateDidChange;
- (void)setWiFiEnabled:(BOOL)arg1;
- (BOOL)isPowered;
@end
