// BluetoothDevice.h

@interface BluetoothDevice
- (id)scoUID;
- (id)name;
- (id)address;
- (BOOL)connected;
- (void)disconnect;
- (void)connect;
- (int)batteryLevel;
- (unsigned)vendorId;
- (BOOL)paired;
- (unsigned)productId;
- (void)unpair;
@end
