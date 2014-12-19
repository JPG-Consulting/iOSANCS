//
//  NotificationViewController.h
//  ANCS
//
//  Created by Stephen Schiffli on 12/8/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotificationEntry.h"

@protocol NotificationControllerDelegate;

@interface NotificationViewController : UIViewController
@property (nonatomic, assign) id<NotificationControllerDelegate> delegate;
@property (nonatomic, strong) NotificationEntry *entryToDisplay;
@end


@protocol NotificationControllerDelegate <NSObject>
- (void)notificationController:(NotificationViewController *)controller didCreateNotification:(NotificationEntry *)entry;
- (void)notificationController:(NotificationViewController *)controller didUpdateNotification:(NotificationEntry *)entry;
@end