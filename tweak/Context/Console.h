// Console.h

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol ConsoleExports <JSExport>

- (void)log:(NSString *)text;
- (void)info:(NSString *)text;
- (void)warn:(NSString *)text;
- (void)error:(NSString *)text;
- (void)debug:(NSString *)text;
- (void)assert:(BOOL)assertation :(id)msg;
- (void)clear;

@end

@interface Console : NSObject <ConsoleExports>

@end
