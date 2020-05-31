// Util.m

#import "Util.h"
#import "Context.h"
#import <dlfcn.h>
#import <notify.h>
#import <objc/runtime.h>

// Create global JSContext
void initContextIfNeeded() {
	if (!ctx) {
		ctx = [[JSContext alloc] initWithVirtualMachine:[[JSVirtualMachine alloc] init]];
		setupLogger(YES);
		setupContext();
		setupHardActions();
	}
}

// Load MK1 hard actions
void setupHardActions() {
	ctx[@"ext"] = @{};
	NSArray *dylibs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/MK1/Extensions/HardActions/" error:nil];
	for (NSString *dylib in dylibs) {
		NSString *path = [@"/Library/MK1/Extensions/HardActions/" stringByAppendingString:dylib];
		id (*f)(NSArray *);
		void *token = dlopen([path UTF8String], RTLD_LAZY);
		*(void **) (&f) = dlsym(token, "MK1Action");
		NSString *name = [dylib componentsSeparatedByString:@"."][0];
		ctx[@"ext"][name] = ^{
			NSMutableArray *args = [[JSContext currentArguments] mutableCopy];
			if (args != nil) {
				for (int i = 0; i < [args count]; i++) {
					args[i] = [args[i] toObject];
				}
			}
			return f(args);
		};
	}
}

// Setup MK1 logger
void setupLogger(BOOL alertOnError) {
	if (alertOnError) {
		ctx.exceptionHandler = ^(JSContext *context, JSValue *exception) {
			if ([exception isString] && [[exception toString] isEqualToString:@"MK1_EXIT"]) return;
			alertError([exception toString]);
			NSLog(@"[MK1](JSException) %@", [exception toString]);
		};
	} else {
		ctx.exceptionHandler = ^(JSContext *context, JSValue *exception) {
			if ([exception isString] && [[exception toString] isEqualToString:@"MK1_EXIT"]) return;
			NSLog(@"[MK1](JSException) %@", [exception toString]);
		};
	}
}

// Run script with specified name
void runScriptWithName(NSString *name) {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *path = [NSString stringWithFormat:@"/Library/MK1/Scripts/%@.js", name];
		if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
			return alertError([NSString stringWithFormat:@"Script file at '%@' does not exist", path]);
		}
		NSString *script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]; 
		initContextIfNeeded();

		ctx[@"SCRIPT_NAME"] = name;
		[ctx evaluateScript:script];
	});
}

// Run all scripts for a trigger
void activateTrigger(NSString *trigger) {
	for (NSString *s in scripts[trigger]) {
		runScriptWithName(s);
	}
}

// Check if trigger has any scripts
BOOL triggerHasScripts(NSString *trigger) {
    if (scripts[trigger] && [scripts[trigger] count] > 0) {
        return YES;
    } else {
        return NO;
    }
}

// Show an error alert
void alertError(NSString *msg) {
	MK1Log(MK1LogError, msg);

	UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;

	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"MK1 Error" message:msg preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
	[alert addAction:okAction];

	[vc presentViewController:alert animated:YES completion:nil];
}

// toString with null check
NSString *toStringCheckNull(JSValue *val) {
	if (!val || [val isNull] || [val isUndefined]) {
		return @"";
	} else {
		return [val toString];
	}
}

// Send message to MK1 log
void MK1Log(enum MK1LogType type, NSString *str) {
	NSString *txt;
	NSString *name = ctx ? [ctx[@"SCRIPT_NAME"] toString] : @"MK1";
	if (type == MK1LogDebug) {
		txt = [NSString stringWithFormat:@"[DEBUG] [%@] %@", name, str];
		#ifdef DEBUG
		NSLog(@"%@", txt);
		#endif
	} else if (type == MK1LogInfo) {
		txt = [NSString stringWithFormat:@"[INFO] [%@] %@", name, str];
	} else if (type == MK1LogError) {
		txt = [NSString stringWithFormat:@"[ERROR] [%@] %@", name, str];
		#ifdef DEBUG
		NSLog(@"%@", txt);
		#endif
	} else if (type == MK1LogWarn) {
		txt = [NSString stringWithFormat:@"[WARN] [%@] %@", name, str];
	}

	NSError *readError;
	NSString *path = @"/tmp/MK1.log";
	NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&readError];
	if (readError) return NSLog(@"[MK1][ERROR] %@", [readError localizedDescription]);

	NSError *writeError;
	NSString *write;
	if (!contents || contents.length > 2000) {
		write = txt;
	} else {
		write = [NSString stringWithFormat:@"%@\n%@", contents, txt];
	}
	[write writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
	if (writeError) return NSLog(@"[MK1][ERROR] %@", [writeError localizedDescription]);

	notify_post("xyz.skitty.mk1app.updateconsole");
}
