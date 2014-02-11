//
// Created by Yuriy Pavlyshak on 22.08.13.
//

@interface STATRSystemInformation : NSObject

@property (nonatomic, strong) NSString *uniqueIdentifier;
@property (nonatomic, strong) NSString *systemName;
@property (nonatomic, strong) NSString *systemVersion;
@property (nonatomic, strong) NSString *device;
@property (nonatomic, strong) NSString *model;
@property (nonatomic, assign) NSInteger screenW;
@property (nonatomic, assign) NSInteger screenH;
@property (nonatomic, assign) NSInteger CPUCores;
@property (nonatomic, assign) NSInteger CPUFrequrency;
@property (nonatomic, assign) NSInteger MemorySize;
@property (nonatomic, strong) NSString *formatsCountry;
@property (nonatomic, strong) NSString *languageUI;

+ (STATRSystemInformation *)systemInformation;

@end

