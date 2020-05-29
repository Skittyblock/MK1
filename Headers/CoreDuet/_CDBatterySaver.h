// _CDBatterySaver.h

@interface _CDBatterySaver
+ (id)sharedInstance;
- (long long)getPowerMode;
- (long long)setMode:(long long)m;
@end
