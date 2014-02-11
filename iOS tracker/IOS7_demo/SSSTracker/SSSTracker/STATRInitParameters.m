//
// Created by Yuriy Pavlyshak on 21.08.13.
//



#import "STATR.h"

@implementation STATRInitParameters

- (id)init
{
    if ([super init]) {
        _useSandbox = NO;
    }
    return self;
}

- (NSString *)productVersionString
{
    if (self.productVersion) {
        return [self.productVersion versionAsString];
    }
    
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

@end