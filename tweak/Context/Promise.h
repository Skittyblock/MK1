// Promise.h

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PromiseExports <JSExport>

- (instancetype)then:(JSValue *)resolve;
- (instancetype)catch:(JSValue *)reject;

@end

@interface Promise : NSObject <PromiseExports>

@property (nonatomic, strong) JSValue *executor;

@property (nonatomic, strong) NSMutableArray *resultObservers;
@property (nonatomic, strong) NSMutableArray *errorObservers;

@property (nonatomic, assign) BOOL resolved;
@property (nonatomic, strong) JSValue *result;
@property (nonatomic, strong) JSValue *error;

@property (nonatomic, strong) Promise *returnPromise;

- (instancetype)initWithExecutor:(JSValue *)executor;
- (void)resolve:(JSValue *)value;
- (void)reject:(JSValue *)value;
- (void)fail:(NSString *)errorString;

@end

NS_ASSUME_NONNULL_END
