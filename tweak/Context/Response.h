// Response.h

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "Promise.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ResponseExports <JSExport>

// @property (nonatomic, assign) BOOL ok;
// @property (nonatomic, strong) NSString *statusText;
// @property (nonatomic, strong) NSString *url;

- (Promise *)text;

@end

@interface Response : NSObject <ResponseExports>

// @property (nonatomic, assign) BOOL ok;
// @property (nonatomic, strong) NSString *statusText;
// @property (nonatomic, strong) NSString *url;

@property (nonatomic, strong) NSString *_text;

- (instancetype)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
