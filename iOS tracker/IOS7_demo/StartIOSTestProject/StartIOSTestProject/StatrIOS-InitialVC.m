//
//  StatrIOS-InitialVC.m
//  StatrIOSTestProject
//
//  Copyright (c) 2013 STATR. All rights reserved.
//

#import "StatrIOS-InitialVC.h"

@interface StatrIOS_InitialVC ()

@end

@implementation StatrIOS_InitialVC

/**********************************************************************************************************
                                        event : "viewDidAppear"
 *********************************************************************************************************/
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    
    // load logo
    self.LogoImageView.image = [UIImage imageNamed:@"logo.png"];

    // Initialize image to draw
    if(!self.imageToDraw){
        
        self.imageToDraw = [[UIImageView alloc] initWithFrame:self.view.frame];
        [self.view addSubview:self.imageToDraw];
        [self.imageToDraw setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    }
    
    // Log user profile information
    [[STATRManager sharedManager] logUserProfileWithAge:22 gender:Gender_male];
    // or
    NSDateFormatter *dateForm = [[NSDateFormatter alloc] init];
    [dateForm setDateFormat:@"yyyy'-'MM'-'dd"];
    NSDate *birthday = [dateForm dateFromString:@"1985-06-18"];
    [[STATRManager sharedManager] logUserProfileWithBirthday:birthday gender:Gender_female];
    
    // Add in-app purchase event
    [[STATRManager sharedManager] logInAppPurchaseWithName:@"fire"
                                                      type:PurchaseType_Consumables
                                                      cost:0.99f
                                                     state:PurchaseState_Failed
                                                    userID:@"nexus-one"
                                                    market:@"AppStrore"];
    
    // Log some FPS values (as example)
    [[STATRManager sharedManager] logFPS:13 viewController:self];
    [[STATRManager sharedManager] logFPS:4 viewController:self];
    [[STATRManager sharedManager] logFPS:30 viewController:self];
    
    NSLog(@"<<<< date NOW >>>> = %@", [NSDate date]);
}
/**********************************************************************************************************
                                Button handler : "ButtonCEStringViewHandler"
 *********************************************************************************************************/
- (IBAction)ButtonCEStringViewHandler:(UIButton *)sender forEvent:(UIEvent *)event
{
    // Initialization of custom event (for building heat-map create custom event with Event parameter)
    STATREvent *yourCustomStringEvent = [[STATREvent alloc] initWithName:@"UI Button"
                                                                    date:[NSDate date]
                                                                   event:event
                                                          viewController:self];
    // Add string parameter to custom event
    [yourCustomStringEvent addTextParameterWithName:@"view open"
                                              value:@"CE String View"];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomStringEvent];
}
/**********************************************************************************************************
                                Button handler : "ButtonCESIntegerViewHandler"
 *********************************************************************************************************/
- (IBAction)ButtonCESIntegerViewHandler:(UIButton *)sender forEvent:(UIEvent *)event
{
    // Initialization of custom event
    STATREvent *yourCustomStringEvent = [[STATREvent alloc] initWithName:@"UI Button"
                                                                    date:[NSDate date]
                                                                   event:event
                                                          viewController:self];
    // Add string parameter to custom event
    [yourCustomStringEvent addTextParameterWithName:@"view open"
                                              value:@"CE Integer View"];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomStringEvent];
}
/**********************************************************************************************************
                                Button handler : "ButtonCELogViewHandler"
 *********************************************************************************************************/
- (IBAction)ButtonCELogViewHandler:(UIButton *)sender forEvent:(UIEvent *)event
{
    // Initialization of custom event
    STATREvent *yourCustomStringEvent = [[STATREvent alloc] initWithName:@"UI Button"
                                                                    date:[NSDate date]
                                                                   event:event
                                                          viewController:self];
    // Add string parameter to custom event
    [yourCustomStringEvent addTextParameterWithName:@"view open"
                                              value:@"CE Log View"];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomStringEvent];
}
/**********************************************************************************************************
                                Button handler : "ButtonCEErrorViewHandler"
 *********************************************************************************************************/
- (IBAction)ButtonCEErrorViewHandler:(UIButton *)sender forEvent:(UIEvent *)event
{
    // Initialization of custom event
    STATREvent *yourCustomErrorEvent = [[STATREvent alloc] initWithName:@"UI Button"
                                                                   date:[NSDate date]
                                                                  event:event
                                                         viewController:self];
    // Add string parameter to custom event
    [yourCustomErrorEvent addTextParameterWithName:@"view open"
                                              value:@"CE Error View"];
    [[STATRManager sharedManager] addCustomEvent:yourCustomErrorEvent];
}
/**********************************************************************************************************
                                Button handler : "ButtonCELicenseViewHandler"
 *********************************************************************************************************/
- (IBAction)ButtonCELicenseViewHandler:(UIButton *)sender forEvent:(UIEvent *)event
{
    // Also you can build heat-map by creating event with CGpoint position (for example - some object position)
    
    // Initialization of custom event
    STATREvent *yourCustomLicenseEvent = [[STATREvent alloc] initWithName:@"UI Button"
                                                                     date:[NSDate date]
                                                                    point:sender.center
                                                           viewController:self];
    // Add string parameter to custom event
    [yourCustomLicenseEvent addTextParameterWithName:@"view open"
                                               value:@"CE License View"];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomLicenseEvent];
}

/**********************************************************************************************************
                                Touch handler : "touchesBegan"
 *********************************************************************************************************/
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    [super touchesBegan:touches withEvent:event];
    
    // Initialization of custom event
    STATREvent *yourCustomIntEvent = [[STATREvent alloc] initWithName:@"Touch began"
                                                                 date:[NSDate date]
                                                                event:event
                                                       viewController:self];
    // Add error parameter to custom event
    [yourCustomIntEvent addTextParameterWithName:@"User touch"
                                           value:@"CE Initial View"];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomIntEvent];
    
    // refresh image to draw
    [self.imageToDraw setAlpha:1.0f];
    
    UIGraphicsBeginImageContextWithOptions(
                                           self.view.bounds.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 1.0);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {1.0, 1.0, 1.0, 0.5f};
    CGColorRef color = CGColorCreate(colorspace, components);
    CGContextSetStrokeColorWithColor(context, color);
    
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchPosition = [touch locationInView:self.view];
    
    CGContextAddEllipseInRect(context, CGRectMake(touchPosition.x - 25, touchPosition.y - 25, 50, 50));
    
    UIColor *alphaWhite = [UIColor colorWithWhite:1.0 alpha:0.4f];
    CGContextSetFillColor(context, CGColorGetComponents(alphaWhite.CGColor));
    CGContextFillPath(context);
    
    [self.imageToDraw setImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.imageToDraw setAlpha:0];
                     }];
}


@end
