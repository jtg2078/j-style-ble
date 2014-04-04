//
//  BaseViewController.h
//  bluetooth
//
//  Created by jason on 4/4/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BluetoothManager.h"

@interface BaseViewController : UIViewController
@property (nonatomic, weak) BluetoothManager *manager;
@end
