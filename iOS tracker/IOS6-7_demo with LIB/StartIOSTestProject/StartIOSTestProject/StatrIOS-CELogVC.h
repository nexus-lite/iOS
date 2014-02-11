//
//  StatrIOS-CELogVC.h
//  StatrIOSTestProject
//
//  Copyright (c) 2013 STATR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STATR.h"

// inherit from class "STATRViewController" to track transitions between views
@interface StatrIOS_CELogVC : STATRViewController

// ------------ Button handler -----------------
- (IBAction)AddCustomLogEventButtonHandler:(UIButton *)sender
                                  forEvent:(UIEvent *)event;
// outlets to user entered name and value of custom event
@property (strong, nonatomic) IBOutlet UITextField *textEditWithName;
@property (strong, nonatomic) IBOutlet UITextField *textEditWithValue;

// Image which will contain user touches
@property (strong, nonatomic) UIImageView *imageToDraw;

@end
