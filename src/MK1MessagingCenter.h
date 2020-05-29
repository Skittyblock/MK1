// MK1MessagingCenter.h

#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

@interface MK1MessagingCenter : NSObject {
	CPDistributedMessagingCenter *_messagingCenter;
}
@end