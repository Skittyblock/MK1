// Process.m

#import "Process.h"
#import <mach-o/arch.h>

@implementation Process

- (instancetype)init {
	self = [super init];
	if (self) {
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
		NSString *arch = [NSString stringWithCString:archInfo->name encoding:NSUTF8StringEncoding];
		self.arch = arch.lowercaseString;

		self.argv = [[NSProcessInfo processInfo] arguments];
		self.env = [[NSProcessInfo processInfo] environment];
		self.pid = [NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]];
	}
	return self;
}

- (NSNumber *)getgid {
	return [NSNumber numberWithInt:getgid()];
}

- (NSNumber *)getuid {
	return [NSNumber numberWithInt:getuid()];
}

- (void)setgid:(NSNumber *)gid {
	setgid([gid intValue]);
}

- (void)setuid:(NSNumber *)uid {
	setuid([uid intValue]);
}

@end
