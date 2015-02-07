//
//  ScanTableViewController.h
//  ActivityTracker
//
//  Created by Stephen Schiffli on 10/16/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetaWear/MetaWear.h>

@protocol ScanTableViewControllerDelegate;

@interface ScanTableViewController : UITableViewController
@property (nonatomic, assign) id<ScanTableViewControllerDelegate> delegate;
@end


@protocol ScanTableViewControllerDelegate <NSObject>
- (void)scanTableViewController:(ScanTableViewController *)controller didSelectDevice:(MBLMetaWear *)device;
@end