//
//  ServiceViewController.h
//  bluetooth
//
//  Created by jason on 4/4/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServiceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *characteristicTableView;

- (instancetype)initWithService:(CBService *)service device:(CBPeripheral *)device;


@end
