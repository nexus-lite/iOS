//
//  StatrIOS-LicenseVC.h
//  StatrIOSTestProject
//
//  Copyright (c) 2013 STATR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STATR.h"

// inherit from class "STATRTableController" to track transitions between views
@interface StatrIOS_LicenseVC : STATRTableViewController <UITableViewDelegate>

// --- outlets to view and cell ---
@property (strong, nonatomic) IBOutlet UITableView *tableWithVendorTypes;
@property (strong, nonatomic) IBOutlet UITableViewCell *CellFree;
@property (strong, nonatomic) IBOutlet UITableViewCell *CellPaid;
@property (strong, nonatomic) IBOutlet UITableViewCell *CellDemo;

@end
