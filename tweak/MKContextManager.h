// MKContextManager.h

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface MKContextManager : NSObject

@property (nonatomic, strong) JSVirtualMachine *vm;
@property (nonatomic, strong) JSContext *currentContext;
@property (nonatomic, strong) NSArray *defaultModules;

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSTimer *> *timeouts;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSTimer *> *intervals;

+ (instancetype)sharedManager;
- (void)createNewContext;

@end
