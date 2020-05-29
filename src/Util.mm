// MK1 - Copyright (c) 2020 Castyte. All rights reserved.

#include <dlfcn.h>
#include <notify.h>
#include "Tweak.h"
#import <objc/runtime.h>

void runScriptWithName(NSString *name){
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *path = [NSString stringWithFormat:@"/Library/MK1/Scripts/%@.js", name];
		if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
			return alertError([NSString stringWithFormat:@"Script file at '%@' does not exist", path]);
		}
		NSString *script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]; 
		initContextIfNeeded();

		ctx[@"SCRIPT_NAME"] = name;
		[ctx evaluateScript:script];
	});
}


void initContextIfNeeded(){
	if(!ctx){
		ctx = [[JSContext alloc] initWithVirtualMachine: [[JSVirtualMachine alloc] init]];
		setupLogger(YES);
		setupContext();
		setupHardActions();
	}
}


void runAllForTrigger(NSString *trigger){
	for(NSString *s in scripts[trigger]){
		runScriptWithName(s);
	}
}

BOOL triggerHasScripts(NSString *trigger){
    if(scripts[trigger] && [scripts[trigger] count] > 0){
        return YES;
    } else {
        return NO;
    }
}

void setupHardActions(){
	ctx[@"ext"] = @{};
	NSArray *dylibs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/MK1/Extensions/HardActions/" error:nil];
	for(NSString *dylib in dylibs){
		NSString *path = [@"/Library/MK1/Extensions/HardActions/" stringByAppendingString:dylib];
		id (*f)(NSArray *);
		void *token = dlopen([path UTF8String], RTLD_LAZY);
		*(void **) (&f) = dlsym(token, "MK1Action");
		NSString *name = [dylib componentsSeparatedByString:@"."][0];
		ctx[@"ext"][name] = ^{
			NSMutableArray *args = [[JSContext currentArguments] mutableCopy];
			if(args != nil) {
				for(int i=0; i<[args count]; i++){
					args[i] = [args[i] toObject];
				}
			}

			return f(args);
		};
	}
}

void alertError(NSString *msg){
	MK1Log(MK1LogError, msg);
	UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"MK1 Error"
								message:msg preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
		handler:^(UIAlertAction * action) {}];

	[alert addAction:okAction];
	[vc presentViewController:alert animated:YES completion:nil];
}

void setupLogger(BOOL alertOnError){
	if(alertOnError){
		ctx.exceptionHandler = ^(JSContext *context, JSValue *exception){
			if([exception isString] && [[exception toString] isEqualToString:@"MK1_EXIT"]) return;
			alertError([exception toString]);
			NSLog(@"[MK1](JSException) %@", [exception toString]);
		};
	} else {
		ctx.exceptionHandler = ^(JSContext *context, JSValue *exception){
			if([exception isString] && [[exception toString] isEqualToString:@"MK1_EXIT"]) return;
			NSLog(@"[MK1](JSException) %@", [exception toString]);
		};
	}
}

NSString *toStringCheckNull(JSValue *val){
	if(!val || [val isNull] || [val isUndefined]){
		return @"";
	} else {
		return [val toString];
	}
}

void MK1Log(enum MK1LogType type, NSString *str){
	NSString *txt;
	NSString *name = ctx ? [ctx[@"SCRIPT_NAME"] toString] : @"MK1";
	if(type == MK1LogDebug){
		txt = [NSString stringWithFormat:@"[DEBUG] [%@] %@", name, str];
		#ifdef DEBUG
		NSLog(@"%@", txt);
		#endif
	} else if(type == MK1LogInfo){
		txt = [NSString stringWithFormat:@"[INFO] [%@] %@", name, str];
	} else if(type == MK1LogError){
		txt = [NSString stringWithFormat:@"[ERROR] [%@] %@", name, str];
		#ifdef DEBUG
		NSLog(@"%@", txt);
		#endif
	} else if(type == MK1LogWarn){
		txt = [NSString stringWithFormat:@"[WARN] [%@] %@", name, str];
	}

	NSError *rError;
	NSString *path = @"/tmp/MK1.log";
	NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&rError];
	if(rError) return NSLog(@"[MK1][ERROR] %@", [rError localizedDescription]);
	NSError *wError;
	NSString *write;
	if(!contents || contents.length > 2000) write = txt;
	else write = [NSString stringWithFormat:@"%@\n%@", contents, txt];
	[write writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&wError];
	if(wError) return NSLog(@"[MK1][ERROR] %@", [wError localizedDescription]);
	notify_post("com.castyte.mk1app.updateconsole");
}