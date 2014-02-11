//
//  StatUtils.h
//  SSSTracker
//
//  Created by Denis Dvoryanchenko on 4/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface STATRUtils : NSObject

+ (NSString *)timeIntervalToDaysAndTimeString:(NSTimeInterval)timeInterval;
+ (NSString *)dateToString:(NSDate *)date;
+ (NSDate *)stringToDate:(NSString *)string;
+ (BOOL)createDirectoryIfNeededAtPath:(NSString *)path;

+ (NSArray *)filesInDirectoryAtPath:(NSString *)directoryPath mask:(NSString *)mask;
+ (NSString *)deviceID;
+ (NSInteger)currentProcessID;
+ (NSString *)createTimedKey;
+ (int)getPhysicalMemorySize;
//+ (int)getCPUFrequency;
+ (NSString *)appDocumentsDirectory;
+ (NSString *)deviceModel;
+ (unsigned int) countCores;

@end

