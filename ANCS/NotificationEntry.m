//
//  NotificationEntry.m
//  ANCS
//
//  Created by Stephen Schiffli on 12/9/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "NotificationEntry.h"

@implementation NotificationEntry

- (instancetype)initWithName:(NSString *)name color:(UIColor *)color picture:(UIImage *)picture
{
    self = [super init];
    if (self) {
        self.name = name;
        self.color = color;
        self.picture = picture;
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
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:UIImagePNGRepresentation(self.picture) forKey:@"pic"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.color forKey:@"color"];
}

@end
