// Promise.h

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol PromiseExports <JSExport>

- (instancetype)then:(JSValue *)resolve;
- (instancetype)catch:(JSValue *)reject;

@end

@interface Promise : NSObject <PromiseExports>

@property (nonatomic, strong) JSValue *resolve;
@property (nonatomic, strong) JSValue *reject;
@property (nonatomic, strong) Promise *next;
@property (nonatomic, strong) NSTimer *timer;

- (void)fail:(NSString *)error;
- (void)success:(id)value;

@end
