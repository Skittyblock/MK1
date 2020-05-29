// BluetoothManager-Class.h

@interface BluetoothManager
+ (id)sharedInstance;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)e;
- (id)connectedDevices;
- (id)pairedDevices;
@end
