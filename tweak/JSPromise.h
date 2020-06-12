// JSPromise.h

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol JSPromiseExports <JSExport>

- (instancetype)then:(JSValue *)resolve;
- (instancetype)catch:(JSValue *)reject;

@end

@interface JSPromise : NSObject <JSPromiseExports>

@property (nonatomic, strong) JSValue *resolve;
@property (nonatomic, strong) JSValue *reject;
@property (nonatomic, strong) JSPromise *next;
@property (nonatomic, strong) NSTimer *timer;

- (void)fail:(NSString *)error;
- (void)success:(id)value;

@end
