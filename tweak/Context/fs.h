// fs.h

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol FSExports <JSExport>

- (void)rename:(NSString *)oldPath :(NSString *)newPath :(void (^)(NSError *))callback;
- (void)renameSync:(NSString *)oldPath :(NSString *)newPath;
- (void)mkdir:(NSString *)path :(void (^)(NSError *))callback;
- (void)mkdirSync:(NSString *)path;
- (void)writeFile:(NSString *)filename :(NSString *)data :(void (^)(NSError *))callback;
- (void)writeFileSync:(NSString *)filename :(NSString *)data;
- (void)readFile:(NSString *)filename :(void (^)(NSError *, NSString *))callback;
- (NSString *)readFileSync:(NSString *)filename;

@end

@interface MKFSModule : NSObject <FSExports>

@end
