// fs.m

#import "fs.h"

@implementation MKFSModule

// Rename files/directories
- (void)rename:(NSString *)oldPath :(NSString *)newPath :(void (^)(NSError *))callback {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *error;
		[[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
		dispatch_async(dispatch_get_main_queue(), ^(void){
			callback(error);
		});
	});
}

- (void)renameSync:(NSString *)oldPath :(NSString *)newPath {
	[[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:nil];
}

// Create directory
- (void)mkdir:(NSString *)path :(void (^)(NSError *))callback {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *error;
		[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
		dispatch_async(dispatch_get_main_queue(), ^(void){
			callback(error);
		});
	});
}

- (void)mkdirSync:(NSString *)path {
	[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

// Write to file
- (void)writeFile:(NSString *)filename :(NSString *)data :(void (^)(NSError *))callback {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *error;
		[data writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:&error];
		dispatch_async(dispatch_get_main_queue(), ^(void){
			callback(error);
		});
	});
}

- (void)writeFileSync:(NSString *)filename :(NSString *)data {
	[data writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// Read file contents
- (void)readFile:(NSString *)filename :(void (^)(NSError *, NSString *))callback {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *error;
		NSString *data = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&error];
		dispatch_async(dispatch_get_main_queue(), ^(void){
			callback(error, data);
		});
	});
}

- (NSString *)readFileSync:(NSString *)filename {
	return [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
}

@end
