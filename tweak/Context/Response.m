// Response.m

#import "Response.h"
#import "Tweak.h"

@implementation Response

- (instancetype)initWithData:(NSData *)data {
	self = [super init];
	if (self) {
		self._text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	return self;
}

- (Promise *)json {
	Promise *promise = [[Promise alloc] init];

	return promise;
}

- (Promise *)text {
	Promise *promise = [[Promise alloc] init];

	JSGlobalContextRef globalContext = JSGlobalContextCreateInGroup(JSContextGroupCreate(), nil);
	JSValue *text = [JSValue valueWithJSValueRef:JSValueMakeString(globalContext, JSStringCreateWithUTF8CString([self._text UTF8String])) inContext:ctx];
	[promise resolve:text];

	return promise;
}

@end
