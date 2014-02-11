//
//  STATR.h
//  STATR Analytics
//
//  © 2010-2014 STATR
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class STATRXmlWriter;
@class STATRHttpRequest;

/** @file */

/*! \mainpage STATR analytics
 *
 * \section testusing How to use STATR Analytics in iOS
 
 Simple using STATRManager in your code.
 
 
 1) To initialize the STATRManager use code below when application is started:
 
 \code
 #import "STATR.h"
 
 // Write here your product key. You can get it from your managed project from STATR site
 #define PRODUCT_KEY		@"123a08b85cd0e05f1g75970123456h123456"
 // Write here name of your product
 #define CLIENT_NAME       @"Some client name"
 // Write here package type of your product (demo, free, debug)
 #define PRODUCT_PACKAGE	@"Demo"
 // Write here your device name
 #define DEVICE_NAME        @"My iphone name"
 
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
 {
    // Register notifications for receiving and handling events from STATR tracker.
    // Called when exception was received
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ExceptionEventNotification:)
                                                 name:kExceptionEventNotification
                                               object:nil];
    // Called when settings of tracker was received
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(TrackerSettingsReceivedNotification:)
                                                 name:kTrackerSettingsReceived
                                              object:nil];
    // Called when data was sent and response was received
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(EventDataSentAndResponseNotification:)
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
    initParams.clientName       = CLIENT_NAME;
    initParams.productPackage   = PRODUCT_PACKAGE;
    initParams.deviceName       = DEVICE_NAME;
 
    // Sandbox => this option is used your data will be posted to our sandbox server which is faster but
    // limited by the number of requests – up to 100 requests per project per day. In case you were trying
    // integration and reached the limit you should create a new project and use another Project Key.
    initParams.useSandbox = NO;
 
    // Set init params to tracker
    [[STATRManager sharedManager] setInitialManagerParameters:initParams];
 
    // Enable/disable auto sending data (by default - YES)
    [STATRManager sharedManager].isEnabledAutomaticDataSending = YES;
 
    // Enable/disable sending data over cellular networ(by default - YES)
    [STATRManager sharedManager].isEnabledDataSendingOverCellularNetwork = YES;
 }
 \endcode
 
 2) You can implement the methods for notifications:
 
 \code
 - (void)exceptionEventNotification:(NSNotification *)notification
 {
    NSString *exceptionText = [notification object];
    NSString *message = [NSString stringWithFormat:@"Exception: %@", exceptionText];
    NSLog(@"%@", message);
 }
 
 - (void)trackerSettingsReceivedNotification:(NSNotification *)notification
 {
    NSString *settingsText = [notification object];
    NSString *message = [NSString stringWithFormat:@"TrackerSettings: %@", settingsText];
    NSLog(@"%@", message);
 }
 
 - (void)eventDataSentAndResponseNotification:(NSNotification *)notification
 {
    NSString *eventDataXML = [[notification userInfo] objectForKey:kEventDataXML];
    NSString *responseText = [[notification userInfo] objectForKey:kResponseText];
    NSString *message = [NSString stringWithFormat:@"SendEventData size=%d, response=%@", [eventDataXML length], responseText];
    NSLog(@"%@", message);
 }
 
 - (void)showManualDataSendAlert
 {
    // Show alert viw on screen
    UIAlertView *askAlertView = [[UIAlertView alloc] initWithTitle:@"The program was not correctly closed last time"
                                                           message:@"Do you want send the collected data to our server?"
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                                 otherButtonTitles:(@"OK", nil];
    [askAlertView show];
 }
 \endcode
 
 3) Use code below when you want to add some custom event without parameters or with one or more parameters:
 
 \code
 // First type: simple event
 - (void) someAction
 {
    STATREvent *simpleCustomEvent = [[STATREvent alloc] initWithName:@"Some event name"
                                                                date:[NSDate date];
 
    [simpleCustomEvent addTextParameterWithName:@"string parameter name"
                                          value:@"parameter value"];
    [simpleCustomEvent addIntegerParameterWithName:@"numeric parameter name"
                                             value:123456];
    [simpleCustomEvent addLogParameterWithName:@"log parameter name"
                                         value:@"log string"];
    [simpleCustomEvent addErrorParameterWithName:@"exception parameter name"
                                           value:@"exception string"];
 
    [[STATRManager sharedManager] addCustomEvent:simpleCustomEvent];
 }
 
 // Second type: with ViewController parameter (for building user-flow statistics)
 - (void) someAction {
 
    // Initialization of custom event
    STATREvent *yourCustomEvent = [[STATREvent alloc] initWithName:@"UI Button"
                                                              date:[NSDate date]
                                                    viewController:self];
    // Add text parameter to custom event
    [yourCustomEvent addTextParameterWithName:@"User touch"
                                        value:@"CE Initial View"];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomEvent];
 }
 
 
// Third type: with event (or point) and ViewController (for building user-flow and heat-map statistics)
 
 - (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
 
    [super touchesBegan:touches withEvent:event];
 
    // Initialization of custom event
    STATREvent *yourCustomEvent = [[STATREvent alloc] initWithName:@"Touch began"
                                                              date:[NSDate date]
                                                             event:event
                                                    viewController:self];
    // Add text parameter to custom event
    [yourCustomEvent addTextParameterWithName:@"User touch"
                                        value:@"CE Initial View"];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomEvent];
 }
 
 // or
 
 - (void) someAction {
 
    // Initialization of custom event
    STATREvent *yourCustomEvent = [[STATREvent alloc] initWithName:@"UI Button"
                                                                     date:[NSDate date]
                                                                    point:someObject.center
                                                           viewController:self];
    // Add string parameter to custom event
    [yourCustomEvent addTextParameterWithName:@"Some text parameter name"
                                        value:@"Some text parameter value"];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomEvent];
 }
 \endcode
 
 4) For tracking transitions between views use next code: 
    NOTE: Build your application in storyboard with UINavigationBar. STATR tracker will track transitions beetwen views.
 
 \code
 // First type: auto tracking. For this you must inherit your new SomeViewControler / SomeTableViewController class from our
 // STATRViewController or STATRTableViewController classes instead of UIViewController or UITableViewController.
 // NOTE: Your ViewCotrollers / Views should have a signed titles (set them in Interface builder or programmatically).
 
 @interface SomeViewControler : STATRViewController
 //.. or ..
 @interface SomeTableViewController : STATRTableViewController

 // Second type: manual tracking. For this you must add two methods into ViewDidAppear and ViewDidDisAppear methods of your controller.
 - (void) viewDidAppear:(BOOL)animated
 {
    [super viewDidAppear:animated];
 
    [[STATRManager sharedManager] trackViewAppearOfViewController:self];
 }
 - (void) viewDidDisappear:(BOOL)animated
 {
    [super viewDidDisappear:animated];
 
    [[STATRManager sharedManager] trackViewDisappearOfViewController:self];
 }
 \endcode
 
 5) You can log FPS value for each view controller (not currently available):
  
 \code
 [[STATRManager sharedManager] logFPS:someCurrentFPSValue viewController:self];
 \endcode
 
 6) Use next methods for log user profile information (not currently available):
 
 \code
 // Log user profile information
 [[STATRManager sharedManager] logUserProfileWithAge:22 gender:Gender_male];
 // or
 NSDateFormatter *dateForm = [[NSDateFormatter alloc] init];
 [dateForm setDateFormat:@"yyyy'-'MM'-'dd"];
 NSDate *birthday = [dateForm dateFromString:@"1985-06-18"];
 [[STATRManager sharedManager] logUserProfileWithBirthday:birthday gender:Gender_female];
 \endcode
 
 7) Also you can log some in-app purchase event (not currently available):
 
 \code
 // Add in-app purchase event
 [[STATRManager sharedManager] logInAppPurchaseWithName:@"fire"
                                                   type:PurchaseType_Consumables
                                                   cost:0.99f
                                                  state:PurchaseState_Failed
                                                 userID:@"nexus-one"
                                                 market:@"AppStrore"];
 \endcode
 
 For more information see demo project.
 */


//  Notifications
/** \brief Notification when exception was received
 */
extern NSString *kExceptionEventNotification;

/** \brief Notification when settings of tracker was received
 */
extern NSString *kTrackerSettingsReceived;

/** \brief Notification when data was sent and response was received
 */
extern NSString *kEventDataSentAndResponse;

/** \brief Notification that is posted when automatic data sending is disabled and app failure occured.
 */
extern NSString *kManualDataSendIsPossibleAfterFailureNotification;

/** \brief Define for get xml with events
 */
extern NSString *kEventDataXML;

/** \brief Define for get response text
 */
extern NSString *kResponseText;

/** \enum STATRParameterType
 *	\brief Type of event parameters
 *
 * Use STATRParameterTypeText for simple string type
 * Use STATRParameterTypeError for error string type
 * Use STATRParameterTypeLog for log string type
 * Use STATRParameterTypeNumeric for numeric type
 */
typedef enum
{
    STATRParameterTypeError = 1,
    STATRParameterTypeText,
    STATRParameterTypeNumeric,
    STATRParameterTypeLog
} STATRParameterType;

/** \class STATREventParameter
 *	\brief Interface of parameter of the tracker event
 */
@interface STATREventParameter : NSObject
{
    NSString *_name;
    NSString *_value;
    STATRParameterType _type;
}

/** \brief Get name of parameter
*/
@property (nonatomic, readonly) NSString *name;

/** \brief Get value of parameter
*/
@property (nonatomic, strong) NSString *value;

/** \brief Get type of parameter
 */
@property (nonatomic, readonly) NSString *typeAsString;

/** \brief Initialise method
 *
 * \param name Name of parameter
 * \param value Value of parameter
 * \param type Type of parameter, default is text
 */
- (id)initWithName:(NSString *)name value:(NSString *)value type:(STATRParameterType)type;

@end

/**  STATRProductVersion
 *	\brief Interface of product version
 */
@interface STATRProductVersion : NSObject
{
    NSInteger _majorVersionNumber;
    NSInteger _minorVersionNumber;
    NSInteger _releaseNumber;
    NSInteger _buildNumber;
}

/** \brief Initialise method with version parameters (recommend)
 *
 * You must use just this constructor for create right version of your application
 * \param majorVersion version number of category major
 * \param minorVersion version number of category minor
 * \param release version number of release
 * \param build version number of build
 */
- (id)initWithMajor:(NSInteger)majorVersion minor:(NSInteger)minorVersion release:(NSInteger)release build:(NSInteger)build;

/**
 * Get string with version
 */
@property (weak, nonatomic, readonly) NSString *versionAsString;

@end

/** \class STATRInitParameters
 *	\brief Interface with initialization parameters for STATRManager
 */
@interface STATRInitParameters : NSObject

/** \brief Product key is unique project identifier.
 *
 * Registered users can find this key under their account in project management section
 * For details visit: http://www.statr.co
 */
@property (nonatomic, strong) NSString *productKey;

/** \brief Name of client
 */
@property (nonatomic, strong) NSString *clientName;

/** \brief Name of device
 */
@property (nonatomic, strong) NSString *deviceName;

/** \brief Version of product. If this is not set CFBundleVersion value from app's Info.plist is used
 */
@property (nonatomic, strong) STATRProductVersion *productVersion;

/** \brief Use Sandbox or Data1 server
 *
 * You must set true if you want to use the Sandbox server for gathering statistic
 * or false to use Data1 server
 */
@property (nonatomic) BOOL useSandbox;

/** \brief Describes software package type e.g. Professional, Gold, Paid, Trial, Demo etc.
 * any additional information about this particular application build.
 *
 * Can be used to track conversions e.g how many users who downloaded demo package
 * later bought some paid version.
 */
@property (nonatomic, strong) NSString *productPackage;

@property (nonatomic, strong) NSString *serverUrl;
@property (nonatomic, strong) NSString *settingsServerUrl;
@property (nonatomic, strong) NSString *trackerVersion;

@property (nonatomic, readonly) NSString *productVersionString;

@end

/**  STATREvent
 *	\brief Interface of statr custom event
 */
@interface STATREvent : NSObject
{
@protected
    NSString *_name;
    NSInteger _order;
    NSString *_value;
    NSDate *_eventDate;

    NSMutableArray *_parameters; // of STATREventParameter
}

/** \brief Tracker event name
 */
@property (nonatomic, strong) NSString *name;

/** \brief Tracker event order
 */
@property (nonatomic) NSInteger order;

/** \brief Tracker event value
 */
@property (nonatomic, strong) NSString *value;

/** \brief DateTime when tracker event was created (occurred)
 */
@property (nonatomic, strong) NSDate *eventDate;

/** \brief Mutable array of event parameters (STATREventParameter)
 */
@property (nonatomic, strong) NSMutableArray *parameters;

/** \brief Simple custom event
 *
 * @param name Event name
 * @param eventDate Event time creating
 */

- (id)initWithName:(NSString *)name date:(NSDate *)eventDate;

/** \brief Custom event with window information (user-flow)
 *
 * @param name Event name
 * @param eventDate Event time creating
 * @param viewController View controller name
 
 */
- (id)initWithName:(NSString *)name
              date:(NSDate *)eventDate
    viewController:(UIViewController*)viewController;

/** \brief Custom event with window information and touch position (user-flow + heat-map)
 *
 * @param name Event name
 * @param eventDate Event time creating
 * @param event UIEvent which contains touch
 * @param viewController View controller name
 */
- (id)initWithName:(NSString *)name
              date:(NSDate *)eventDate
             event:(UIEvent *)event
    viewController:(UIViewController*)viewController;

/** \brief Custom event with window information and coordinates x, y as CGPoint (user-flow + heat-map)
 *
 * @param name Event name
 * @param eventDate Event time creating
 * @param point Coordinates x, y as CGPoint
 * @param viewController View controller name
 */
- (id)initWithName:(NSString *)name
              date:(NSDate *)eventDate
             point:(CGPoint)point
    viewController:(UIViewController*)viewController;

/** \brief Method for removing previous parameters for this event
*/
- (void)removeAllParameters;

/** \brief Method for adding text parameter to tracker event
 *
 * @param name Parameter name
 * @param value Parameter value is string
 */
- (void)addTextParameterWithName:(NSString *)name value:(NSString *)value;

/** \brief Method for adding numeric parameter to tracker event
 *
 * @param name Parameter name
 * @param value Parameter value is integer
 */
- (void)addIntegerParameterWithName:(NSString *)name value:(NSInteger)value;

/** \brief Method for adding log parameter to tracker event
 *
 * @param name Parameter name
 * @param value Parameter value is string
 */
- (void)addLogParameterWithName:(NSString *)name value:(NSString *)value;

/** \brief Method for adding exception parameter to tracker event
 *
 * @param name Parameter name
 * @param value Parameter value is string
 */
- (void)addErrorParameterWithName:(NSString *)name value:(NSString *)value;

/** \brief Number of parameters of the tracker event
 */
- (NSUInteger)parameterCount;

/** \brief Get parameter from the list of parameters of the tracker event
 *
 * \param index index of parameter
 */
- (STATREventParameter *)parameterAtIndex:(NSUInteger)index;

@end

/**  STATREventAppStart
 *	\brief Interface of app start event
 */
@interface STATREventAppStart : STATREvent

- (id)initWithAppStartDate:(NSDate *)appStartDate parameters:(STATRInitParameters *)initParameters;

@end

/**  STATREventAppFinish
 *	\brief Interface of app finish event
 */
@interface STATREventAppFinish : STATREvent

- (id)initWithAppStartDate:(NSDate *)appStartDate finishDate:(NSDate *)appFinishDate;

@end

/**  STATREventAppFailure
 *	\brief Interface of app failure event
 */
@interface STATREventAppFailure : STATREvent

- (id)initWithAppStartDate:(NSDate *)appStartDate failureDate:(NSDate *)appFailureDate;

@end

/**  STATREventWindowActivation
 *	\brief Interface of window activation event
 */
@interface STATREventWindowActivation : STATREvent

/**  Initializer
 *	\brief windowName Name of window
 *	\brief parentWindowName Name of parent window
 */
- (id)initWithWindowName:(NSString *)windowName parentWindowName:(NSString *) parentWindowName;

/**  Initializer
 *	\brief viewController View controller
 */
- (id)initWithViewController:(UIViewController *)viewController;

@end

/**  STATREventWindowDeactivation
 *	\brief Interface of window deactivation event
 */
@interface STATREventWindowDeactivation : STATREvent

/**  Initializer
 *	\brief windowName Name of window
 *	\brief parentWindowName Name of parent window
 */
- (id)initWithWindowName:(NSString *)windowName parentWindowName:(NSString *)parentWindowName;

@end


/** \class STATREventFPS
 *	\brief Interface of FPS event
 */
@interface STATREventFPS : STATREvent

/**  Initializer of FPS event
 *	\brief minFPS Minimum value of FPS for scene
 *	\brief maxFPS Maximum value of FPS for scene
 *	\brief windowName Name of current window
 *	\brief parentWindowName Name of current parent window 
 */
- (id)initWithMinFPS:(NSInteger)minFPS
              maxFPS:(NSInteger)maxFPS
          windowName:(NSString *)windowName
    parentWindowName:(NSString *)parentWindowName;

@end

/** \class STATREventUserProfile
 *	\brief Interface of user profile event
 */
@interface STATREventUserProfile : STATREvent

/**  Initializer of user profile event with birthday and gender
 *	\brief birthday User birthday
 *	\brief gender User gender (male or female)
 */
- (id)initWithBirthday:(NSDate*)birthday
                gender:(NSString*)gender;

/**  Initializer of user profile event with age and gender
 *	\brief age User age
 *	\brief gender User gender (male or female)
 */
- (id)initWithAge:(NSInteger)age
           gender:(NSString*)gender;

@end

/** \class STATREventInAppPurchase
 *	\brief Interface of in-app purchase event
 */
@interface STATREventInAppPurchase : STATREvent

/**  Initializer of in-app purchase event
 *	\brief purchaseName Purchase name
 *	\brief purchaseType Purchase type
 *	\brief purchaseCost Purchase cost
 *	\brief purchaseState Purchase state
 *	\brief date Purchase date
 *	\brief purchaseMarket Purchase market
 */
- (id) initWithPurchaseName:(NSString*)purchaseName
                       type:(NSInteger)purchaseType
                       cost:(float)purchaseCost
                      state:(NSInteger)purchaseState
                     userID:(NSString*)userID
                       date:(NSDate*)date
                     market:(NSString*)purchaseMarket;

@end


/** \class STATRManager
 *	\brief Interface of STATR manager
 */
@interface STATRManager : NSObject

/** \brief Get shared instance of STATRManager
 * Note that you must set initial parameters with setInitialManagerParameters: method before using the instance
 *
 */
+ (STATRManager *)sharedManager;

/** \brief Set initial parameters for STATRManager
 *
 * \param initialParameters parameters for STATRManager
 */
- (void)setInitialManagerParameters:(STATRInitParameters *)initialParameters;

/** \brief This method tells tracker to start collecting data.
 *
 */
- (void)appStart;

/** \brief This method tells tracker to finish collecting data.
 *
 */
- (void)appFinish;

/** \brief This method adds statistics event on view appear.
 *
 */
- (void)trackViewAppearOfViewController:(UIViewController *)viewController;

/** \brief This method adds statistics event on view disappear.
 *
 */
- (void)trackViewDisappearOfViewController:(UIViewController *)viewController;

/** \brief Add a new tracker event.
 *
 * @param event Object of STATREvent.
 * An instance of STATREvent must be created manually.
 */
- (void)addCustomEvent:(STATREvent *)event;

/** \brief Enable sending statictics data over cellular network.
 * Default is YES.
 */
@property (nonatomic) BOOL isEnabledDataSendingOverCellularNetwork;

/** \brief Enable automatically send statistics data.
 * Default is YES.
 */
@property (nonatomic) BOOL isEnabledAutomaticDataSending;

/** \brief Send statistics data manually if automatic sending is disabled.
 */
- (void)sendDataManually;

/**  Additional enums.
 * \enum Gender
 * \brief For user profile event
 *
 */
enum Gender
{
    Gender_male,
    Gender_female
};

/**  \enum PurchaseType
 * \brief For in-App purchase
 */
enum PurchaseType
{
    PurchaseType_Consumables,
    PurchaseType_NonConsumables,
    PurchaseType_Subscription
};
/**  \enum PurchaseState
 * \brief For in-App purchase
 */
enum PurchaseState
{
    PurchaseState_Purchased,
    PurchaseState_Restored,
    PurchaseState_Failed
};

/** \brief Log data about user: birthday and gender
 * @param birthday Birthday of current user
 * @param gender Gender of current user
 * @param eventTime Time of logging this event
 */
-(void) logUserProfileWithBirthday:(NSDate*)birthday gender:(NSInteger)gender;

/** \brief Log data about user: age and gender
 * @param age Age of current user
 * @param gender Gender of current user
 * @param eventTime Time of logging this event
 */
-(void) logUserProfileWithAge:(NSInteger)age gender:(NSInteger)gender;

/** \brief Log FPS value
 * @param FPS One of FPS value for current view
 * @param viewController Current viewController
 */
-(void) logFPS:(NSInteger)FPSValue viewController:(UIViewController*) viewController;

/** \brief Log In-app purchase
*	\brief purchaseName Purchase name
*	\brief purchaseType Purchase type
*	\brief purchaseCost Purchase cost
*	\brief purchaseState Purchase state
*	\brief purchaseMarket Purchase market
*/
-(void) logInAppPurchaseWithName:(NSString*)purchaseName
                            type:(NSInteger)purchaseType
                            cost:(float)purchaseCost
                           state:(NSInteger)purchaseState
                          userID:(NSString*)userID
                          market:(NSString*)purchaseMarket;

@end

/** \class STATRViewController
 *	\brief UIViewController with added tracking calls in viewDidAppear and viewDidDisappear methods
 */
@interface STATRViewController : UIViewController

@end

/** \class STATRTableViewController
 *	\brief UITableViewController with added tracking calls in viewDidAppear and viewDidDisappear methods
 */
@interface STATRTableViewController : UITableViewController

@end

