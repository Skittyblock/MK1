// MKMessagingCenter.h

#import "../Headers/AppSupport/CPDistributedMessagingCenter.h"
#import <rocketbootstrap/rocketbootstrap.h>

@interface MKMessagingCenter : NSObject {
	CPDistributedMessagingCenter *_messagingCenter;
}
@end