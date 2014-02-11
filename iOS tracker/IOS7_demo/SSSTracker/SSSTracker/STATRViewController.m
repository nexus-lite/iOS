//
//  STATRViewController.m
//  SSSTracker
//
//  Created by Yuriy Pavlyshak on 09.10.13.
//
//

#import "STATR.h"


@implementation STATRViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[STATRManager sharedManager] trackViewAppearOfViewController:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[STATRManager sharedManager] trackViewDisappearOfViewController:self];
}

@end


@implementation STATRTableViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[STATRManager sharedManager] trackViewAppearOfViewController:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[STATRManager sharedManager] trackViewDisappearOfViewController:self];
}

@end