// MKContextManager.m

#import "MKContextManager.h"
#import "Context.h"
#import "Util.h"

#import "Process.h"
#import "Console.h"
#import "fs.h"
#import "os.h"
#import "Promise.h"
#import "Response.h"
#import "XMLHttpRequest.h"

@implementation MKContextManager

- (instancetype)init {
	self = [super init];
	if (self) {
		self.vm = [[JSVirtualMachine alloc] init];
		self.coreModules = @[@"fs", @"os"];
		// TODO: implement below modules
		// NODE
		//  - path
		//  - console
		//  - child_process
		// MK1
		//  - bridge 
		//  - device
		//  - settings
		//      airplane mode, bluetooth, brightness, cellular, clipboard, flashlight, lpm, orientation lock, dark mode, volume, wifi
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

- (JSValue *)runCode:(NSString *)code {
	if (!self.currentContext) [self createNewContext];
	return [self.currentContext evaluateScript:code];
}

- (NSString *)wrapCode:(NSString *)code {
	NSString *dirname = [NSString stringWithFormat:@"/Library/MK1/Scripts/%@/", self.currentContext[@"SCRIPT_NAME"]];
	NSString *filename = [dirname stringByAppendingPathComponent:@"index.js"];
	NSString *wrapper = [NSString stringWithFormat:@"(function(exports, module, __filename, __dirname) {%@;})", code];
	return [NSString stringWithFormat:@"(function(){var module = {exports: {}, filename: '%@', id: '%@', path: '%@'};%@(module.exports, module, '%@', '%@');return module.exports;})();", filename, filename, dirname, wrapper, filename, dirname];
}

- (Class)classOfCoreModule:(NSString *)moduleName {
	if ([self.coreModules indexOfObject:moduleName] != NSNotFound) {
		if ([moduleName isEqualToString:@"fs"]) {
			return [MKFSModule class];
		} else if ([moduleName isEqualToString:@"os"]) {
			return [MKOSModule class];
		}
	}
	return nil;
}

- (void)setupExceptionHandlerForContext:(JSContext *)context {
	context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
		if ([exception isString] && [[exception toString] isEqualToString:@"MK1_EXIT"]) return;
		alertError([exception toString]);
	};
}

- (void)setupGlobalFunctionsForContext:(JSContext *)ctx {
	__weak JSContext *weakCtx = ctx;

	// global object
	ctx[@"global"] = ctx.globalObject;

	// console: https://developer.mozilla.org/en-US/docs/Web/API/Console
	ctx.globalObject[@"console"] = [[Console alloc] init];

	ctx.globalObject[@"process"] = [[Process alloc] init];

	// require(moduleName): CommonJS module support
	// TODO: support JSON files, move into local module variable
	ctx[@"require"] = ^(NSString *moduleName) {
		// Check cache first
		JSValue *cachedModule = weakCtx[@"require"][@"cache"][moduleName];
		if (cachedModule && ![cachedModule isUndefined] && ![cachedModule isNull]) {
			return cachedModule;
		}

		// Load core module
		if ([self.coreModules indexOfObject:moduleName] != NSNotFound) {
			JSValue *coreModule = [[[self classOfCoreModule:moduleName] alloc] init];
			weakCtx[@"require"][@"cache"][moduleName] = coreModule;
			return coreModule;
		}

		NSString *dirname = [NSString stringWithFormat:@"/Library/MK1/Scripts/%@/", weakCtx[@"SCRIPT_NAME"]];

		// TODO: stringByExpandingTildeInPath? should ~ be supported?
		NSString *modulePath = moduleName;

		NSFileManager *fileManager = [NSFileManager defaultManager];

		// External module
		if (![moduleName hasPrefix:@"./"] && ![moduleName hasPrefix:@"/"]) {
			if ([fileManager fileExistsAtPath:[[dirname stringByAppendingPathComponent:@"modules"] stringByAppendingPathComponent:moduleName]]) {
				modulePath = [[dirname stringByAppendingPathComponent:@"modules"] stringByAppendingPathComponent:moduleName];
			}
			else return [JSValue valueWithUndefinedInContext:weakCtx]; // TODO: throw "not found"
		} else {
			// Local file
			// TODO: check ../
			// TODO: check if file doesn't exist first, then try .js, .json
			// if (![moduleName hasSuffix:@".js"]) modulePath = [modulePath stringByAppendingString:@".js"];

			if ([modulePath hasPrefix:@"./"]) {
				NSString *scriptDirectory = [NSString stringWithFormat:@"/Library/MK1/Scripts/%@/", weakCtx[@"SCRIPT_NAME"]];
				modulePath = [scriptDirectory stringByAppendingPathComponent:[modulePath substringFromIndex:2]];
			}
		}

		BOOL isDir;
		BOOL fileExists = [fileManager fileExistsAtPath:modulePath isDirectory:&isDir];

		if (![modulePath hasSuffix:@".js"] && !(fileExists && !isDir)) {
			if ([fileManager fileExistsAtPath:[modulePath stringByAppendingPathComponent:@"index.js"]]) modulePath = [modulePath stringByAppendingPathComponent:@"index.js"];
			else if ([fileManager fileExistsAtPath:[modulePath stringByAppendingString:@".js"]]) modulePath = [modulePath stringByAppendingString:@".js"];
			else return [JSValue valueWithUndefinedInContext:weakCtx];
		}

		NSString *moduleCode = [NSString stringWithContentsOfFile:modulePath encoding:NSUTF8StringEncoding error:nil];
		NSString *injectedModuleCode = [self wrapCode:moduleCode];

		JSValue *ret = [weakCtx evaluateScript:injectedModuleCode];
		weakCtx[@"require"][@"cache"][moduleName] = ret;
		return ret;
	};

	ctx[@"require"][@"cache"] = @{};

	// alert(message, title): substitute for window.alert
	ctx.globalObject[@"alert"] = ^(NSString *message, JSValue *title) {
		NSString *alertTitle = toStringCheckNull(title);
		// if (!title || [title isNull] || [title isUndefined]) alertTitle = [NSString stringWithFormat:@"%@", weakCtx[@"SCRIPT_NAME"]];

		UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle message:message preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
		[alert addAction:okAction];

		UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;
		[vc presentViewController:alert animated:YES completion:nil];
	};

	// confirm(message, title, callback): calls callback function with the result of the selected choice
	ctx.globalObject[@"confirm"] = ^(NSString *message, NSString *title, JSValue *callback) {
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
	ctx.globalObject[@"prompt"] = ^(NSString *message, NSString *title, JSValue *callback) {
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

	// XMLHttpRequest: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
	ctx.globalObject[@"XMLHttpRequest"] = [XMLHttpRequest class];

	// Promise: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
	ctx.globalObject[@"Promise"] = (id) ^(JSValue *executor) { 
		return [[Promise alloc] initWithExecutor:executor];
	};

	// fetch(url, options): https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API
	// Supports method, body, and headers for options. TODO: implement more
	ctx.globalObject[@"fetch"] = ^(NSString *link, NSDictionary * _Nullable options) {
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
	ctx.globalObject[@"setTimeout"] = ^(JSValue *function, double delay) {
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
	ctx.globalObject[@"clearTimeout"] = ^(NSString *timeoutID) {
		if (self.timeouts[timeoutID]) {
			[self.timeouts[timeoutID] invalidate];
			self.timeouts[timeoutID] = nil;
		}
	};

	// setInterval(function, delay)
	ctx.globalObject[@"setInterval"] = ^(JSValue *function, double delay) {
		if (!delay) delay = 0;
		NSString *intervalID = [[NSUUID UUID] UUIDString];
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:delay/1000 repeats:YES block:^(NSTimer *timer) {
			[function callWithArguments:@[]];
		}];
		self.intervals[intervalID] = timer;
		return intervalID;
	};

	// clearInterval(intervalID)
	ctx.globalObject[@"clearInterval"] = ^(NSString *intervalID) {
		if (self.intervals[intervalID]) {
			[self.intervals[intervalID] invalidate];
			self.intervals[intervalID] = NULL;
		}
	};

	// Legacy functions
	setupContext(ctx);
}

@end
