// MKContextManager.m

#import "MKContextManager.h"
#import "Context.h"
#import "Util.h"

#import "Console.h"
#import "fs.h"
#import "os.h"
#import "XMLHttpRequest.h"
#import "Promise.h"
#import "Response.h"

@implementation MKContextManager

- (instancetype)init {
	self = [super init];
	if (self) {
		self.vm = [[JSVirtualMachine alloc] init];
		self.defaultModules = @[@"fs", @"os"];
	}
	return self;
}

+ (instancetype)sharedManager {
	static MKContextManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[MKContextManager alloc] init];
	});
	return sharedInstance;
}

- (void)createNewContext {
	self.currentContext = [[JSContext alloc] initWithVirtualMachine:self.vm];
	[self setupExceptionHandlerForContext:self.currentContext];
	[self setupGlobalFunctionsForContext:self.currentContext];
}

- (Class)classOfDefaultModule:(NSString *)moduleName {
	if ([self.defaultModules indexOfObject:moduleName] != NSNotFound) {
		if ([moduleName isEqualToString:@"fs"]) {
			return [MKFSModule class];
		} else if ([moduleName isEqualToString:@"os"]) {
			return [MKOSModule class];
		}
	}
	return nil;
}

- (void)setupExceptionHandlerForContext:(JSContext *)context {
	ctx.exceptionHandler = ^(JSContext *context, JSValue *exception) {
		if ([exception isString] && [[exception toString] isEqualToString:@"MK1_EXIT"]) return;
		alertError([exception toString]);
	};
}

- (void)setupGlobalFunctionsForContext:(JSContext *)ctx {
	__weak JSContext *weakCtx = ctx;

	// global object
	ctx[@"global"] = ctx.globalObject;

	// require(moduleName): CommonJS module support
	ctx[@"require"] = ^(NSString *moduleName) {
    	if (![moduleName hasPrefix:@"./"] && ![moduleName hasPrefix:@"/"]) {
			if ([self.defaultModules indexOfObject:moduleName] != NSNotFound) return (JSValue *)[[[self classOfDefaultModule:moduleName] alloc] init];
			else return [JSValue valueWithUndefinedInContext:weakCtx];
		}
    	if (![moduleName hasSuffix:@".js"]) moduleName = [moduleName stringByAppendingString:@".js"];

		NSString *modulePath = moduleName;

		if ([modulePath hasPrefix:@"./"]) {
			NSString *scriptDirectory = [NSString stringWithFormat:@"/Library/MK1/Scripts/%@/", weakCtx[@"SCRIPT_NAME"]];
			modulePath = [scriptDirectory stringByAppendingPathComponent:[modulePath substringFromIndex:2]];
		}

		NSString *moduleCode = [NSString stringWithContentsOfFile:modulePath encoding:NSUTF8StringEncoding error:nil];
		NSString *injectedModuleCode = [NSString stringWithFormat:@"(function(){var module = {exports: {}};(function(module, exports) {%@;})(module, module.exports);return module.exports;})();", moduleCode];

		return [weakCtx evaluateScript:injectedModuleCode];
	};

	// alert(message, title): substitute for window.alert
	ctx[@"alert"] = ^(NSString *message, NSString *title) {
		if (!title) title = [weakCtx[@"SCRIPT_NAME"] toString];
		
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
		[alert addAction:okAction];

		UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;
		[vc presentViewController:alert animated:YES completion:nil];
	};

	// confirm(message, title, callback): calls callback function with the result of the selected choice
	ctx[@"confirm"] = ^(NSString *message, NSString *title, JSValue *callback) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
		handler:^(UIAlertAction * action) {
			[callback callWithArguments:@[@NO]];
		}];
		UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
		handler:^(UIAlertAction * action) {
			[callback callWithArguments:@[@YES]];
		}];

		[alert addAction:cancelAction];
		[alert addAction:okAction];
		alert.preferredAction = okAction;

		UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;
		[vc presentViewController:alert animated:YES completion:nil];
	};

	// prompt(message, title, callback): calls callback function with inputted text or false if cancelled
	ctx[@"prompt"] = ^(NSString *message, NSString *title, JSValue *callback) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
		[alert addTextFieldWithConfigurationHandler:nil];

		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
		handler:^(UIAlertAction *action) {
			NSString *text = [alert textFields][0].text;
			[callback callWithArguments:@[text]];
		}];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
			[callback callWithArguments:@[@NO]];
		}];

		[alert addAction:cancelAction];
		[alert addAction:okAction];
		alert.preferredAction = okAction;

		UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;
		[vc presentViewController:alert animated:YES completion:nil];
	};

	// console: https://developer.mozilla.org/en-US/docs/Web/API/Console
	ctx[@"console"] = [[Console alloc] init];

	// XMLHttpRequest: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
	ctx[@"XMLHttpRequest"] = [XMLHttpRequest class];

	// Promise: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
    ctx[@"Promise"] = (id) ^(JSValue *executor) { 
		return [[Promise alloc] initWithExecutor:executor];
	};

	// fetch(url, options): https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API
	// Supports method, body, and headers for options. TODO: implement more
	ctx[@"fetch"] = ^(NSString *link, NSDictionary * _Nullable options) {
		Promise *promise = [[Promise alloc] init];

		NSURL *url = [NSURL URLWithString:link];
		if (url) {
			NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
			req.HTTPMethod = @"GET";
			if (options) {
				if (options[@"method"]) req.HTTPMethod = options[@"method"];
				if (options[@"body"]) req.HTTPBody = [options[@"body"] dataUsingEncoding:NSUTF8StringEncoding];
				if (options[@"headers"]) {
					NSDictionary *headers = options[@"headers"];
					for (NSString *header in headers.allKeys) {
						[req setValue:headers[header] forHTTPHeaderField:header];
					}
				}
			}

			[[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
				dispatch_async(dispatch_get_main_queue(), ^{
					if (error) {
						[promise fail:error.localizedDescription];
					} else if (data) {
						Response *res = [[Response alloc] initWithData:data];
						[promise resolve:[JSValue valueWithObject:res inContext:weakCtx]];
					} else {
						[promise fail:[link stringByAppendingString:@" is empty"]];
					}
				});
			}] resume];
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[promise fail:[link stringByAppendingString:@" is not url"]];
			});
		}

		return promise;
	};

	// setTimeout(function, delay): https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/setTimeout
	ctx[@"setTimeout"] = ^(JSValue *function, double delay) {
		if (!delay) delay = 0;
		NSString *timeoutID = [[NSUUID UUID] UUIDString];
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:delay/1000 repeats:NO block:^(NSTimer *timer) {
			[function callWithArguments:@[]];
			self.timeouts[timeoutID] = nil;
		}];
		self.timeouts[timeoutID] = timer;
		return timeoutID;
	};

	// clearTimeout(timeoutID)
	ctx[@"clearTimeout"] = ^(NSString *timeoutID) {
		if (self.timeouts[timeoutID]) {
			[self.timeouts[timeoutID] invalidate];
			self.timeouts[timeoutID] = nil;
		}
	};

	// setInterval(function, delay)
	ctx[@"setInterval"] = ^(JSValue *function, double delay) {
		if (!delay) delay = 0;
		NSString *intervalID = [[NSUUID UUID] UUIDString];
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:delay/1000 repeats:YES block:^(NSTimer *timer) {
			[function callWithArguments:@[]];
		}];
		self.intervals[intervalID] = timer;
		return intervalID;
	};

	// clearInterval(intervalID)
	ctx[@"clearInterval"] = ^(NSString *intervalID) {
		if (self.intervals[intervalID]) {
			[self.intervals[intervalID] invalidate];
			self.intervals[intervalID] = NULL;
		}
	};

	// Legacy functions
	setupContext(ctx);
}

@end
