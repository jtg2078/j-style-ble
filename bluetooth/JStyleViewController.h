//
//  JStyleViewController.h
//  bluetooth
//
//  Created by jason on 4/9/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JStyleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithDevice:(CBPeripheral *)device;

@property (weak, nonatomic) IBOutlet UITableView *optionTableView;

@end
