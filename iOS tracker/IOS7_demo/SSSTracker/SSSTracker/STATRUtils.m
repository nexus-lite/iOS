//
//  StatUtils.m
//  SSSTracker
//
//  Created by Denis Dvoryanchenko on 4/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "STATRUtils.h"
#import "KeychainItemWrapper.h"
#import <sys/sysctl.h>

@implementation STATRUtils

+ (NSString *)timeIntervalToDaysAndTimeString:(NSTimeInterval)timeInterval
{
    //    "13 11:55:58"
    NSInteger days = (NSInteger)timeInterval / (60 * 60 * 24);
    NSInteger hours = ((NSInteger)timeInterval - days * 60 * 60 * 24) / (60 * 60);
    NSInteger minutes = ((NSInteger)timeInterval - days * 60 * 60 * 24 - hours * 60 * 60) / 60;
    NSInteger seconds = (NSInteger)timeInterval - days * 60 * 60 * 24 - hours * 60 * 60 - minutes * 60;

    NSString *dtString;
    if (days > 0) {
        dtString = [NSString stringWithFormat:@"%d %.2d:%.2d:%.2d", days, hours, minutes, seconds];
    }
    else {
        dtString = [NSString stringWithFormat:@"%.2d:%.2d:%.2d", hours, minutes, seconds];
    }

    return dtString;
}

+ (NSDateFormatter *)dateStringFormatter
{
    //"2011-04-14T09:29:53"
    static NSDateFormatter *dateStringFormatter = nil;
    static dispatch_once_t dateToStringFormatterOnceToken;
    dispatch_once(&dateToStringFormatterOnceToken, ^{
        dateStringFormatter = [[NSDateFormatter alloc] init];
        //[dateStringFormatter setDateFormat:@"YYYY'-'MM'-'dd'T'HH':'mm':'ss"]; // WRONG !!! show 2014 Dec 30 xx instead of 2013 Dec 30 xx !!
        [dateStringFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
    });
    
    return dateStringFormatter;
}

+ (NSString *)dateToString:(NSDate *)date
{
    NSLog(@"!!!! date = %@", date);
    
    return [[self dateStringFormatter] stringFromDate:date];
}


+ (NSDate *)stringToDate:(NSString *)string
{
    return [[self dateStringFormatter] dateFromString:string];
}

+ (BOOL)createDirectoryIfNeededAtPath:(NSString *)path
{
    BOOL result;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    if (![fileManager fileExistsAtPath:path]) {
        result = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    else {
        result = YES;
    }

    return result;
}

+ (NSArray *)filesInDirectoryAtPath:(NSString *)directoryPath mask:(NSString *)mask
{
    NSArray *filesArray = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    @try {
        NSArray *documentsContents = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];

        filesArray = [documentsContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"SELF like[c] '%@'", mask]]];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }

    return filesArray;
}

+ (NSString *)generateDeviceID
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    NSString *uuidString = [NSString stringWithString:(__bridge NSString *)uuidStringRef];
    CFRelease(uuidStringRef);
    CFRelease(uuidRef);
    
    return uuidString;
}

+ (NSString *)deviceID
{
    static NSString *identifier = nil;
    if (!identifier) {
        KeychainItemWrapper *identifierItemWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"SSSInstalationIdentifier" accessGroup:nil];
        identifier = [identifierItemWrapper objectForKey:(__bridge id)kSecValueData];
        if ([identifier length] == 0) {
            identifier = [self generateDeviceID];
            [identifierItemWrapper setObject:identifier forKey:(__bridge id)kSecValueData];
        }
    }
    
    return identifier;
}

+ (NSInteger)currentProcessID
{
    pid_t pID = getpid();
    NSInteger result = pID;
    return result;
}

+ (NSDateFormatter *)timedKeyFormatter
{
    static NSDateFormatter *timedKeyFormatter = nil;
    static dispatch_once_t timedKeyFormatterOnceToken;
    dispatch_once(&timedKeyFormatterOnceToken, ^{
        timedKeyFormatter = [[NSDateFormatter alloc] init];
        //[timedKeyFormatter setDateFormat:@"YYYYMMdd'-'HHmmSS'-'"];
        [timedKeyFormatter setDateFormat:@"yyyyMMdd'-'HHmmSS'-'"];
    });
    return timedKeyFormatter;
}

+ (NSString *)createTimedKey
{
    NSString *stringDateNow = [[self timedKeyFormatter] stringFromDate:[NSDate date]];
    NSTimeInterval dt = [NSDate timeIntervalSinceReferenceDate];
    NSString *result = [stringDateNow stringByAppendingFormat:@"%d", (NSInteger) dt & 1000000];
    return result;
}

+ (NSString *)appDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (NSString *)deviceModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithUTF8String:machine];
    free(machine);
    return deviceModel;
}

+ (int)getPhysicalMemorySize
{
    size_t length;
    int mib[6];
    unsigned int result;
    
    mib[0] = CTL_HW;
    mib[1] = HW_PHYSMEM;
    length = sizeof(result);
    
    if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
        return -1;
    else
        return (int) (result / (1024 * 1024)); // in Mb
}

+ (unsigned int) countCores
{
    size_t len;
    unsigned int ncpu;
    
    len = sizeof(ncpu);
    sysctlbyname ("hw.ncpu",&ncpu,&len,NULL,0);
    
    return ncpu;
}

/*+ (int)getCPUFrequency
{
    unsigned long long result;
    size_t length = sizeof(result);
    if (sysctlbyname("hw.cpufrequency", &result, &length, NULL, 0))
        return -1;
    else
        return (int)(result / 1000000); //in MHz
}*/

@end




