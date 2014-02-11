//
// Created by Yuriy Pavlyshak on 22.08.13.
//

#import "STATRUtils.h"
#include "STATRSystemInformation.h"

@implementation STATRSystemInformation

+ (STATRSystemInformation *)systemInformation
{
    STATRSystemInformation *systemInfo = [[STATRSystemInformation alloc] init];
    UIDevice *thisDevice = [UIDevice currentDevice];

    systemInfo.uniqueIdentifier = [STATRUtils deviceID];

    systemInfo.systemName = thisDevice.systemName;                  //iPhone OS
    systemInfo.systemVersion = thisDevice.systemVersion;            //5.0.0
    systemInfo.device = thisDevice.model;                           //iPhone
    systemInfo.model = [STATRUtils deviceModel];       //iPhone4,1

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat scale = [[UIScreen mainScreen] scale];
    systemInfo.screenW = screenBounds.size.width * scale;
    systemInfo.screenH = screenBounds.size.height * scale;

    systemInfo.CPUCores = [STATRUtils countCores];
    //systemInfo.CPUFrequrency = [STATRUtils getCPUFrequency];
    systemInfo.MemorySize = [STATRUtils getPhysicalMemorySize];

    NSLocale *curLocale = [NSLocale currentLocale];

    systemInfo.languageUI = [curLocale objectForKey:NSLocaleLanguageCode];//"language-UI" - en
    systemInfo.formatsCountry = [curLocale objectForKey:NSLocaleCountryCode];//formats-country" - US

    return systemInfo;
}

@end