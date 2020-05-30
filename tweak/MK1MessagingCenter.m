// MK1MessagingCenter.m

#import "MK1MessagingCenter.h"
#import "Tweak.h"
#import "Util.h"

@implementation MK1MessagingCenter

+ (void)load {
	[self sharedInstance];
}

+ (instancetype)sharedInstance {
	static dispatch_once_t once = 0;
	__strong static id sharedInstance = nil;
	dispatch_once(&once, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

- (instancetype)init {
	if ((self = [super init])) {
		_messagingCenter = [CPDistributedMessagingCenter centerNamed:@"xyz.skitty.mk1"];
		rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);

		[_messagingCenter runServerOnCurrentThread];
		[_messagingCenter registerForMessageName:@"runscript" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
		[_messagingCenter registerForMessageName:@"runtrigger" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
		[_messagingCenter registerForMessageName:@"updateScripts" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
	}

	return self;
}

- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	if ([name isEqualToString:@"runscript"] && userInfo[@"name"]) {
		initContextIfNeeded();
		if(userInfo[@"arg"]) ctx[@"MK1_ARG"] = userInfo[@"arg"];
		runScriptWithName(userInfo[@"name"]);
	} else if ([name isEqualToString:@"runtrigger"] && userInfo[@"name"]) {
		initContextIfNeeded();
		if(userInfo[@"arg"]) ctx[@"MK1_ARG"] = userInfo[@"arg"];
		runAllForTrigger(userInfo[@"name"]);
	} else if([name isEqualToString:@"updateScripts"]) {
		updateScripts();
	}
	return @{};
}

@end
