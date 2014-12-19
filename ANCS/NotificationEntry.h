//
//  NotificationEntry.h
//  ANCS
//
//  Created by Stephen Schiffli on 12/9/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetaWear/MetaWear.h>

@interface NotificationEntry : NSObject <NSCoding>
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIImage *picture;

- (instancetype)initWithName:(NSString *)name color:(UIColor *)color picture:(UIImage *)picture;

- (void)programToDevice:(MBLMetaWear *)device;
- (void)eraseFromDevice:(MBLMetaWear *)device;
@end
