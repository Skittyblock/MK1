// XMLHttpRequest.m

#import "XMLHttpRequest.h"
#import "Util.h"

@implementation XMLHttpRequest {
	NSString *_method;
	NSString *_url;
	NSMutableDictionary *_headers;
	BOOL _async;
	JSManagedValue *_onLoad;
	JSManagedValue *_onReadyStateChange;
	JSManagedValue *_onError;
}

@synthesize responseText;
@synthesize readyState;
@synthesize status;

// open(method, url, async)
- (void)open:(NSString *)httpMethod :(NSString *)url :(bool)async; {
	_method = httpMethod;
	_url = url;
	_async = async;
	self.readyState = 1;
}

// setRequestHeader(key, value)
- (void)setRequestHeader:(NSString *)key :(NSString *)value {
	if (!_headers) _headers = [NSMutableDictionary dictionary];
	_headers[key] = value;
}

// onload
- (void)setOnload:(JSValue *)onload {
	_onLoad = [JSManagedValue managedValueWithValue:onload];
	[[[JSContext currentContext] virtualMachine] addManagedReference:_onLoad withOwner:self];
}

- (JSValue *)onload {
	return _onLoad.value;
}

// onreadystatechange
- (void)setOnreadystatechange:(JSValue *)onReadyStateChange {
	_onReadyStateChange = [JSManagedValue managedValueWithValue:onReadyStateChange];
	[[[JSContext currentContext] virtualMachine] addManagedReference:_onReadyStateChange withOwner:self];
}

- (JSValue *)onreadystatechange {
	return _onReadyStateChange.value;
}

// onerror
- (void)setOnerror:(JSValue *)onerror {
	_onError = [JSManagedValue managedValueWithValue:onerror];
	[[[JSContext currentContext] virtualMachine] addManagedReference:_onError withOwner:self];
}

- (JSValue *)onerror {
	return _onError.value;
}

// send(body)
- (void)send:(id)body {
	self.readyState = 2;

	NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_url]];
	req.HTTPMethod = _method;

	NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    req.HTTPBody = data;

	for (NSString *items in _headers.allKeys) {
		[req setValue:_headers[items] forHTTPHeaderField:items];
	}

	self.readyState = 3;
	[[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		self.responseText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		self.status = [(NSHTTPURLResponse *)response statusCode];

		self.readyState = 4;
		if (!error) {
			if (_onLoad) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[[_onLoad.value invokeMethod:@"bind" withArguments:@[self]] callWithArguments:NULL];
				});
			} else if (_onReadyStateChange) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[[_onReadyStateChange.value invokeMethod:@"bind" withArguments:@[self]] callWithArguments:NULL];
				});
			}
		} else if (error && _onError) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[_onError.value invokeMethod:@"bind" withArguments:@[self]] callWithArguments:@[[JSValue valueWithNewErrorFromMessage:error.localizedDescription inContext:[JSContext currentContext]]]];
			});
		}
	}] resume];
}

@end
