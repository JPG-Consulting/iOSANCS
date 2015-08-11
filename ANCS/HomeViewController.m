/**
 * HomeViewController.m
 * ANCS
 *
 * Created by Stephen Schiffli on 12/9/14.
 * Copyright 2014-2015 MbientLab Inc. All rights reserved.
 *
 * IMPORTANT: Your use of this Software is limited to those specific rights
 * granted under the terms of a software license agreement between the user who
 * downloaded the software, his/her employer (which must be your employer) and
 * MbientLab Inc, (the "License").  You may not use this Software unless you
 * agree to abide by the terms of the License which can be found at
 * www.mbientlab.com/terms.  The License limits your use, and you acknowledge,
 * that the Software may be modified, copied, and distributed when used in
 * conjunction with an MbientLab Inc, product.  Other than for the foregoing
 * purpose, you may not use, reproduce, copy, prepare derivative works of,
 * modify, distribute, perform, display or sell this Software and/or its
 * documentation for any purpose.
 *
 * YOU FURTHER ACKNOWLEDGE AND AGREE THAT THE SOFTWARE AND DOCUMENTATION ARE
 * PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY, TITLE,
 * NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL
 * MBIENTLAB OR ITS LICENSORS BE LIABLE OR OBLIGATED UNDER CONTRACT, NEGLIGENCE,
 * STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR OTHER LEGAL EQUITABLE
 * THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES INCLUDING BUT NOT LIMITED
 * TO ANY INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR CONSEQUENTIAL DAMAGES, LOST
 * PROFITS OR LOST DATA, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY,
 * SERVICES, OR ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY
 * DEFENSE THEREOF), OR OTHER SIMILAR COSTS.
 *
 * Should you have any questions regarding your right to use this Software,
 * contact MbientLab via email: hello@mbientlab.com
 */

#import "HomeViewController.h"
#import "NotificationViewController.h"
#import "ScanTableViewController.h"
#import "DeviceSettings.h"
#import "MBProgressHUD.h"
#import <MetaWear/MetaWear.h>

@interface HomeViewController () <NotificationControllerDelegate, ScanTableViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectBarButton;
@property (weak, nonatomic) IBOutlet UILabel *identifierLabel;

@property (nonatomic, strong) MBLMetaWear *device;
@property (nonatomic, strong) DeviceSettings *configuration;
@end

@implementation HomeViewController

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set up navigation bar colors
    self.navigationController.navigationBar.tintColor = ColorNavigationTint;
    self.navigationController.navigationBar.barTintColor = ColorNavigationBarTint;
    self.navigationController.navigationBar.translucent = TRUE;
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:ColorNavigationTitle,NSForegroundColorAttributeName, FontNavigationTitle, NSFontAttributeName, nil]];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [[MBLMetaWearManager sharedManager] retrieveSavedMetaWearsWithHandler:^(NSArray *array) {
        if (array.count) {
            self.device = array[0];
            self.configuration = self.device.configuration;
            self.identifierLabel.text = self.device.identifier.UUIDString;
            self.connectBarButton.title = @"Remove";
        } else {
            self.connectBarButton.title = @"Connect";
            self.identifierLabel.text = @"No MetaWear Paired";
        }
        [self.tableView reloadData];
    }];
}

- (IBAction)connectPressed:(id)sender
{
    if ([self.connectBarButton.title isEqualToString:@"Connect"]) {
        [self performSegueWithIdentifier:@"ShowScanScreen" sender:nil];
    } else {
        MBLMetaWear *device = self.device;
        self.device = nil;
        self.configuration = nil;
        [self.tableView reloadData];
        
        [device connectWithHandler:^(NSError *error) {
            [device deleteAllBonds];
            [device setConfiguration:nil handler:nil];
        }];
        [device forgetDevice];
        
        [[[UIAlertView alloc] initWithTitle:@"Action Required" message:@"Go to Settings->Bluetooth and Forget the MetaWear device to complete removal" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        self.connectBarButton.title = @"Connect";
        self.identifierLabel.text = @"No MetaWear Paired";
    }
}

- (IBAction)refreshPressed:(id)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Programming...";
    
    DeviceSettings *configuration = self.configuration.notifications.count ? self.configuration : nil;
    [self.device connectWithHandler:^(NSError *error) {
        if (error) {
            hud.labelText = error.localizedDescription;
            [hud hide:YES afterDelay:2];
        } else {
            [self.device setConfiguration:configuration handler:^(NSError *error) {
                if (error) {
                    hud.labelText = error.localizedDescription;
                    [hud hide:YES afterDelay:2];
                } else {
                    [hud hide:YES];
                }
            }];
        }
    }];
}

- (void)handleEntry:(NotificationEntry *)entry
{
    [self.tableView reloadData];
    // Program the device!
    [self refreshPressed:nil];
}

- (void)notificationController:(NotificationViewController *)controller didCreateNotification:(NotificationEntry *)entry
{
    [self.configuration.notifications addObject:entry];
    [self handleEntry:entry];
}

- (void)notificationController:(NotificationViewController *)controller didUpdateNotification:(NotificationEntry *)entry
{
    [self handleEntry:entry];
}

- (void)scanTableViewController:(ScanTableViewController *)controller didSelectDevice:(MBLMetaWear *)device
{
    self.device = device;
    self.configuration = device.configuration;
    if (!self.configuration) {
        self.configuration = [[DeviceSettings alloc] init];
    }
    
    self.identifierLabel.text = device.identifier.UUIDString;
    self.connectBarButton.title = @"Remove";
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Notifications";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.configuration.notifications.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.row >= self.configuration.notifications.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"AddNew" forIndexPath:indexPath];
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        if (self.device) {
            label.text = @"+ Add New Notification";
        } else {
            label.text = @"+ Connect MetaWear";
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationEntry" forIndexPath:indexPath];
        NotificationEntry *cur = self.configuration.notifications[indexPath.row];
        
        UIImageView *picture = (UIImageView *)[cell viewWithTag:1];
        [picture setImage:cur.picture];
        
        UILabel *name = (UILabel *)[cell viewWithTag:2];
        name.text = cur.name;
        
        UIView *color = [cell viewWithTag:3];
        color.backgroundColor = cur.color;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row >= self.configuration.notifications.count) {
        if (self.device) {
            [self performSegueWithIdentifier:@"ShowNotification" sender:nil];
        } else {
            [self connectPressed:nil];
        }
    } else {
        NotificationEntry *selected = self.configuration.notifications[indexPath.row];
        [self performSegueWithIdentifier:@"ShowNotification" sender:selected];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return indexPath.row < self.configuration.notifications.count;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.configuration.notifications removeObjectAtIndex:indexPath.row];
        [self refreshPressed:nil];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[NotificationViewController class]]) {
        NotificationViewController *controller = segue.destinationViewController;
        controller.delegate = self;
        controller.entryToDisplay = sender;
    } else if ([segue.destinationViewController isKindOfClass:[ScanTableViewController class]]) {
        ScanTableViewController *controller = segue.destinationViewController;
        controller.delegate = self;
    }
}

@end
