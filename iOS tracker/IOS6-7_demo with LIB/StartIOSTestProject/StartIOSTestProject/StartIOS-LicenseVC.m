//
//  StatrIOS-LicenseVC.m
//  StatrIOSTestProject
//
//  Copyright (c) 2013 STATR. All rights reserved.
//

#import "StatrIOS-LicenseVC.h"
#import "StatrIOS-AppDelegate.h"

@interface StatrIOS_LicenseVC ()

@end

@implementation StatrIOS_LicenseVC

/**********************************************************************************************************
                                    event : "viewWillAppear"
 *********************************************************************************************************/
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    
    // Only for iOS7 change cell edge (because on iOS6 cells in table will be with offset)
#ifdef IOS7_SDK
    self.tableWithVendorTypes.separatorInset = UIEdgeInsetsZero;
#endif
    // read last product package
    NSString *lastPackage = [[NSUserDefaults standardUserDefaults] objectForKey:@"product_package"];

    if([lastPackage isEqualToString:@"Free"]){
        
        [self.CellFree setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else if([lastPackage isEqualToString:@"Paid"]){
        
        [self.CellPaid setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else if([lastPackage isEqualToString:@"Demo"]){

        [self.CellDemo setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
}
/**********************************************************************************************************
                        UITableView event : "tableView didSelectRowAtIndexPath"
 *********************************************************************************************************/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // checking selected cell (package)
    if(indexPath.row == 0){
        
        // set chech mark on Free
        [self.CellFree setAccessoryType:UITableViewCellAccessoryCheckmark];
        [self.CellPaid setAccessoryType:UITableViewCellAccessoryNone];
        [self.CellDemo setAccessoryType:UITableViewCellAccessoryNone];
        
        [[NSUserDefaults standardUserDefaults] setObject:@"Free"
                                                  forKey:@"product_package"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if(indexPath.row == 1){
        
        // set chech mark on Paid
        [self.CellFree setAccessoryType:UITableViewCellAccessoryNone];
        [self.CellPaid setAccessoryType:UITableViewCellAccessoryCheckmark];
        [self.CellDemo setAccessoryType:UITableViewCellAccessoryNone];
        
        [[NSUserDefaults standardUserDefaults] setObject:@"Paid"
                                                  forKey:@"product_package"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else{
        // set chech mark on Demo
        [self.CellFree setAccessoryType:UITableViewCellAccessoryNone];
        [self.CellPaid setAccessoryType:UITableViewCellAccessoryNone];
        [self.CellDemo setAccessoryType:UITableViewCellAccessoryCheckmark];
        
        [[NSUserDefaults standardUserDefaults] setObject:@"Demo"
                                                  forKey:@"product_package"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
@end
