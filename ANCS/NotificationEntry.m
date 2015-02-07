//
//  NotificationEntry.m
//  ANCS
//
//  Created by Stephen Schiffli on 12/9/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "NotificationEntry.h"

@interface NotificationEntry ()
@property (nonatomic, strong) NSString *identifier;
@end

@implementation NotificationEntry

- (instancetype)initWithName:(NSString *)name color:(UIColor *)color picture:(UIImage *)picture
{
    self = [super init];
    if (self) {
        self.name = name;
        self.color = color;
        self.picture = picture;
        
        self.identifier = [@"com.mbientlab." stringByAppendingString:name];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.picture = [UIImage imageWithData:[aDecoder decodeObjectForKey:@"pic"]];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.color = [aDecoder decodeObjectForKey:@"color"];
        self.identifier = [aDecoder decodeObjectForKey:@"id"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:UIImagePNGRepresentation(self.picture) forKey:@"pic"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.color forKey:@"color"];
    [aCoder encodeObject:self.identifier forKey:@"id"];
}

- (void)programToDevice:(MBLMetaWear *)device
{
    [device connectWithHandler:^(NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[@"Try again please! " stringByAppendingString:error.localizedDescription] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else {
            MBLEvent *event = [device retrieveEventWithIdentifier:self.identifier];
            if (!event) {
                event = [device.ancs eventWithCategoryIds:MBLANCSCategoryIDAny
                                                 eventIds:MBLANCSEventIDNotificationAdded
                                               eventFlags:MBLANCSEventFlagAny
                                              attributeId:MBLANCSNotificationAttributeIDTitle
                                            attributeData:self.name
                                               identifier:self.identifier];
                
                /*event = [device.ancs eventWithCategoryIds:MBLANCSCategoryIDAny
                                                 eventIds:MBLANCSEventIDNotificationAdded
                                               eventFlags:MBLANCSEventFlagAny
                                              attributeId:MBLANCSNotificationAttributeIDNone
                                            attributeData:nil
                                               identifier:self.identifier];*/
            } else {
                [event eraseCommandsToRunOnEvent];
            }
            
            [event programCommandsToRunOnEvent:^{
                [device.led flashLEDColor:self.color withIntensity:1.0 numberOfFlashes:5];
                [device.hapticBuzzer startHapticWithDutyCycle:255 pulseWidth:500 completion:nil];
            }];
            [device disconnectWithHandler:nil];
        }
    }];
}

- (void)eraseFromDevice:(MBLMetaWear *)device
{
    [device connectWithHandler:^(NSError *error) {
        MBLEvent *event = [device retrieveEventWithIdentifier:self.identifier];
        if (event) {
            [event eraseCommandsToRunOnEvent];
        }
        [device disconnectWithHandler:nil];
    }];
}

@end
