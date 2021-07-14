// os.h

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol OSExports <JSExport>

- (NSString *)arch; // arm64 or arm64e
// - (NSArray *)cpus; // [ { model: 'apple', speed: 1, times: { user: 1, nice: 0, sys: 0, idle: 0, irq: 0 } } ]
- (NSString *)devNull; // /dev/null
- (NSString *)endianness;
- (NSNumber *)freemem;
- (NSString *)homeDir;
- (NSString *)hostname;
// - (NSArray *)loadavg; // [0, 0, 0]
- (NSString *)platform;
- (NSString *)release:(NSString *)ignore; // objc won't let me make a method just named release
- (NSString *)tmpdir; // /tmp
- (NSNumber *)totalmem;
- (NSString *)type;
- (NSNumber *)uptime;
- (NSDictionary *)userInfo:(NSDictionary *)options;
- (NSString *)version;

@end

@interface MKOSModule : NSObject <OSExports>
@end
