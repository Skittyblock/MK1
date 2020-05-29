// MK1 Application - Copyright (c) 2020 Castyte. All rights reserved.

#import "MKScript.h"

@implementation MKScript

-(id)initWithName:(NSString *)name trigger:(NSString *)trigger{
    self = [super init];
    self.name = name;
    self.trigger = trigger;
    self.path = [NSString stringWithFormat:@"/Library/MK1/Scripts/%@.js", self.name];
    return self;
}

-(NSString *)codeWithError:(NSError **)error{
    return [NSString stringWithContentsOfFile:self.path encoding:NSUTF8StringEncoding error:error];
}

@end