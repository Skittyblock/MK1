// MKScript.h

@interface MKScript : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *trigger;
@property (strong, nonatomic) NSString *path;

- (id)initWithName:(NSString *)name trigger:(NSString *)trigger;
- (NSString *)codeWithError:(NSError **)error;

@end
