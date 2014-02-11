//
// Created by Yuriy Pavlyshak on 21.08.13.
//


#import "STATR.h"

@implementation STATRProductVersion


- (id)initWithMajor:(NSInteger)majorVersion minor:(NSInteger)minorVersion release:(NSInteger)release build:(NSInteger)build
{
    if (self = [super init])
    {
        _majorVersionNumber = majorVersion;
        _minorVersionNumber = minorVersion;
        _releaseNumber = release;
        _buildNumber = build;
    }

    return self;
}

- (NSString *)versionAsString
{
    return [NSString stringWithFormat:@"%d.%d.%d.%d", _majorVersionNumber, _minorVersionNumber, _releaseNumber, _buildNumber];
}

@end