// Console.m

#import "Console.h"
#import "Util.h"

@implementation Console

- (void)log:(NSString *)text {
	MK1Log(MK1LogInfo, text);
}

- (void)info:(NSString *)text {
	MK1Log(MK1LogInfo, text);
}

- (void)warn:(NSString *)text {
	MK1Log(MK1LogWarn, text);
}

- (void)error:(NSString *)text {
	MK1Log(MK1LogError, text);
}

- (void)debug:(NSString *)text {
	MK1Log(MK1LogDebug, text);
}

- (void)assert:(BOOL)assertation :(id)msg {
	if (!assertation) {
		MK1Log(MK1LogError, [NSString stringWithFormat:@"Assertation failed: %@", msg]);
	}
}

- (void)clear {
    [@"[INFO] [MK1] Log cleared." writeToFile:@"/tmp/MK1.log" atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

@end
