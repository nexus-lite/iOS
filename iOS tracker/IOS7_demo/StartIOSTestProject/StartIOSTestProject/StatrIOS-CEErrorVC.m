//
//  StatrIOS-CEErrorVC.m
//  StatrIOSTestProject
//
//  Copyright (c) 2013 STATR. All rights reserved.
//

#import "StatrIOS-CEErrorVC.h"

@interface StatrIOS_CEErrorVC()

@end

@implementation StatrIOS_CEErrorVC

/**********************************************************************************************************
                                        event : "viewDidAppear"
 *********************************************************************************************************/
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    
    // Initialize image to draw
    if(!self.imageToDraw){
        
        self.imageToDraw = [[UIImageView alloc] initWithFrame:self.view.frame];
        [self.view addSubview:self.imageToDraw];
        [self.imageToDraw setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    }
    
    // Log some FPS values (as example)
    [[STATRManager sharedManager] logFPS:10 viewController:self];
    [[STATRManager sharedManager] logFPS:15 viewController:self];
    [[STATRManager sharedManager] logFPS:25 viewController:self];
}
/**********************************************************************************************************
                            Button handler : "AddCustomErrorEventButtonHandler"
 *********************************************************************************************************/
- (IBAction)AddCustomErrorEventButtonHandler:(UIButton *)sender forEvent:(UIEvent *)event
{
    // Initialization of custom event
    STATREvent *yourCustomErrorEvent = [[STATREvent alloc] initWithName:@"Sent Button"
                                                                 date:[NSDate date]
                                                                event:event
                                                       viewController:self];
    // Add error parameter to custom event
    [yourCustomErrorEvent addErrorParameterWithName:self.textEditWithName.text
                                              value:self.textEditWithValue.text];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomErrorEvent];
}
/**********************************************************************************************************
                            Button handler : "ShowCrashViewButtonHandler"
 *********************************************************************************************************/
- (IBAction)ShowCrashViewButtonHandler:(UIButton *)sender forEvent:(UIEvent *)event
{
    // Initialization of custom event
    STATREvent *yourCustomEvent = [[STATREvent alloc] initWithName:@"UI Button"
                                                                   date:[NSDate date]
                                                                  event:event
                                                         viewController:self];
    // Add text parameter to custom event
    [yourCustomEvent addTextParameterWithName:@"view open"
                                        value:@"Crash view"];
    // Add your custom event to STATR tracker
    [[STATRManager sharedManager] addCustomEvent:yourCustomEvent];
}
/**********************************************************************************************************
                                    Touch handler : "touchesBegan"
 *********************************************************************************************************/
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    [super touchesBegan:touches withEvent:event];
    
    // close keyboard
    [self.textEditWithName resignFirstResponder];
    [self.textEditWithValue resignFirstResponder];
    
    // Initialization of custom event
    STATREvent *yourCustomIntEvent = [[STATREvent alloc] initWithName:@"Touch began"
                                                                 date:[NSDate date]
                                                                event:event
                                                       viewController:self];
    // Add error parameter to custom event
    [yourCustomIntEvent addTextParameterWithName:@"User touch"
                                           value:@"CE Error View"];
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
