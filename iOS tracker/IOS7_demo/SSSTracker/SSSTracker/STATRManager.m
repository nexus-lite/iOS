//
//  StatMng.m
//  SSSTracker
//
//  Created by Denis Dvoryanchenko on 4/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define _DEBUG

#import "STATR.h"
#import "STATRUtils.h"
#import "STATRHttpRequest.h"
#import "STATRXmlWriter.h"
#import "Reachability.h"

#define kTrackerVersion         @"6.0.0.6"
#define kSandboxSettingsUrl     @"http://sandbox.software-statistics-service.com/get_settings.php"
#define kSandboxServerUrl       @"http://sandbox.software-statistics-service.com/index.php?version=2&key="

#define kSettingsUrl            @"http://data1.software-statistics-service.com/get_settings.php"
#define kServerUrl              @"http://data1.software-statistics-service.com/index.php?version=2&key="


@interface STATRManager ()

@property (strong) NSMutableArray *statisticsEventList;
@property BOOL isCollectingDataEnabled;
@property BOOL isSendingDataEnabled;
@property NSInteger waitTimeout;
@property (strong) NSDate *lastGetServerSettingsDate;

@property BOOL isFinishing;
@property BOOL isFinishingLastSend;

@property (strong) NSMutableString *currentStatisticsEventsXml;
@property (strong) NSString *currentStatisticsEventsStorageFileName;
@property (strong) NSFileHandle *currentStatisticsEventsStorageFileHandle;

@property (nonatomic, strong) STATRXmlWriter *xmlWriter;
@property (nonatomic, strong) STATRHttpRequest *httpRequest;

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) STATRInitParameters *initialParameters;
@property (nonatomic, strong) NSThread *workingThread;
@property BOOL isThreadTerminated;
@property (nonatomic, strong) NSString *dataDirectoryPath;

@property (nonatomic, strong) NSString *installationKey;
@property (nonatomic, strong) NSString *executionKey;

@property (nonatomic) NSInteger storageFileNumber;

@property (nonatomic, strong) NSDate *lastSendDate;
@property (nonatomic) BOOL wasErrorDuringLastSend;

@property (strong) NSTimer *timer;

@property (nonatomic, strong) NSString *failureFileName;
@property (nonatomic, strong) NSDate *failureUpdateDate;

@property (nonatomic, strong) Reachability *reachability;
@property NetworkStatus currentNetworkStatus;
@property (nonatomic, readonly) BOOL isDataSendingAllowedInCurrentNetwork;
@property BOOL shouldSendDataOnce;

@property (nonatomic, strong) NSString *currentWindowName, *currentParentWindowName;

@property NSInteger minFPS;
@property NSInteger maxFPS;
@property (nonatomic, strong) NSString *FPSwindowName, *FPSparentWindowName;

@end


@implementation STATRManager


+ (STATRManager *)sharedManager
{
    static STATRManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}


- (id)init
{
    if (self = [super init]) {
        self.statisticsEventList = [[NSMutableArray alloc] init];
        self.currentStatisticsEventsXml = [[NSMutableString alloc] init];
    }
    return self;
}


- (void)setInitialManagerParameters:(STATRInitParameters *)initialParameters
{
    self.storageFileNumber = 0;
    self.initialParameters = initialParameters;
    self.initialParameters.trackerVersion = kTrackerVersion;
    self.isEnabledDataSendingOverCellularNetwork = YES;
    self.isEnabledAutomaticDataSending = SettingDefIsEnabledAutomaticDataSending;
    [self registerDefaultSettings];

    if (self.initialParameters.useSandbox) {
        self.initialParameters.settingsServerUrl = kSandboxSettingsUrl;
        self.initialParameters.serverUrl = [NSString stringWithFormat:@"%@%@", kSandboxServerUrl, self.initialParameters.productKey];
    }
    else {
        self.initialParameters.settingsServerUrl = kSettingsUrl;
        self.initialParameters.serverUrl = [NSString stringWithFormat:@"%@%@", kServerUrl, self.initialParameters.productKey];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appStart) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appFinish) name:UIApplicationDidEnterBackgroundNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:kReachabilityChangedNotification object:nil];
    self.reachability = [Reachability reachabilityForInternetConnection];
    [self.reachability startNotifier];
    [self updateCurrentNetworkStatus];
    
    self.currentWindowName = @"";
    self.currentParentWindowName = @"";
    self.FPSwindowName = @"";
    self.FPSparentWindowName = @"";
}

- (void)setIsEnabledAutomaticDataSending:(BOOL)isEnabledAutomaticDataSending
{
    if (_isEnabledAutomaticDataSending != isEnabledAutomaticDataSending) {
        if (isEnabledAutomaticDataSending == NO) {

            STATREvent *sendingDataOffEvent = [[STATREvent alloc] initWithName:StatEventSendingDataOff date:[NSDate date]];
            [self addCustomEvent:sendingDataOffEvent];
            self.shouldSendDataOnce = YES;
            if (self.workingThread) {
                [self performSelector:@selector(threadExecute) onThread:self.workingThread withObject:nil waitUntilDone:NO];
            }
        }
        _isEnabledAutomaticDataSending = isEnabledAutomaticDataSending;

        [[NSUserDefaults standardUserDefaults] setBool:self.isEnabledAutomaticDataSending forKey:SettingStorageKeyIsEnabledAutomaticDataSending];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateCurrentNetworkStatus
{
    self.currentNetworkStatus = [self.reachability currentReachabilityStatus];
}

- (void)reachabilityChanged
{
    [self updateCurrentNetworkStatus];
}

- (BOOL)isDataSendingAllowedInCurrentNetwork
{
    return self.isEnabledDataSendingOverCellularNetwork || self.currentNetworkStatus == ReachableViaWiFi;
}

- (void)sendDataManually
{
    self.shouldSendDataOnce = YES;
    [self performSelector:@selector(threadExecute) onThread:self.workingThread withObject:nil waitUntilDone:NO];
}

- (void)appStart
{
    if (self.startDate) {
        return;
    }
    
    self.lastSendDate = nil;
    self.wasErrorDuringLastSend = NO;
    self.xmlWriter = [[STATRXmlWriter alloc] init];
    self.httpRequest = [[STATRHttpRequest alloc] init];
    self.startDate = [NSDate date];

    [self createStatisticsDataDirectoryIfNeeded];
    [self loadSettings];
    [self loadInstallationKey];
    [self loadExecutionKey];
    [self resetCurrentStorage];

    [self processFailureFiles];
    [self loadFailureFileName];
    [self updateFailureFile];

    [self createThread];

    STATREventAppStart *appStartEvent = [[STATREventAppStart alloc] initWithAppStartDate:self.startDate parameters:self.initialParameters];

    [self postStatEvent:appStartEvent];
}

- (void)createThread
{
    self.isThreadTerminated = NO;

    self.workingThread = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(threadMainRoutine)
                                                   object:nil];
    [self.workingThread start];  // Actually create the thread

}

- (void)timerFireMethod:(NSTimer *)timer
{

#ifdef _DEBUG
    NSLog(@"%@",@"timerFireMethod start");
#endif

    [self threadExecute];
}

- (void)threadMainRoutine
{
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [self processStart];
    [runLoop run];
}

- (void)processStart
{
    [self processServerSettings];       // get settings from server once when program start

    [NSTimer scheduledTimerWithTimeInterval:SendAfterStartIntervalSec target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];// for first send after start application
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];

#ifdef _DEBUG
    NSLog(@"ProcessStart",nil);
#endif
}

- (void)processFinish
{
    [self.timer invalidate];// stop timer
    self.timer = nil;

    [self processStatEvents:NO];// save events if collecting enable

    if (!self.isFinishingLastSend)// if sending
        [self sendCurrentStatEvents:(YES)];// send events if sending enable

    [self processStatEvents:YES];// save events to disk

#ifdef _DEBUG
    NSLog(@"ProcessFinish",nil);
#endif
}


- (void)threadExecute
{
    self.isFinishingLastSend = NO;

    BOOL hasEvents = NO;

    while (!self.isThreadTerminated) {

#ifdef _DEBUG
        NSLog(@"ThreadExecute while",nil);
#endif
        [self processStatEvents:NO];// save events if collecting enable

        if (self.isThreadTerminated)
            break;

        [self updateFailureFile];

        if (self.isThreadTerminated)
            break;

        hasEvents = [self sendCurrentStatEvents:(self.isFinishing && !self.isFinishingLastSend)];// send events if sending enable

        if (self.isThreadTerminated)
            break;

#ifdef _DEBUG
        NSLog(@"hasEvents=%d", hasEvents);
#endif

        if (hasEvents == NO)
            return;

    }

    [self processStatEvents:YES];
}


- (void)appFinish
{
    self.isFinishing = YES;
    STATREventAppFinish *appfinish = [[STATREventAppFinish alloc] initWithAppStartDate:self.startDate finishDate:[NSDate date]];

    [self postStatEvent:appfinish];

    [self finishWorkingThread];
    [self removeFailureFile];
    self.startDate = nil;
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

- (NSString*)getCaptionParameterForViewController:(UIViewController *)viewController
{
    if ([viewController.title length]) {
        return viewController.title;
    }
    return nil;
}

- (NSString*)getParentCaptionParameterForViewController:(UIViewController *)viewController
{
    NSString *caption = [self titleOfPreviousVCInNavigationStackForViewController:viewController];
    
    if ([caption length]) {
       return caption;

    }
    else if ([viewController.parentViewController.title length]) {
        return viewController.parentViewController.title;
    }
    else if ([viewController.presentingViewController.title length]) {
        return viewController.presentingViewController.title;
    }
    return nil;
}

- (void)trackViewAppearOfViewController:(UIViewController *)viewController
{
    STATREventWindowActivation *event = [[STATREventWindowActivation alloc] initWithViewController:viewController];
    [self postStatEvent:event];
    
    // save current window and parent title
    self.currentWindowName = [self getCaptionParameterForViewController:viewController];
    self.currentParentWindowName = [self getCaptionParameterForViewController:viewController];
}

- (void)trackViewDisappearOfViewController:(UIViewController *)viewController
{
    if(![self.currentWindowName isEqualToString:@""]){
        
        STATREventWindowDeactivation *event = [[STATREventWindowDeactivation alloc]
                                             initWithWindowName:self.currentWindowName
                                               parentWindowName:self.currentParentWindowName];
        [self postStatEvent:event];
    }
}

- (void)finishWorkingThread
{
    self.isThreadTerminated = YES;
    if (self.workingThread) if ([self.workingThread isExecuting]) {
        [self performSelector:@selector(stopTimerInThreadAndExitThread) onThread:self.workingThread withObject:nil waitUntilDone:NO];
    }
}

- (void)stopTimerInThreadAndExitThread
{
    if (self.timer) {
#ifdef _DEBUG
        NSLog(@"stopTimerInThreadAndExitThread");
#endif
        [self processFinish];
    }

#ifdef _DEBUG
    NSLog(@"NSThread exit");
#endif
    [NSThread exit];
}

- (void)createStatisticsDataDirectoryIfNeeded
{
    NSString *appDataFolder = [STATRUtils appDocumentsDirectory];

    NSString *statFolder = nil;

    if ([appDataFolder length] == 0)
        return;

    statFolder = [appDataFolder stringByAppendingPathComponent:self.initialParameters.clientName];
    //statFolder = [appDataFolder stringByAppendingPathComponent:self.initialParameters.productVendor];
    statFolder = [statFolder stringByAppendingPathComponent:self.initialParameters.clientName];
    statFolder = [statFolder stringByAppendingPathComponent:self.initialParameters.productKey];
    statFolder = [statFolder stringByAppendingPathComponent:self.initialParameters.productVersionString];

    if (![STATRUtils createDirectoryIfNeededAtPath:statFolder]) {
        return;
    }

    self.dataDirectoryPath = statFolder;
}



- (void)registerDefaultSettings
{
    NSDictionary *defaultSettings = @{SettingStorageKeyCollectData: @(SettingDefCollectData),
                                      SettingStorageKeySendData: @(SettingDefSendData),
                                      SettingStorageKeyWaitTimeout: @(SettingDefWaitTimeout),
                                      SettingStorageKeySettingsPreviousConnectionTime: [NSDate date],
                                      SettingStorageKeyIsEnabledAutomaticDataSending: @(SettingDefIsEnabledAutomaticDataSending)};
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultSettings];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadSettings
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

    self.isCollectingDataEnabled = [settings boolForKey:SettingStorageKeyCollectData];
    self.isSendingDataEnabled = [settings boolForKey:SettingStorageKeySendData];
    self.waitTimeout = [settings integerForKey:SettingStorageKeyWaitTimeout];
    self.lastGetServerSettingsDate = [settings objectForKey:SettingStorageKeySettingsPreviousConnectionTime];
    _isEnabledAutomaticDataSending = [settings boolForKey:SettingStorageKeyIsEnabledAutomaticDataSending];
}

- (void)saveSettings
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

    [settings setBool:self.isCollectingDataEnabled forKey:SettingStorageKeyCollectData];
    [settings setBool:self.isSendingDataEnabled forKey:SettingStorageKeySendData];
    [settings setInteger:self.waitTimeout forKey:SettingStorageKeyWaitTimeout];
    [settings setObject:self.lastGetServerSettingsDate forKey:SettingStorageKeySettingsPreviousConnectionTime];
    [settings setBool:self.isEnabledAutomaticDataSending forKey:SettingStorageKeyIsEnabledAutomaticDataSending];

    [settings synchronize];
}

- (void)loadInstallationKey
{
    if ([self.dataDirectoryPath length] == 0)
        return;

    NSString *installationFile = [self.dataDirectoryPath stringByAppendingPathComponent:@"installation.key"];
    NSString *installationKey = @"";

    NSFileManager *flmng = [NSFileManager defaultManager];

    if ([flmng fileExistsAtPath:installationFile]) {
        NSData *dat = [flmng contentsAtPath:installationFile];
        if (dat == nil)
            installationKey = @"";
        else
            installationKey = [[NSString alloc] initWithData:dat encoding:NSUTF8StringEncoding];
    }

    if ([installationKey length] == 0) {
        installationKey = [STATRUtils deviceID];

        installationKey = [installationKey stringByAppendingString:[self.initialParameters.productKey substringFromIndex:[self.initialParameters.productKey length] - 4]];

        if ([installationKey writeToFile:installationFile atomically:NO encoding:NSUTF8StringEncoding error:nil] == NO)
            installationKey = @"";
    }


    self.installationKey = installationKey;

}

- (void)loadExecutionKey
{
    self.executionKey = [STATRUtils createTimedKey];
}

- (void)resetCurrentStorage
{
    self.currentStatisticsEventsStorageFileName = nil;
    self.currentStatisticsEventsStorageFileHandle = nil;
}

- (void)postStatEvent:(STATREvent *)StatEvent
{
    NSString *StatEventXml = [self statEventToXml:StatEvent];
    [self postStatEventXml:StatEventXml];
}

- (void)postStatEventXml:(NSString *)statEventXml
{
    if (self.isCollectingDataEnabled) {
        [self.statisticsEventList addObject:statEventXml];
    }
}

- (NSString *)statEventToXml:(STATREvent *)StatEvent
{
    STATRXmlWriter *XmlWriter = [_xmlWriter clean];
    @try {
        [self writeStatEvent:StatEvent withWriter:XmlWriter];
        return [XmlWriter xmlString];
    }
    @catch (...) {}

    return @"";
}

- (void)writeStatEvent:(STATREvent *)StatEvent withWriter:(STATRXmlWriter *)xmlWriter
{
    [xmlWriter writeElementStart:StatTagEvent];
    [xmlWriter writeAttribute:StatAttrName value:[StatEvent name]];
    [xmlWriter writeAttribute:StatAttrDateTime
                        value:[STATRUtils dateToString:[StatEvent eventDate]]];

    [xmlWriter writeAttribute:StatAttrOrder value:[NSString stringWithFormat:@"%d", [StatEvent order]]];

    [xmlWriter writeAttribute:StatAttrInstallationKey value:[self installationKey]];

    [xmlWriter writeAttribute:StatAttrExecutionKey value:[self executionKey]];

    if ([[StatEvent value] length] > 0) {
        [xmlWriter writeAttribute:StatAttrValue value:[StatEvent value]];
    }

    for (NSUInteger i = 0; i < [StatEvent parameterCount]; i++) {
        STATREventParameter *param = [StatEvent parameterAtIndex:i];// Params(i);

        if (([param.name length] == 0) || ([param.value length] == 0))
            continue;

        [xmlWriter writeElementStart:StatTagParam];
        [xmlWriter writeAttribute:StatAttrName value:param.name];
        
        NSString *parameterType = [param typeAsString];
        if ([parameterType length]) {
            [xmlWriter writeAttribute:StatAttrType value:parameterType];
        }
        [xmlWriter writeAttribute:StatAttrValue value:param.value];
        [xmlWriter writeElementEnd:StatTagParam];
    }
    [xmlWriter writeElementEnd:StatTagEvent];
}

- (void)addCustomEvent:(STATREvent *)event
{
    [self postStatEvent:event];
}

- (BOOL)sendCurrentStatEvents:(BOOL)OnExit
{
    NSString *Response = nil;

    BOOL res = [self.currentStatisticsEventsXml length] > 0;

    if (res) {
        NSDate *CurTime = [NSDate date];
        if ([self detectNeedSend:CurTime Exit:OnExit]) {
            self.lastSendDate = CurTime;
            STATRHttpRequestResult HttpResult = [self sendStatEvents:self.currentStatisticsEventsXml Response:&Response];
            
#ifdef _DEBUG
            NSLog(@"SENT DATA: %@", self.currentStatisticsEventsXml);
#endif
            
            if (HttpResult == STATRHttpRequestResultOk) {
                NSInteger intResponse = [Response integerValue];
                [self processErrorCode:intResponse];
            }
            else // ERROR_NO_CONNECTION ERROR_HTTP_ERROR
            {
                self.wasErrorDuringLastSend = YES;
            }
        }
        else
            res = NO;// don't repeat while in ThreadExecution
    }
    if (OnExit)
        self.isFinishingLastSend = YES;

    return res;
}

- (void)processErrorCode:(NSInteger)errorCode
{
    // switch error code - response from server after data sent
    switch (errorCode) {
        case ERROR_OK:
        case ERROR_APP_VER_IS_BLOCKED:
        case ERROR_APP_IS_BLOCKED:
        case ERROR_DATA_PACKAGE_IS_INVALID://Tracker clear this packet
            [self clearPersistedStatEvents:NO];
            break;

        case ERROR_INVALID_PROJECT: {// Clear all events, don't send events in this session
            [self clearPersistedStatEvents:YES];
            self.isSendingDataEnabled = NO;
            break;
        }

        case ERROR_IP_IS_BLOCKED:
        case ERROR_TRACKER_VER_IS_INVALID:// don't send events in this session
            self.isSendingDataEnabled = NO;
            break;

        case ERROR_INTERNAL_SERVER_ERROR:// try to send in next session
            self.wasErrorDuringLastSend = YES;
            break;

        default:
            break;
    }
}


- (void)clearPersistedStatEvents:(BOOL)AlsoClearAllFiles
{
    NSFileManager *flnmg = [NSFileManager defaultManager];

    if (self.currentStatisticsEventsStorageFileHandle) {
        [self.currentStatisticsEventsStorageFileHandle closeFile];
        [flnmg removeItemAtPath:self.currentStatisticsEventsStorageFileName error:nil];
    }

    [self.currentStatisticsEventsXml setString:@""];
    self.currentStatisticsEventsStorageFileName = nil;
    self.currentStatisticsEventsStorageFileHandle = nil;

    if (AlsoClearAllFiles) {
        NSArray *EventFiles = [STATRUtils filesInDirectoryAtPath:self.dataDirectoryPath mask:@"event-*.xml"];
        NSUInteger N = [EventFiles count];

        while (N > 0) {
            N--;
            NSString *EventFile = [self.dataDirectoryPath stringByAppendingPathComponent:[EventFiles objectAtIndex:N]];
            [flnmg removeItemAtPath:EventFile error:nil];
        }
    }
}

- (STATRHttpRequestResult)sendStatEvents:(NSString *)StatEvents Response:(NSString **)Response
{
    STATRHttpRequest *HttpRequest;

    STATRHttpRequestResult res = STATRHttpRequestResultError;
    *Response = @"";
    HttpRequest = self.httpRequest;
    @try {
        if (self.isThreadTerminated)
            return res;

        NSString *strFullXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?><%@ tracker=\"%@\">\n%@</%@>",
                                                          StatTagPackage,
                                                          self.initialParameters.trackerVersion,
                                                          StatEvents,
                                                          StatTagPackage
        ];

        res = [HttpRequest postToURL:self.initialParameters.serverUrl data:[strFullXML dataUsingEncoding:NSUTF8StringEncoding] response:Response];

        switch (res) {
            case STATRHttpRequestResultOk:
                [self eventDataSent:strFullXML andResponse:*Response];
                break;
            case STATRRequestResultNoConnection:
                [self eventDataSent:strFullXML andResponse:@"NO HTTP CONNECTION"];
                break;
            case STATRHttpRequestResultError:
                [self eventDataSent:strFullXML andResponse:@"HTTP ERROR"];
                break;
            default:
                break;
        }

    }
    @catch (...) {}

    return res;
}

- (BOOL)detectNeedSend:(NSDate *)CurTime Exit:(BOOL)OnExit
{
    if (!self.isSendingDataEnabled || !self.isDataSendingAllowedInCurrentNetwork) {
        return NO;
    }
    else if (!self.isEnabledAutomaticDataSending) {
        if (self.shouldSendDataOnce) {
            self.shouldSendDataOnce = NO;
            return YES;
        }
        else {
            return NO;
        }
    }
    else if (OnExit && !self.wasErrorDuringLastSend) {
        return YES;
    }

    if (self.lastSendDate == nil) {
        self.lastSendDate = self.startDate;// once after start
    }

    if (self.wasErrorDuringLastSend) {
        return [CurTime timeIntervalSinceDate:self.lastSendDate] > SendErrorIntervalSec;// if was error last time -  after hour
    }

    return [CurTime timeIntervalSinceDate:self.lastSendDate] > SendSuccessIntervalSec;// if last send without error - after 15 sec
}

- (void)processServerSettings
{
#ifdef _DEBUG
    NSLog(@"%@",@"processServerSettings");
#endif
    NSString *url = [NSString stringWithFormat:@"%@?key=%@&version=%@&tracker=%@", self.initialParameters.settingsServerUrl,
                    self.initialParameters.productKey,
                    self.initialParameters.productVersionString,
                    self.initialParameters.trackerVersion];

    NSString *Response = nil;

    STATRHttpRequestResult res = STATRHttpRequestResultError;

    STATRHttpRequest *HttpRequest = self.httpRequest;

    @try {
        res = [HttpRequest postToURL:url data:nil response:&Response];
    }
    @catch (...) {}

    if (res == STATRHttpRequestResultOk) {
        if ([Response length] == 0)
            return;

        self.lastGetServerSettingsDate = [NSDate date];// store last time when connect to server for get settings

        Response = [Response stringByAppendingFormat:@"&SettingPrevConnTime=%@", [STATRUtils dateToString:self.lastGetServerSettingsDate]];

        [self parseSettingsString:Response];

        [self saveSettings];

        [self trackerSettingsReceived:Response];
    }
    else {
        switch (res) {
            case STATRRequestResultNoConnection:
                [self trackerSettingsReceived:@"NO HTTP CONNECTION"];
                break;
            case STATRHttpRequestResultError:
                [self trackerSettingsReceived:@"HTTP ERROR"];
                break;
            default:
                break;
        }

    }
}

- (void)parseSettingsString:(NSString *)settingsString
{
    if ([settingsString length] == 0) {
        return;
    }

    BOOL collectData = SettingDefCollectData;
    BOOL sendData = SettingDefSendData;
    NSUInteger waitTimeout = SettingDefWaitTimeout;
    NSDate *SettingPrevConnTime = [NSDate date];

    // parse settings error_code=0&collect_data=1&send_data=1&wait_timeout=0[SettingPrevConnTime=123211231]
    NSInteger errorCode = SettingDefErrorCode;


    NSArray *listItems = [settingsString componentsSeparatedByString:@"&"];
    if ([listItems count]) {
        for (NSString *i in listItems) {
            NSRange KR = [i rangeOfString:@"error_code="];
            NSUInteger K0 = KR.location;
            if (K0 != NSNotFound) {
                K0 = K0 + [@"error_code=" length];
                NSUInteger K = [i length];

                if ((K != 0) && (K0 != 0) && (K > K0)) {
                    NSString *error_code = [i substringWithRange:NSMakeRange(K0, K - K0)];
                    errorCode = [error_code integerValue];
                }
            }

            KR = [i rangeOfString:@"collect_data="];
            K0 = KR.location;
            if (K0 != NSNotFound) {
                K0 = K0 + [@"collect_data=" length];
                NSUInteger K = [i length];

                if ((K != 0) && (K0 != 0) && (K > K0)) {
                    NSString *collect_data = [i substringWithRange:NSMakeRange(K0, K - K0)];
                    collectData = [collect_data boolValue];
                }
            }

            KR = [i rangeOfString:@"send_data="];
            K0 = KR.location;
            if (K0 != NSNotFound) {
                K0 = K0 + [@"send_data=" length];
                NSUInteger K = [i length];

                if ((K != 0) && (K0 != 0) && (K > K0)) {
                    NSString *send_data = [i substringWithRange:NSMakeRange(K0, K - K0)];
                    sendData = [send_data boolValue];
                }
            }

            KR = [i rangeOfString:@"wait_timeout="];
            K0 = KR.location;
            if (K0 != NSNotFound) {
                K0 = K0 + [@"wait_timeout=" length];
                NSUInteger K = [i length];

                if ((K != 0) && (K0 != 0) && (K > K0)) {
                    NSString *wait_timeout = [i substringWithRange:NSMakeRange(K0, K - K0)];
                    waitTimeout = [wait_timeout integerValue];
                }
            }


            KR = [i rangeOfString:@"SettingPrevConnTime="];
            K0 = KR.location;
            if (K0 != NSNotFound) {
                K0 = K0 + [@"SettingPrevConnTime=" length];
                NSUInteger K = [i length];

                if ((K != 0) && (K0 != 0) && (K > K0)) {
                    NSString *_SettingPrevConnTime = [i substringWithRange:NSMakeRange(K0, K - K0)];
                    SettingPrevConnTime = [STATRUtils stringToDate:_SettingPrevConnTime];
                }
            }

        }
    }


    if (waitTimeout > SettingMaxWaitTimeout )
        waitTimeout = SettingMaxWaitTimeout;

    if ([SettingPrevConnTime compare:[NSDate date]] == NSOrderedDescending) // if date is bed
        SettingPrevConnTime = [NSDate date];//store the current date

    self.isCollectingDataEnabled = collectData;
    self.isSendingDataEnabled = sendData;
    self.waitTimeout = waitTimeout;

    self.lastGetServerSettingsDate = SettingPrevConnTime;// get settings last time
}


- (void)processStatEvents:(BOOL)OnExit
{
    NSString *StatEventsXml = [self peekStatEvents:MaxStatEventsBufferSize - [self.currentStatisticsEventsXml length]];// if current > max return empty string
    if (!OnExit)
        [self openPersistedStatEvents:YES EventsToAdd:StatEventsXml];//also get events from other files if currentStatisticsEventsXml empty now
    else
        [self storePersistedStatEvents:StatEventsXml];

    while (YES) {
        StatEventsXml = [self peekStatEvents:MaxStatEventsBufferSize];//get events from list to string
        if ([StatEventsXml length] == 0)
            break;
        [self storePersistedStatEvents:@""];// save and close current file with events(currentStatisticsEventsXml + _T("")), currentStatisticsEventsXml.clear()...
        if (!OnExit)
            [self openPersistedStatEvents:NO EventsToAdd:StatEventsXml];//currentStatisticsEventsXml = currentStatisticsEventsXml + StatEventsToAdd...
    }
}


- (void)storePersistedStatEvents:(NSString *)StatEventsToAdd
{
    if (self.currentStatisticsEventsStorageFileHandle) {
        NSString *forSave = [self.currentStatisticsEventsXml stringByAppendingString:StatEventsToAdd];

        NSFileManager *flmng = [NSFileManager defaultManager];
        [flmng createFileAtPath:self.currentStatisticsEventsStorageFileName contents:[forSave dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];// rewrite file

        [self.currentStatisticsEventsStorageFileHandle closeFile];
    } else if ([self.currentStatisticsEventsXml length]) {
        [self checkStatEventsFolderFilesSize];//

        NSString *fileName = [self getNextStorageFileName];
        NSString *fileData = [self.currentStatisticsEventsXml stringByAppendingString:StatEventsToAdd];

        NSFileManager *flmng = [NSFileManager defaultManager];
        [flmng createFileAtPath:fileName contents:[fileData dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    [self.currentStatisticsEventsXml setString:@""];// clear
    self.currentStatisticsEventsStorageFileName = @"";
    self.currentStatisticsEventsStorageFileHandle = nil;
}

- (void)openPersistedStatEvents:(BOOL)CheckPrevFiles EventsToAdd:(NSString *)StatEventsToAdd
{

    [self.currentStatisticsEventsXml appendString:StatEventsToAdd];//= currentStatisticsEventsXml + StatEventsToAdd;
    if (self.currentStatisticsEventsStorageFileHandle != nil)// append events to current file-store
    {
        if ([StatEventsToAdd length]) {
            NSData *dt = [StatEventsToAdd dataUsingEncoding:NSUTF8StringEncoding];
            [self.currentStatisticsEventsStorageFileHandle writeData:dt];
        }
        return;
    }

    BOOL bDelete;
    NSString *EventsXml = nil;

    if (CheckPrevFiles) {
        NSArray *EventFiles = [STATRUtils filesInDirectoryAtPath:self.dataDirectoryPath mask:@"event-*.xml"];

        @try {
            NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"" ascending:YES];
            NSArray *sortArrDesc = [NSArray arrayWithObject:desc];
            EventFiles = [EventFiles sortedArrayUsingDescriptors:sortArrDesc];//[NSMutableArray arrayWithArray: ];

            NSUInteger N = [EventFiles count];
            while ((N > 0) && ([self.currentStatisticsEventsXml length] < MaxStatEventsBufferSize)) {
                N--;
                NSString *EventFile = [self.dataDirectoryPath stringByAppendingPathComponent:[EventFiles objectAtIndex:N]];// EventFiles[N]);// get the last file

                NSFileHandle *EventFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:EventFile];


                if (EventFileHandle) {
                    bDelete = NO;
                    NSData *sdt = [EventFileHandle readDataToEndOfFile];

                    EventsXml = [[NSString alloc] initWithData:sdt encoding:NSUTF8StringEncoding];

                    if (EventsXml) {
                        if (([self.currentStatisticsEventsXml length] == 0) || ([EventsXml length] <= MaxStatEventsBufferSize)) {// EventsXml.length always less MaxStatEventsBufferSize
                            if (([EventsXml length] + [self.currentStatisticsEventsXml length]) > MaxStatEventsBufferSize ) {
                                if (EventFileHandle)
                                    [EventFileHandle closeFile];
                                break;
                            }
                            bDelete = YES;
                            [self.currentStatisticsEventsXml appendString:EventsXml];
                            if (self.currentStatisticsEventsStorageFileHandle == nil) {
                                self.currentStatisticsEventsStorageFileName = EventFile;
                                self.currentStatisticsEventsStorageFileHandle = EventFileHandle;
                                EventFileHandle = nil;
                                bDelete = NO;
                            }
                        }
                    }


                    if (EventFileHandle)
                        [EventFileHandle closeFile];
                    if (bDelete) {
                        NSFileManager *flmng = [NSFileManager defaultManager];
                        [flmng removeItemAtPath:EventFile error:nil];
                    }
                }

            }
        }
        @catch (...) {}
    }

    if (self.currentStatisticsEventsStorageFileHandle == nil)// create new file for store events
    {
        [self checkStatEventsFolderFilesSize];//
        self.currentStatisticsEventsStorageFileName = [self getNextStorageFileName];
        NSFileManager *flmng = [NSFileManager defaultManager];
        [flmng createFileAtPath:self.currentStatisticsEventsStorageFileName contents:nil attributes:nil];
        self.currentStatisticsEventsStorageFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.currentStatisticsEventsStorageFileName];
    }
    // and save to file
    if (self.currentStatisticsEventsStorageFileHandle) {
        NSFileManager *flmng = [NSFileManager defaultManager];
        [flmng createFileAtPath:self.currentStatisticsEventsStorageFileName contents:[self.currentStatisticsEventsXml dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
}

- (NSString *)getNextStorageFileName
{
    self.storageFileNumber++;

    NSString *t = [[NSString stringWithFormat:@"%3x", self.storageFileNumber]
            stringByReplacingOccurrencesOfString:@" " withString:@"0"];
    NSString *fileName = [NSString stringWithFormat:@"event-%@-%@.xml", self.executionKey, t];

    return [self.dataDirectoryPath stringByAppendingPathComponent:fileName];
}


- (NSString *)peekStatEvents:(NSInteger)MaxSize
{
    NSMutableString *res = [[NSMutableString alloc] initWithString:@""];
    if (MaxSize <= 0)
        return res;

    @try {
        while (0 < [self.statisticsEventList count]) {
            NSString *OneEvent = [self.statisticsEventList objectAtIndex:0];
            if (([res length] + [OneEvent length]) > MaxSize)
                break;// res.size must be less MaxSize
            [res appendString:OneEvent];
            [self.statisticsEventList removeObject:OneEvent];
        }
    }
    @catch (...) {}

    return res;
}

- (void)checkStatEventsFolderFilesSize
{
    unsigned long long folderSize = 0;
    unsigned long long Result = 0;

    NSArray *EventFiles = [STATRUtils filesInDirectoryAtPath:self.dataDirectoryPath mask:@"event-*.xml"];

    NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"" ascending:YES];
    NSArray *sortArrDesc = [NSArray arrayWithObject:desc];
    EventFiles = [EventFiles sortedArrayUsingDescriptors:sortArrDesc];//[NSMutableArray arrayWithArray: ];


    NSMutableDictionary *filesMap = [[NSMutableDictionary alloc] initWithCapacity:[EventFiles count]];
    NSFileManager *flmng = [NSFileManager defaultManager];

    for (NSString *fileName in EventFiles) {
        unsigned long long fileSz = [[flmng attributesOfItemAtPath:fileName error:nil] fileSize];
        Result = Result + fileSz;
        [filesMap setObject:[NSNumber numberWithUnsignedLongLong:fileSz] forKey:fileName];

    }


    folderSize = Result;

    NSUInteger currentFileNumber = 0;
    while (folderSize > MaxStatEventsFolderFilesSize ) {
        if ([filesMap count] == 0)
            break;

        NSString *flname = [EventFiles objectAtIndex:currentFileNumber];
        currentFileNumber++;
        NSString *fln = [self.dataDirectoryPath stringByAppendingPathComponent:flname];

        if ([flmng removeItemAtPath:fln error:nil])
            folderSize = folderSize - [[filesMap objectForKey:flname] unsignedLongLongValue];

        [filesMap removeObjectForKey:flname];
    }
}

- (void)trackerSettingsReceived:(NSString *)settingsText
{

    [[NSNotificationCenter defaultCenter] postNotificationName:kTrackerSettingsReceived object:settingsText userInfo:nil];
}

- (void)eventDataSent:(NSString *)eventDataXML andResponse:(NSString *)responseText
{

    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:eventDataXML forKey:kEventDataXML];
    [info setValue:responseText forKey:kResponseText];

    [[NSNotificationCenter defaultCenter] postNotificationName:kEventDataSentAndResponse object:nil userInfo:info];
}


#pragma mark Work with failure file

- (void)processFailureFiles
{
    if ([self.dataDirectoryPath length] == 0) {
        return;
    }

    NSArray *EventFiles = [STATRUtils filesInDirectoryAtPath:self.dataDirectoryPath mask:@"proc-*"];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL shouldSendFailureNotification = NO;
    for (NSString *fileName in EventFiles) {
        NSError *err;
        NSString *filePath = [self.dataDirectoryPath stringByAppendingPathComponent:fileName];
        NSString *str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];

        if ([str length]) {
            shouldSendFailureNotification = YES;
            [self postStatEventXml:str];
        }
        [fileManager removeItemAtPath:filePath error:&err];
    }
    
    if (shouldSendFailureNotification && !self.isEnabledAutomaticDataSending) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kManualDataSendIsPossibleAfterFailureNotification object:self];
    }
}

- (void)loadFailureFileName
{
    if ([self.dataDirectoryPath length] == 0) {
        return;
    }

    NSString *temp = [NSString stringWithFormat:@"%d", [STATRUtils currentProcessID]];
    self.failureFileName = [self.dataDirectoryPath stringByAppendingPathComponent:[@"proc-" stringByAppendingString:temp]];
}

- (void)updateFailureFile
{
    if ((self.failureFileName == nil) && ([self.failureFileName length] == 0)) {
        return;
    }

    NSDate *CurTime = [NSDate date];
    if (self.failureUpdateDate) {
        NSTimeInterval ti = [CurTime timeIntervalSinceDate:self.failureUpdateDate];
        if (ti < 60) {      // do not rewrite file
            return;
        }
    }

    STATREventAppFailure *StatEvent = [[STATREventAppFailure alloc] initWithAppStartDate:self.startDate failureDate:CurTime];

    NSString *FailureXml = [self statEventToXml:StatEvent];

    if ([FailureXml length])//rewrite
    {
        NSFileManager *flmng = [NSFileManager defaultManager];
        [flmng createFileAtPath:self.failureFileName contents:[FailureXml dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];// rewrite file with new failure event
    }
    self.failureUpdateDate = CurTime;

}

- (void)removeFailureFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:self.failureFileName]) {
        [fileManager removeItemAtPath:self.failureFileName error:nil];
        self.failureFileName = nil;
    }
}

- (void) logUserProfileWithBirthday:(NSDate*)birthday gender:(NSInteger)gender
{
    STATREventUserProfile *event = [[STATREventUserProfile alloc] initWithBirthday:birthday
                                                                            gender:gender?@"female":@"male"];
    [self postStatEvent:event];
}

- (void) logUserProfileWithAge:(NSInteger)age gender:(NSInteger)gender
{
    STATREventUserProfile *event = [[STATREventUserProfile alloc] initWithAge:age
                                                                       gender:gender?@"female":@"male"];
    [self postStatEvent:event];
}

-(void) logFPS:(NSInteger)FPSValue viewController:(UIViewController*) viewController
{
    
    // check - if the name of window was changed
    if(![self.FPSwindowName isEqual:viewController.title]){
        
        // check - Is this firts log call
        if(![self.FPSwindowName isEqual:@""] &&
           [STATRManager sharedManager].minFPS != 0 &&
           [STATRManager sharedManager].maxFPS != 0){

            // send data about previous FPS avg value for current scene
            STATREventFPS *event = [[STATREventFPS alloc] initWithMinFPS:self.minFPS
                                                                  maxFPS:self.maxFPS
                                                              windowName:self.FPSwindowName
                                                        parentWindowName:self.FPSparentWindowName];
            [self postStatEvent:event];
            
#ifdef _DEBUG
            NSLog(@"Log FPS: send data => FPS min = %d", self.minFPS);
            NSLog(@"Log FPS: send data => FPS max = %d", self.maxFPS);
#endif
        }
        
        // save new values
        self.minFPS = FPSValue;
        self.maxFPS = FPSValue;
        self.FPSwindowName = [self getCaptionParameterForViewController:viewController];
        self.FPSparentWindowName = [self getParentCaptionParameterForViewController:viewController];
#ifdef _DEBUG
        NSLog(@"Log FPS: reset max/min values, nameSceneFPS");
#endif
    }
    // sceneName is the same
    else{
        if(FPSValue<self.minFPS){
            
            [STATRManager sharedManager].minFPS = FPSValue;
#ifdef _DEBUG
            NSLog(@"Log FPS: change minFPS = %d", [STATRManager sharedManager].minFPS);
#endif
        }
        else if(FPSValue>self.maxFPS){
            
            self.maxFPS = FPSValue;
#ifdef _DEBUG
            NSLog(@"Log FPS: change maxFPS = %d", self.maxFPS);
#endif
        }
        else{
#ifdef _DEBUG
            NSLog(@"Log FPS: the same value of FPS");
#endif
        }
    }
}

- (void) logInAppPurchaseWithName:(NSString*)purchaseName
                             type:(NSInteger) purchaseType
                             cost:(float) purchaseCost
                            state:(NSInteger) purchaseState
                           userID:(NSString*) userID
                           market:(NSString*)purchaseMarket
{
    STATREventInAppPurchase *event = [[STATREventInAppPurchase alloc] initWithPurchaseName:purchaseName
                                                                                      type:purchaseType
                                                                                      cost:purchaseCost
                                                                                     state:purchaseState
                                                                                    userID:userID
                                                                                      date:[NSDate date]
                                                                                    market:purchaseMarket];
    [self postStatEvent:event];
}


@end
