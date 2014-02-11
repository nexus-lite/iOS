//
//  StatEvent.m
//  SSSTracker
//
//  Created by Denis Dvoryanchenko on 4/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define _DEBUG

#import <libkern/OSAtomic.h>
#import "STATR.h"
#import "STATRConstants.h"
#import "STATRUtils.h"
#import "STATRSystemInformation.h"

int32_t StatEventNumber = 0;
static NSInteger const STATRParameterTypeNone = 0;

@implementation STATREvent

- (id)initWithName:(NSString *)name date:(NSDate *)eventDate
{
    if (self = [super init]) {
        _name = name;
        _eventDate = eventDate;
        _order = OSAtomicIncrement32(&StatEventNumber);
    }
    return self;
}

- (void)addWindowSizeParameters:(UIWindow *)window
{
    float width = [UIScreen mainScreen].scale * [UIScreen mainScreen].bounds.size.width;
    float height = [UIScreen mainScreen].scale * [UIScreen mainScreen].bounds.size.height;
    
    [self addNotTypedParameterWithName:StatParamWindowHeight value:[NSString stringWithFormat:@"%d", (NSInteger)height]];
    [self addNotTypedParameterWithName:StatParamWindowWidth value:[NSString stringWithFormat:@"%d", (NSInteger)width]];
}

- (NSString *)titleOfPreviousVCInNavigationStackForViewController:(UIViewController *)viewController
{
    NSArray *viewControllersInNavigationStack = viewController.navigationController.viewControllers;
    
    if ([viewControllersInNavigationStack count] < 2) {
        return nil;
    }
    NSInteger previousVCIndex = [viewControllersInNavigationStack count] - 2;
    UIViewController *previousVC = viewControllersInNavigationStack[previousVCIndex];
    
    return previousVC.title;
}

- (void)addCaptionParameterForViewController:(UIViewController *)viewController
{
    if ([viewController.title length]) {
        [self addNotTypedParameterWithName:StatParamWindowCaption value:viewController.title];
    }
}

- (void)addParentCaptionParameterForViewController:(UIViewController *)viewController
{
    if ([[self titleOfPreviousVCInNavigationStackForViewController:viewController] length]) {
        NSString *caption = [self titleOfPreviousVCInNavigationStackForViewController:viewController];
        [self addNotTypedParameterWithName:StatParamParentWindowCaption
                                     value:caption];
    }
    else if ([viewController.parentViewController.title length]) {
        [self addNotTypedParameterWithName:StatParamParentWindowCaption
                                     value:viewController.parentViewController.title];
    }
    else if ([viewController.presentingViewController.title length]) {
        [self addNotTypedParameterWithName:StatParamParentWindowCaption
                                     value:viewController.presentingViewController.title];
    }
}

- (char) getDeviceOrientation
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
#ifdef _DEBUG
            NSLog(@"orientation = PortraitUp");
#endif
            return 'P';
        case UIInterfaceOrientationPortraitUpsideDown:
#ifdef _DEBUG
            NSLog(@"orientation = PortraitUpsideDown");
#endif
            return 'P';
            
        case UIInterfaceOrientationLandscapeLeft:
#ifdef _DEBUG
            NSLog(@"orientation = LandScapeLeft");
#endif
            return 'L';
            
        case UIInterfaceOrientationLandscapeRight:
#ifdef _DEBUG
            NSLog(@"orientation = LandScapeRight");
#endif
            return 'L';
            
        default:
#ifdef _DEBUG
            NSLog(@"orientation = Unknown");
#endif
            return 0;
    }
}

- (CGPoint) convertPointsAccordingToOrientation:(CGPoint) point
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    switch (orientation) {
        
        // convert point only for two orientations (rorated on 180 degrees)
        case UIInterfaceOrientationPortraitUpsideDown:
            
            return CGPointMake([UIScreen mainScreen].bounds.size.width - point.x,
                               [UIScreen mainScreen].bounds.size.height - point.y);
            
        case UIInterfaceOrientationLandscapeRight:
            
            return CGPointMake([UIScreen mainScreen].bounds.size.width - point.x,
                               [UIScreen mainScreen].bounds.size.height - point.y);
        // for rest do nothing
        default:
            return point;
    }
}

- (id)initWithName:(NSString *)name
              date:(NSDate *)eventDate
    viewController:(UIViewController*)viewController;
{
    if (self = [self initWithName:name date:eventDate]) {
        
        [self addNotTypedParameterWithName:StatParamWindowCaption value:viewController.title];
        [self addParentCaptionParameterForViewController:viewController];
    }
    return self;
}

- (id)initWithName:(NSString *)name
              date:(NSDate *)eventDate
             event:(UIEvent *)event
    viewController:(UIViewController*) viewController
{
    if (self = [self initWithName:name date:eventDate]) {
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [self addWindowSizeParameters:window];
        
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint touchPosition = [touch locationInView:window];

        CGPoint tempPoint = [self convertPointsAccordingToOrientation:touchPosition];
        
        float x = [UIScreen mainScreen].scale * tempPoint.x;
        float y = [UIScreen mainScreen].scale * tempPoint.y;
        [self addNotTypedParameterWithName:StatParamTouchCoordinateX value:[NSString stringWithFormat:@"%d", (NSInteger)x]];
        [self addNotTypedParameterWithName:StatParamTouchCoordinateY value:[NSString stringWithFormat:@"%d", (NSInteger)y]];
        [self addCaptionParameterForViewController:viewController];
        [self addParentCaptionParameterForViewController:viewController];
        [self addNotTypedParameterWithName:StatParamScreenOrientation value:[NSString stringWithFormat:@"%c", [self getDeviceOrientation]]];
    }
    return self;
}

- (id)initWithName:(NSString *)name
              date:(NSDate *)eventDate
             point:(CGPoint)point
    viewController:(UIViewController*)viewController
{
    if (self = [self initWithName:name date:eventDate]) {
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [self addWindowSizeParameters:window];
        
        CGPoint tempPoint = point;
        //tempPoint = [self convertPointsAccordingToOrientation:tempPoint];
        
        float xPosInCGPoint = [UIScreen mainScreen].scale * tempPoint.x;
        float yPosInCGPoint= [UIScreen mainScreen].scale * tempPoint.y;
        [self addNotTypedParameterWithName:StatParamTouchCoordinateX value:[NSString stringWithFormat:@"%d", (NSInteger) xPosInCGPoint]];
        [self addNotTypedParameterWithName:StatParamTouchCoordinateY value:[NSString stringWithFormat:@"%d", (NSInteger) yPosInCGPoint]];
        [self addCaptionParameterForViewController:viewController];
        [self addParentCaptionParameterForViewController:viewController];
        [self addNotTypedParameterWithName:StatParamScreenOrientation value:[NSString stringWithFormat:@"%c", [self getDeviceOrientation]]]; 
    }
    return self;
}

- (NSMutableArray *)parameters
{
    if (!_parameters) {
        _parameters = [[NSMutableArray alloc] init];
    }
    return _parameters;
}

- (void)removeAllParameters
{
    [self.parameters removeAllObjects];
}

- (void)addNotTypedParameterWithName:(NSString *)name value:(NSString *)value
{
    STATREventParameter *param = [[STATREventParameter alloc] initWithName:name value:value type:STATRParameterTypeNone];
    [self.parameters addObject:param];
}

- (void)addTextParameterWithName:(NSString *)name value:(NSString *)value
{
    STATREventParameter *param = [[STATREventParameter alloc] initWithName:name value:value type:STATRParameterTypeText];
    [self.parameters addObject:param];
}

- (void)addIntegerParameterWithName:(NSString *)name value:(NSInteger)value
{
    NSString *strValue = [NSString stringWithFormat:@"%d", value];
    STATREventParameter *param = [[STATREventParameter alloc] initWithName:name value:strValue type:STATRParameterTypeNumeric];
    [self.parameters addObject:param];
}

- (void)addLogParameterWithName:(NSString *)name value:(NSString *)value
{
    STATREventParameter *param = [[STATREventParameter alloc] initWithName:name value:value type:STATRParameterTypeLog];
    [self.parameters addObject:param];
}

- (void)addErrorParameterWithName:(NSString *)name value:(NSString *)value
{
    STATREventParameter *param = [[STATREventParameter alloc] initWithName:name value:value type:STATRParameterTypeError];
    [self.parameters addObject:param];
}

- (NSUInteger)parameterCount
{
    return [self.parameters count];
}

- (STATREventParameter *)parameterAtIndex:(NSUInteger)index
{
    return [self.parameters objectAtIndex:index];
}

@end


@implementation STATREventAppStart

- (id)initWithAppStartDate:(NSDate *)appStartDate parameters:(STATRInitParameters *)initParameters
{
    self = [super initWithName:StatEventAppStart date:appStartDate];
    if (self) {
        [self addNotTypedParameterWithName:StatParamAppVersion value:initParameters.productVersionString];
        [self addNotTypedParameterWithName:StatParamAppPackage value:initParameters.productPackage];
        [self addSystemParameters];
        
        [self addNotTypedParameterWithName:StatParamDeviceName value:initParameters.deviceName];
        [self addNotTypedParameterWithName:StatParamClientName value:initParameters.clientName];
    }

    return self;
}

- (void)addSystemParameters
{
    STATRSystemInformation *systemInfo = [STATRSystemInformation systemInformation];

    [self addNotTypedParameterWithName:StatParamPlatform value:StatParamValueIOS];
    [self addNotTypedParameterWithName:StatParamOSName value:systemInfo.systemName];
    [self addNotTypedParameterWithName:StatParamOSVersion value:systemInfo.systemVersion];
    [self addNotTypedParameterWithName:StatParamDevice value:systemInfo.device];
    [self addNotTypedParameterWithName:StatParamModel value:systemInfo.model];
    [self addNotTypedParameterWithName:StatParamProcessorCount value:[NSString stringWithFormat:@"%d", (NSInteger)systemInfo.CPUCores]];
    //[self addIntegerParameterWithName:StatParamProcessorMHz value:systemInfo.CPUFrequrency];
    [self addNotTypedParameterWithName:StatParamMemoryPhysicalMb value:[NSString stringWithFormat:@"%d", (NSInteger)systemInfo.MemorySize]];
    
    [self addNotTypedParameterWithName:[NSString stringWithFormat:StatParamMonitorWidth, 0]
                                 value:[NSString stringWithFormat:@"%d", (NSInteger)systemInfo.screenW]];
    [self addNotTypedParameterWithName:[NSString stringWithFormat:StatParamMonitorHeight, 0]
                                 value:[NSString stringWithFormat:@"%d", (NSInteger)systemInfo.screenH ]];
    
    [self addNotTypedParameterWithName:StatParamFormatsCountry value:systemInfo.formatsCountry];
    [self addNotTypedParameterWithName:StatParamLanguageUI value:systemInfo.languageUI];
}

@end


@implementation STATREventAppFinish

- (id)initWithAppStartDate:(NSDate *)appStartDate finishDate:(NSDate *)appFinishDate
{
    self = [super initWithName:StatEventAppFinish date:appFinishDate];
    if (self) {
        self.value = [STATRUtils timeIntervalToDaysAndTimeString:[appFinishDate timeIntervalSinceDate:appStartDate]];
    }
    return self;
}

@end


@implementation STATREventAppFailure

- (id)initWithAppStartDate:(NSDate *)appStartDate failureDate:(NSDate *)appFailureDate
{
    self = [super initWithName:StatEventAppFailure date:appFailureDate];
    if (self) {
        self.order = INT_MAX;
    }
    return self;
}

@end


@implementation STATREventWindowActivation

- (id)initWithViewController:(UIViewController *)viewController
{
    if (self = [super initWithName:StatEventWindowActivation date:[NSDate date]]) {
        
        [self addCaptionParameterForViewController:viewController];
        [self addParentCaptionParameterForViewController:viewController];
    }
    return self;
}

- (id)initWithWindowName:(NSString *)windowName parentWindowName:(NSString *) parentWindowName
{
    if (self = [super initWithName:StatEventWindowActivation date:[NSDate date]]) {
        [self addNotTypedParameterWithName:StatParamWindowCaption value:windowName];
        
        if(parentWindowName && ![parentWindowName isEqualToString:@""]){
        
            [self addNotTypedParameterWithName:StatParamParentWindowCaption value:parentWindowName];
        }
    }
    return self;
}

@end


@implementation STATREventWindowDeactivation

- (id)initWithWindowName:(NSString *)windowName parentWindowName:(NSString *) parentWindowName
{
    if (self = [super initWithName:StatEventWindowDeactivation date:[NSDate date]]) {
        [self addNotTypedParameterWithName:StatParamWindowCaption value:windowName];
        
        if(parentWindowName && ![parentWindowName isEqualToString:@""]){
            
            [self addNotTypedParameterWithName:StatParamParentWindowCaption value:parentWindowName];
        }
    }
    return self;
}

@end

@implementation STATREventFPS

- (id)initWithMinFPS:(NSInteger) minFPS
              maxFPS:(NSInteger) maxFPS
          windowName:(NSString *)windowName
    parentWindowName:(NSString *)parentWindowName
{
    if (self = [super initWithName:StatEventFPS date:[NSDate date]]) {
        
        [self addNotTypedParameterWithName:StatParamFPSMin value:[NSString stringWithFormat:@"%d", (NSInteger)minFPS]];
        [self addNotTypedParameterWithName:StatParamFPSMax value:[NSString stringWithFormat:@"%d", (NSInteger)maxFPS]];
        [self addNotTypedParameterWithName:StatParamWindowCaption value:windowName];
        [self addNotTypedParameterWithName:StatParamParentWindowCaption value:parentWindowName];
    }
    return self;
}

@end

@implementation STATREventUserProfile

- (id)initWithBirthday:(NSDate*)birthday
                gender:(NSString*)gender
{
    if (self = [super initWithName:StatEventUserProfile date:[NSDate date]]) {

        NSDateFormatter *dateForm = [[NSDateFormatter alloc] init];
        [dateForm setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
        NSString *dateStr =  [dateForm stringFromDate:birthday];
        
        [self addNotTypedParameterWithName:StatParamUserBirthday value:[NSString stringWithFormat:@"%@", dateStr]];
        [self addNotTypedParameterWithName:StatParamUserGender value:gender];
    }
    return self;
}


- (id)initWithAge:(NSInteger)age
           gender:(NSString*)gender
{
    if (self = [super initWithName:StatEventUserProfile date:[NSDate date]]) {
        
        [self addNotTypedParameterWithName:StatParamUserBirthday value:[NSString stringWithFormat:@"%d", (NSInteger)age]];
        [self addNotTypedParameterWithName:StatParamUserGender value:gender];
    }
    return self;
}

@end

@implementation STATREventInAppPurchase

- (id) initWithPurchaseName:(NSString*)purchaseName
                       type:(NSInteger) purchaseType
                       cost:(float) purchaseCost
                      state:(NSInteger) purchaseState
                     userID:(NSString*) userID
                       date:(NSDate*) date
                     market:(NSString*)purchaseMarket
{
    if (self = [super initWithName:StatEventInAppPurchase date:date]) {
        
        NSString *purchaseTypeStr;
        NSString *purchaseStateStr;
        
        switch (purchaseState) {
            case 0: purchaseStateStr = @"Purchased"; break;
            case 1: purchaseStateStr = @"Restored"; break;
            case 2: purchaseStateStr = @"Failed"; break;
        }
        
        switch (purchaseType) {
            case 0: purchaseTypeStr = @"Consumables"; break;
            case 1: purchaseTypeStr = @"NonConsumables"; break;
            case 2: purchaseTypeStr = @"Subscription"; break;
        }
        
        [self addNotTypedParameterWithName:StatParamInAppPurchaseName
                                     value:purchaseName];
        [self addNotTypedParameterWithName:StatParamInAppPurchaseType
                                     value:purchaseTypeStr];
        [self addNotTypedParameterWithName:StatParamInAppPurchaseCost
                                     value:[NSString stringWithFormat:@"%f", purchaseCost]];
        [self addNotTypedParameterWithName:StatParamInAppPurchaseState
                                     value:purchaseStateStr];
        [self addNotTypedParameterWithName:StatParamInAppPurchaseUserID
                                     value:userID];
        [self addNotTypedParameterWithName:StatParamInAppPurchaseMarket
                                     value:purchaseMarket];
    }
    return self;
}

@end