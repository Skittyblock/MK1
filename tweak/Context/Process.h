// Process.h

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol ProcessExports <JSExport>

@property (nonatomic, strong) NSString *arch;
@property (nonatomic, strong) NSArray *argv;
@property (nonatomic, retain) NSDictionary *env;
@property (nonatomic, strong) NSNumber *pid;

- (NSNumber *)getgid;
- (NSNumber *)getuid;
- (void)setgid:(NSNumber *)gid;
- (void)setuid:(NSNumber *)uid;

@end

@interface Process : NSObject <ProcessExports>

@property (nonatomic, strong) NSString *arch;
@property (nonatomic, strong) NSArray *argv;
@property (nonatomic, strong) NSDictionary *env;
@property (nonatomic, strong) NSNumber *pid;

@end
