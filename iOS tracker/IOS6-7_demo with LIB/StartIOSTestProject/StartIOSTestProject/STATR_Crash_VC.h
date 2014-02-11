//
//  STATR_Crash_VC.h
//  iOS6_DEMO
//
//  Copyright (c) 2013 STATR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STATR.h"

// inherit from class "STATRViewController" to track transitions between views
@interface STATR_Crash_VC : STATRViewController

// ------------ Button handler -----------------
- (IBAction)makeCrash:(UIButton *)sender forEvent:(UIEvent *)event;

// Image which will contain user touches
@property (strong, nonatomic) UIImageView *imageToDraw;

@end
