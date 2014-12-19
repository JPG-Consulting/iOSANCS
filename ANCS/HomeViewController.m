//
//  HomeViewController.m
//  ANCS
//
//  Created by Stephen Schiffli on 12/9/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "HomeViewController.h"
#import "NotificationViewController.h"
#import <MetaWear/MetaWear.h>

@interface HomeViewController () <NotificationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectBarButton;
@property (weak, nonatomic) IBOutlet UILabel *identifierLabel;

@property (nonatomic, strong) MBLMetaWear *device;
@property (nonatomic, strong) NSMutableArray *notifications;
@property (nonatomic, strong) NSString *logFilename;
@end

@implementation HomeViewController
@synthesize logFilename = _logFilename;

- (NSString *)logFilename
{
    if (!_logFilename) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if (paths.count) {
            _logFilename = [NSString stringWithFormat:@"%@/logfile", paths[0]];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot find documents directory, logging not supported" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            _logFilename = nil;
        }
    }
    return _logFilename;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load saved values and display
    self.notifications  = [[NSKeyedUnarchiver unarchiveObjectWithFile:self.logFilename] mutableCopy];
    if (!self.notifications) {
        self.notifications = [NSMutableArray array];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateInterface];
}


- (void)updateInterface
{
    [[MBLMetaWearManager sharedManager] retrieveSavedMetaWearsWithHandler:^(NSArray *array) {
        if (array.count) {
            self.device = array[0];
            self.identifierLabel.text = self.device.identifier.UUIDString;
            self.connectBarButton.title = @"Remove";
        } else {
            self.connectBarButton.title = @"Connect";
            self.identifierLabel.text = @"No MetaWear Paired";
        }
        [self.tableView reloadData];
    }];
    [self.tableView reloadData];
}

- (IBAction)connectPressed:(id)sender
{
    if ([self.connectBarButton.title isEqualToString:@"Connect"]) {
        [self performSegueWithIdentifier:@"ShowScanScreen" sender:nil];
    } else {
        MBLMetaWear *device = self.device;
        self.device = nil;
        
        [device connectWithHandler:^(NSError *error) {
            // TODO: Should remove pairing info
            [device resetDevice];
        }];
        [device forgetDevice];
        
        [self updateInterface];
    }
}

- (IBAction)refreshPressed:(id)sender
{
    [self.device connectWithHandler:^(NSError *error) {
        [self.device resetDevice];
        if (self.notifications.count) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.device connectWithHandler:^(NSError *error) {
                    if (!error) {
                        for (NotificationEntry *entry in self.notifications) {
                            [entry programToDevice:self.device];
                        }
                        [self.device disconnectWithHandler:nil];
                    }
                }];
            });
        }
    }];
}

- (void)handleEntry:(NotificationEntry *)entry
{
    [NSKeyedArchiver archiveRootObject:self.notifications toFile:self.logFilename];
    [self.tableView reloadData];
    
    [entry programToDevice:self.device];
}

- (void)notificationController:(NotificationViewController *)controller didCreateNotification:(NotificationEntry *)entry
{
    [self.notifications addObject:entry];
    [self handleEntry:entry];
}

- (void)notificationController:(NotificationViewController *)controller didUpdateNotification:(NotificationEntry *)entry
{
    [self handleEntry:entry];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Notifications";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notifications.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.row >= self.notifications.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"AddNew" forIndexPath:indexPath];
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        if (self.device) {
            label.text = @"+ Add New Notification";
        } else {
            label.text = @"+ Connect MetaWear";
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationEntry" forIndexPath:indexPath];
        NotificationEntry *cur = self.notifications[indexPath.row];
        
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
    if (indexPath.row >= self.notifications.count) {
        if (self.device) {
            [self performSegueWithIdentifier:@"ShowNotification" sender:nil];
        } else {
            [self connectPressed:nil];
        }
    } else {
        NotificationEntry *selected = self.notifications[indexPath.row];
        [self performSegueWithIdentifier:@"ShowNotification" sender:selected];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return indexPath.row < self.notifications.count;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NotificationEntry *cur = self.notifications[indexPath.row];
        [cur eraseFromDevice:self.device];
        
        [self.notifications removeObjectAtIndex:indexPath.row];
        [NSKeyedArchiver archiveRootObject:self.notifications toFile:self.logFilename];
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
    }
}

@end
