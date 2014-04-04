//
//  BluetoothManager.m
//  bluetooth
//
//  Created by jason on 4/4/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import "BluetoothManager.h"

@interface BluetoothManager ()

@end

@implementation BluetoothManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    // using main queue for now
    self.cbcManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
}

#pragma mark - main methods


#pragma mark - singleton implementation code

+ (instancetype)sharedInstance {
    static BluetoothManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

@end
