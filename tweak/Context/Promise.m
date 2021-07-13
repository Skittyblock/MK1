// Promise.m

#import "Promise.h"
#import "Tweak.h"
#import "Util.h"

@implementation Promise

- (instancetype)init {
	self = [super init];
	if (self) {
        self.resultObservers = [NSMutableArray new];
        self.errorObservers = [NSMutableArray new];
		self.resolved = NO;
	}
	return self;
}

- (instancetype)initWithExecutor:(JSValue *)executor {
	self = [super init];
	if (self) {
		self.executor = executor;
        self.resultObservers = [NSMutableArray new];
        self.errorObservers = [NSMutableArray new];
		self.resolved = NO;
		[self execute];
	}
	return self;
}

- (instancetype)then:(JSValue *)resolve {
	if (!resolve) return self;

	self.returnPromise = [[Promise alloc] init];
	[self.resultObservers addObject:resolve];
    [self update];
    return self.returnPromise;
}

- (instancetype)catch:(JSValue *)reject {
	if (!reject) return self;

	self.returnPromise = [[Promise alloc] init];
	[self.errorObservers addObject:reject];
    [self update];
    return self.returnPromise;
}

- (void)resolve:(JSValue *)value {
	if (!value) return;

	if ([[value toObject] isKindOfClass:Promise.class]) {
		Promise *promise = (Promise *)[value toObject];
		if (promise.resolved) value = promise.result;
		else {
			// TODO: support this
		}
	}

	self.result = value;
    self.resolved = YES;
    [self update];
}

- (void)reject:(JSValue *)value {
	if (!value) return;

	if ([[value toObject] isKindOfClass:Promise.class]) {
		Promise *promise = (Promise *)[value toObject];
		if (promise.error) self.error = promise.error;
	} else {
		self.error = value;
	}
    [self update];
}

- (void)fail:(NSString *)errorString {
	self.error = [JSValue valueWithNewErrorFromMessage:errorString inContext:ctx];
	[self update];
}

- (void)execute {
	@try {
		[self.executor callWithArguments:@[
			^(JSValue *result) {
				[self resolve:result];
			},
			^(JSValue *error) {
				[self reject:error];
			}
		]];
	} @catch (NSException *exception) {
		[self fail:exception.reason];
	}
}

- (void)update {
	if (self.resolved && self.result) {
        for (JSValue *resolution in self.resultObservers) {
			JSValue *retVal = [resolution callWithArguments:@[self.result]];
			if (retVal && self.returnPromise) [self.returnPromise resolve:retVal];
        }
        [self.resultObservers removeAllObjects];
    } else if (self.error != nil) {

		if (self.returnPromise) {
			self.returnPromise.error = self.error;
			[self.returnPromise update];
		} else if (self.errorObservers.count == 0) {
			// alertError(@"Unhandled Promise rejection");
		}

        for (JSValue *rejection in self.errorObservers) {
			[rejection callWithArguments:@[self.error]];
        }
        [self.errorObservers removeAllObjects];
	}
}

@end
