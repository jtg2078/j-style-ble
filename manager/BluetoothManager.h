//
//  BluetoothManager.h
//  bluetooth
//
//  Created by jason on 4/4/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BluetoothManager : NSObject

+ (BluetoothManager *)sharedInstance;

@property (nonatomic, strong) CBCentralManager *cbcManager;

@end
