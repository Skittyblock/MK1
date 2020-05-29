// MTAlarm.h

@interface MTAlarm
@property (nonatomic, readonly) NSString *displayTitle; 
@property (assign, nonatomic) unsigned long long hour;
@property (assign, nonatomic) unsigned long long minute;
@property (assign, getter=isEnabled, nonatomic) BOOL enabled;
@property (getter=isSnoozed, nonatomic, readonly) BOOL snoozed;
@property (nonatomic, readonly) NSDate *nextFireDate;
- (id)alarmIDString;
@end
