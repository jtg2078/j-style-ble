//
//  ConnectDeviceViewController.m
//  bluetooth
//
//  Created by jason on 4/4/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import "ConnectDeviceViewController.h"
#import "ServiceViewController.h"

@interface ConnectDeviceViewController () <CBPeripheralDelegate>
@property (nonatomic, strong) CBPeripheral *device;
@property (nonatomic, strong) NSArray *services;
@end

@implementation ConnectDeviceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype)initWithDevice:(CBPeripheral *)device
{
    self = [super init];
    if (self) {
        self.device = device;
    }
    return self;
}

#pragma mark - memeory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // -------------------- view related --------------------
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // -------------------- device related --------------------
    
    self.device.delegate = self;
    
    [self.device discoverServices:nil];
    
    [SVProgressHUD showWithStatus:@"Discovering Services..."
                         maskType:SVProgressHUDMaskTypeGradient];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.device.delegate = self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.services count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ServiceTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:CellIdentifier];
    }
    
    [self configureScheduleCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureScheduleCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBService *service = self.services[indexPath.row];
    
    cell.textLabel.text = [service description];
    
    NSLog(@"%@", [service description]);
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CBService *service = self.services[indexPath.row];
    
    ServiceViewController *svc = [[ServiceViewController alloc] initWithService:service
                                                                         device:self.device];
    
    [self.navigationController pushViewController:svc animated:YES];
}

#pragma mark - CBPeripheralDelegate
#pragma mark - Discovering Services

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    [SVProgressHUD dismiss];
    
    self.services = peripheral.services;
    [self.serviceTableView reloadData];
}

@end
