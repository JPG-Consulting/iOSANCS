//
//  ScanTableViewController.m
//  ActivityTracker
//
//  Created by Stephen Schiffli on 10/16/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "ScanTableViewController.h"
#import <MetaWear/MetaWear.h>
#import "MBProgressHUD.h"
#import "DeviceSettings.h"

@interface ScanTableViewController ()
@property (nonatomic, strong) NSArray *devices;
@property (nonatomic, strong) MBLMetaWear *selected;
@end

@implementation ScanTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[MBLMetaWearManager sharedManager] startScanForMetaWearsAllowDuplicates:YES handler:^(NSArray *array) {
        self.devices = array;
        [self.tableView reloadData];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[MBLMetaWearManager sharedManager] stopScanForMetaWears];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MetaWearCell" forIndexPath:indexPath];
   
    MBLMetaWear *cur = self.devices[indexPath.row];
    
    UILabel *uuid = (UILabel *)[cell viewWithTag:1];
    uuid.text = cur.identifier.UUIDString;
    
    UILabel *rssi = (UILabel *)[cell viewWithTag:2];
    rssi.text = [cur.discoveryTimeRSSI stringValue];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Connecting...";
    
    self.selected = self.devices[indexPath.row];
    [self.selected connectWithHandler:^(NSError *error) {
        if (!error) {
            [self.selected.led flashLEDColor:[UIColor greenColor] withIntensity:0.75];
            [hud hide:YES];
            [[[UIAlertView alloc] initWithTitle:@"Confirm Device"
                                        message:@"Do you see a blinking green LED on the MetaWear?"
                                       delegate:self
                              cancelButtonTitle:@"No"
                              otherButtonTitles:@"Yes!", nil] show];
        } else {
            hud.labelText = error.localizedDescription;
            [hud hide:YES afterDelay:2];
        }
    }];
}

#pragma mark - Alert View delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.selected.led setLEDOn:NO withOptions:1];
    if (buttonIndex == 1) {
        if (!self.selected.ancs) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:@"This MetaWear does not have ANCS enabled"
                                       delegate:nil
                              cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil] show];
            [self.selected disconnectWithHandler:nil];
            return;
        }
        
        [self.selected rememberDevice];
        if (self.delegate) {
            [self.delegate scanTableViewController:self didSelectDevice:self.selected];
        }
        
        [self.selected initiatePairing];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.selected disconnectWithHandler:nil];
            [self.navigationController popViewControllerAnimated:YES];
        });
    } else {
        [self.selected disconnectWithHandler:nil];
    }
}

@end
