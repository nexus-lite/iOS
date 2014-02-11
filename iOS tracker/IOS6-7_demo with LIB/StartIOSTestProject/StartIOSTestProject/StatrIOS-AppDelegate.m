//
//  StatrIOS_AppDelegate.m
//  StatrIOSTestProject
//
//  Copyright (c) 2013 STATR. All rights reserved.
//

#import "StatrIOS-AppDelegate.h"
// Import header file to use STATR tracker
#import "STATR.h"

/**********************************************************************************************************
                                        Global constants
 *********************************************************************************************************/

// Write here your product key. You can get it from your managed project from STATR site
//#define PRODUCT_KEY		@"77b4fa754876b21ca4e604bb2cb8ac36523" // iOS test final
#define PRODUCT_KEY		@"9e9875dfa56ef0f7726e3c6522063db0563"
// Write here name of your product
#define PRODUCT_NAME	@"STATR demo iOS project"
// Write here vendor name of your product
#define PRODUCT_VENDOR	@"ELEKS"
// Write here package type of your product
#define PRODUCT_PACKAGE	@"Free"
// Write here your device name
#define DEVICE_NAME     @"MyIphoneName"

// define this constant for using iOS7 storyboard (else use iOS6 storyboard => and remove storyboard for iOS7 from Bundle resources)
#define IOS7_SDK

@implementation StatrIOS_AppDelegate
/**********************************************************************************************************
                        event : "application didFinishLaunchingWithOptions"
 **********************************************************************************************************/
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIStoryboard *mainStoryboard = nil;
    
    // Load corresponding storyboard for iOS7 or iOS6
#ifdef IOS7_SDK
    mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iOS7" bundle:nil];
#else
    mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iOS6" bundle:nil];
#endif
    
    self.initialVC = [mainStoryboard instantiateInitialViewController];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.initialVC;
    [self.window makeKeyAndVisible];
    
    // Customize navigation bar
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithWhite:0 alpha:1.0f]];

    // Register notifications for receiving and handling events from STATR tracker.
    // Called when exception was received
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ExceptionEventNotif:)
                                                 name:kExceptionEventNotification
                                               object:nil];
    // Called when settings of tracker was received
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(TrackerSettingsReceivedNotif:)
                                                 name:kTrackerSettingsReceived
                                               object:nil];
    // Called when data was sent and response was received
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(EventDataSentAndResponseNotif:)
                                                 name:kEventDataSentAndResponse
                                               object:nil];
    // Handle possibility to send data manually if automatic data sending is disabled and app failure occured
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showManualDataSendAlert)
                                                 name:kManualDataSendIsPossibleAfterFailureNotification
                                               object:nil];
    
	// Initialize parameters of STATR tracker
	STATRInitParameters * initParams = [[STATRInitParameters alloc] init];
	initParams.productKey       = PRODUCT_KEY;
    initParams.productName      = PRODUCT_NAME;
    initParams.productVendor    = PRODUCT_VENDOR;
    initParams.deviceName       = DEVICE_NAME;
    
    // check from registry last product package that user recently chose
    NSString *lastPackage = [[NSUserDefaults standardUserDefaults] objectForKey:@"product_package"];
    if(lastPackage){

        initParams.productPackage= lastPackage;
    }
    else{
        initParams.productPackage = PRODUCT_PACKAGE;
        [[NSUserDefaults standardUserDefaults] setObject:PRODUCT_PACKAGE
                                                  forKey:@"product_package"];
    }
    
    // Sandbox => this option is used your data will be posted to our sandbox server which is faster but
    // limited by the number of requests – up to 100 requests per project per day. In case you were trying
    // integration and reached the limit you should create a new project and use another Project Key.
    initParams.UseSandbox = NO;
    
    // ProductVersion => Tracker automatically get your version of product from project settings,
    // but you can manualy set it with follow code: (uncomment next line).
    //initParams.ProductVersion = [[SoftwareStatisticsProductVersion alloc] initWithMajor:0 minor:0 release:0 build:1];
    
    [[STATRManager sharedManager] setInitialManagerParameters:initParams];
    
    // AutomaticDataSending => By default, STATR tracker automaticaly sent data to over server but you
    // can disable this option.
    [STATRManager sharedManager].isEnabledAutomaticDataSending = YES;
    
    // When AutomaticDataSending is disabled you can manually sent all collected data by next metod in
    // any part of your app code:
    //[[STATRManager sharedManager] sendDataManually];

    // DataSendingOverCellularNetwork => By default, STATR tracker is able to sent data over cellular
    // network. You can disable this option.
    [STATRManager sharedManager].isEnabledDataSendingOverCellularNetwork = YES;
    
    return YES;
}
/*********************************************************************************************************
                                event : "ExceptionEventNotif"
********************************************************************************************************/
- (void)ExceptionEventNotif:(NSNotification *)notification
{
    NSString *excepText = [notification object];
    NSString* message = [NSString stringWithFormat:@"Exception: %@", excepText];
    
    // Write message to iOS simulation console
    NSLog(@"ExceptionEvent = %@", message);
}
/*********************************************************************************************************
                                event : "TrackerSettingsReceivedNotif"
 ********************************************************************************************************/
- (void)TrackerSettingsReceivedNotif:(NSNotification *)notification
{
    NSString *settingsText = [notification object];
    NSString* message = [NSString stringWithFormat:@"TrackerSettings: %@", settingsText];
    
    // Write message to iOS simulation console
    NSLog(@"TrackerSettings = %@", message);
}
/*********************************************************************************************************
                                event : "EventDataSentAndResponseNotif"
 ********************************************************************************************************/
- (void)EventDataSentAndResponseNotif:(NSNotification *)notification
{
    NSString* eventDataXML = [[notification userInfo] objectForKey:kEventDataXML];
    NSString* responseText = [[notification userInfo] objectForKey:kResponseText];
    NSString* message = [NSString stringWithFormat:@"SendEventData size=%d, response=%@", [eventDataXML length], responseText];
    // Write message to iOS simulation console
    NSLog(@"DataSentAndResponseNotif = %@", message);
}
/*********************************************************************************************************
                                selector : "showManualDataSendAlert"
 ********************************************************************************************************/
- (void)showManualDataSendAlert
{
    // Show alert viw on screen
    UIAlertView *askAlertView = [[UIAlertView alloc] initWithTitle:@"The programm was not correctly clossed last time"
                                                           message:@"Do you want send the collected data to our server?"
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                                 otherButtonTitles:@"OK", nil];
    [askAlertView show];
}
/*********************************************************************************************************
                            event : "alertView, clickedButtonAtIndex"
 ********************************************************************************************************/
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // if pressed button OK
    if(buttonIndex == 1){
        
        [[STATRManager sharedManager] sendDataManually];
    }
}

@end
