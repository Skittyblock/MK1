// MK1 Control Center Module - Copyright (c) 2020 Castyte. All rights reserved.


#import "mk1cc.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

@implementation mk1cc

-(UIImage *)iconGlyph{
	return [UIImage imageNamed:@"ModuleIcon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

-(BOOL)isSelected{
  return NO;
}

-(void)setSelected:(BOOL)selected{
  if(selected){
    static CPDistributedMessagingCenter *c = nil;
	c = [CPDistributedMessagingCenter centerNamed:@"com.castyte.mk1"];
	rocketbootstrap_distributedmessagingcenter_apply(c);
	[c sendMessageName:@"runtrigger" userInfo:@{@"name":@"CONTROLCENTER-MODULE"}];
  }
}

@end
