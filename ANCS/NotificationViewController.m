/**
 * NotificationViewController.m
 * ANCS
 *
 * Created by Stephen Schiffli on 12/8/14.
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

#import "NotificationViewController.h"
#import "NKOColorPickerView.h"
#import <MetaWear/MetaWear.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface NotificationViewController () <ABPeoplePickerNavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet NKOColorPickerView *colorPickerView;

@property (nonatomic) BOOL createdNotification;
@end

@implementation NotificationViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.entryToDisplay) {
        self.nameLabel.text = self.entryToDisplay.name;
        self.profilePicture.image = self.entryToDisplay.picture;
        self.colorPickerView.color = self.entryToDisplay.color;
        [self.doneButton setEnabled:YES];
    } else {
        self.nameLabel.text = @"Tap To Select Contact";
        self.profilePicture.image = [UIImage imageNamed:@"ClickToAdd"];
        self.colorPickerView.color = [UIColor greenColor];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ihavebeenlaunched"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"ihavebeenlaunched"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[[UIAlertView alloc] initWithTitle:@"Notice" message:@"This app filters notifications by title.  The title is what shows up in bold font above the notification payload when looking at the notification dropdown.  The app makes a best guess as to what those names are for the contanct you select, but display formats are customizable so it can't be guaranteed to work." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (IBAction)donePressed:(id)sender
{
    if (self.entryToDisplay) {
        self.entryToDisplay.name = self.nameLabel.text;
        self.entryToDisplay.picture = self.profilePicture.image;
        self.entryToDisplay.color = self.colorPickerView.color;
        
        if (self.createdNotification) {
            [self.delegate notificationController:self didCreateNotification:self.entryToDisplay];
        } else {
            [self.delegate notificationController:self didUpdateNotification:self.entryToDisplay];
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancelPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)selectPersonPressed:(id)sender
{
    if (!self.entryToDisplay) {
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        if ([picker respondsToSelector:@selector(predicateForSelectionOfPerson)]) {
            picker.predicateForSelectionOfPerson = [NSPredicate predicateWithValue:YES];
        }
        picker.peoplePickerDelegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)addElement:(ABPropertyID)elementId person:(ABRecordRef)person name:(NSMutableString *)name
{
    NSString *element = (__bridge NSString *)(ABRecordCopyValue(person, elementId));
    if (element) {
        if (name.length) {
            [name appendString:@" "];
        }
        [name appendString:element];
    }
}

- (void)selectedPerson:(ABRecordRef)person
{
    if (person == nil) {
        return;
    }
    // Check for contact picture
    UIImage *picture;
    if (ABPersonHasImageData(person)) {
        picture = [UIImage imageWithData:(__bridge NSData *)(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail))];
    } else {
        picture = [UIImage imageNamed:@"BlankProfile"];
    }
    NSString *fullName;
    NSString *nickname = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonNicknameProperty));
    if (nickname) {
        // The default contact display name is to perfer nickname if given
        fullName = nickname;
    } else {
        // Otherwise compose full name from individual names
        NSMutableString *name = [NSMutableString string];
        [self addElement:kABPersonPrefixProperty person:person name:name];
        [self addElement:kABPersonFirstNameProperty person:person name:name];
        [self addElement:kABPersonMiddleNameProperty person:person name:name];
        [self addElement:kABPersonLastNameProperty person:person name:name];
        [self addElement:kABPersonSuffixProperty person:person name:name];
        fullName = name;
    }
    self.entryToDisplay = [[NotificationEntry alloc] initWithName:fullName color:self.colorPickerView.color picture:picture];
    self.createdNotification = YES;
    [self.doneButton setEnabled:YES];
}


- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person
{
    [self selectedPerson:person];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    [self selectedPerson:person];
    [self dismissViewControllerAnimated:YES completion:nil];
    return NO;
}


@end
