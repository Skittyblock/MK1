// MKMessagingCenter.m

#import "MKMessagingCenter.h"
#import "Tweak.h"
#import "Util.h"
#import "MKContextManager.h"
#import <JavaScriptCore/JavaScriptCore.h>

@implementation MKMessagingCenter

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
	self = [super init];

	if (self) {
		_messagingCenter = [CPDistributedMessagingCenter centerNamed:@"xyz.skitty.mk1"];
		rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);

		[_messagingCenter runServerOnCurrentThread];
		[_messagingCenter registerForMessageName:@"runscript" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
		[_messagingCenter registerForMessageName:@"runScript" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
		[_messagingCenter registerForMessageName:@"runtrigger" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
		[_messagingCenter registerForMessageName:@"runTrigger" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
		[_messagingCenter registerForMessageName:@"updateScripts" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
		
		[_messagingCenter registerForMessageName:@"runCode" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
	}

	return self;
}

- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	if (([name isEqualToString:@"runscript"] || [name isEqualToString:@"runScript"]) && userInfo[@"name"]) {
		initContextIfNeeded();
		if (userInfo[@"arg"]) ctx[@"MK1_ARG"] = userInfo[@"arg"];
		runScriptWithName(userInfo[@"name"]);
	} else if (([name isEqualToString:@"runtrigger"] || [name isEqualToString:@"runtrigger"]) && userInfo[@"name"]) {
		initContextIfNeeded();
		if (userInfo[@"arg"]) ctx[@"MK1_ARG"] = userInfo[@"arg"];
		activateTrigger(userInfo[@"name"]);
	} else if ([name isEqualToString:@"updateScripts"]) {
		updateScripts();
	} else if ([name isEqualToString:@"runCode"]) {
		JSValue *result = [[MKContextManager sharedManager] runCode:userInfo[@"code"]];
		return @{
			@"result": [result toString]
		};
	}
	return @{};
}

@end
