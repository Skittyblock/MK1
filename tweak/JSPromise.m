// JSPromise.m

#import "JSPromise.h"
#import "Util.h"

@implementation JSPromise

- (instancetype)then:(JSValue *)resolve {
	self.resolve = resolve;
	self.next = [[JSPromise alloc] init];

	if (self.timer) _timer.fireDate = [NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]];
	self.next.timer = self.timer;
	self.timer = nil;

	return _next;
}

- (instancetype)catch:(JSValue *)reject {
	self.reject = reject;
	self.next = [[JSPromise alloc] init];

	if (self.timer) _timer.fireDate = [NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]];
	self.next.timer = self.timer;
	self.timer = nil;

	return self.next;
}

- (void)fail:(NSString *)error {
	if (self.reject) {
		[self.reject callWithArguments:@[error]];
	} else if (self.next) {
		[self.next fail:error];
	}
}

- (void)success:(id)value {
	if (!self.resolve) return;
	JSValue *result;
	if (value) {
		result = [self.resolve callWithArguments:@[value]];
	} else {
		result = [self.resolve callWithArguments:@[]];
	}

	if (!self.next) return;
	if (result) {
		if (result.isUndefined) {
			[self.next success:nil];
			return;
		} else if ([result hasProperty:@"isError"]) {
			[self.next fail:[result toString]];
		}
	}

	[self.next success:value];
}

@end
