//
//  StatrIOS-InitialVC.h
//  StatrIOSTestProject
//
//  Copyright (c) 2013 STATR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STATR.h"

// inherit from class "STATRViewController" to track transitions between views
@interface StatrIOS_InitialVC : STATRViewController

// ------------ Button handlers -----------------
- (IBAction)ButtonCEStringViewHandler:(UIButton *)sender forEvent:(UIEvent *)event;
- (IBAction)ButtonCESIntegerViewHandler:(UIButton *)sender forEvent:(UIEvent *)event;
- (IBAction)ButtonCELogViewHandler:(UIButton *)sender forEvent:(UIEvent *)event;
- (IBAction)ButtonCEErrorViewHandler:(UIButton *)sender forEvent:(UIEvent *)event;
- (IBAction)ButtonCELicenseViewHandler:(UIButton *)sender forEvent:(UIEvent *)event;

// ------ outlet to logo Image View
@property (strong, nonatomic) IBOutlet UIImageView *LogoImageView;

// Image which will contain user touches
@property (strong, nonatomic) UIImageView *imageToDraw;

@end
