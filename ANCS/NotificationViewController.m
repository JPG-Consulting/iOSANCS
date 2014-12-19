//
//  NotificationViewController.m
//  ANCS
//
//  Created by Stephen Schiffli on 12/8/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

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
    NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
    NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName == nil ? @"" : firstName, lastName == nil ? @"" : lastName];
    
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
