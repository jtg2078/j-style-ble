//
//  ConnectViewController.m
//  bluetooth
//
//  Created by jason on 4/4/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import "ScanViewController.h"
#import "BluetoothManager.h"
#import "DeviceTableViewCell.h"
#import "ConnectDeviceViewController.h"
#import "JStyleViewController.h"

@interface ScanViewController () <CBCentralManagerDelegate>
@property (nonatomic, weak) BluetoothManager *manager;
@property (nonatomic, strong) NSMutableArray *devices;
@property BOOL isScanning;
@end

@implementation ScanViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    // Do any additional setup after loading the view from its nib.
    
    self.manager = [BluetoothManager sharedInstance];
    
    // -------------------- view related --------------------
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // -------------------- cb related --------------------
    
    self.manager.cbcManager.delegate = self;
    
    // -------------------- device table view --------------------
    
    self.deviceTableView.rowHeight = 240;
    
    [self.deviceTableView registerNib:[UINib nibWithNibName:@"DeviceTableViewCell" bundle:nil] forCellReuseIdentifier:@"DeviceTableViewCell"];
    
}

#pragma mark - user interaction

- (IBAction)scanBtnPressed:(id)sender
{
    if(self.isScanning)
    {
        self.messageLabel.text = @"Press Scan to start";
        [self.scanBtn setTitle:@"Scan" forState:UIControlStateNormal];
        
        [self.manager.cbcManager stopScan];
        
        self.isScanning = NO;
    }
    else
    {
        self.messageLabel.text = @"Scanning....";
        [self.scanBtn setTitle:@"Stop" forState:UIControlStateNormal];
        
        self.devices = [NSMutableArray array];
        [self.deviceTableView reloadData];
        
        [self.manager.cbcManager scanForPeripheralsWithServices:nil options:nil];

        self.isScanning = YES;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DeviceTableViewCell";
    
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [self configureScheduleCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureScheduleCell:(DeviceTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *info = self.devices[indexPath.row];
    
    CBPeripheral *peripheral = info[@"peripheral"];
    NSDictionary *advertisementData = info[@"advertisementData"];
    NSNumber *RSSI = info[@"RSSI"];
    
    cell.deviceNameLabel.text = peripheral.name;
    cell.deviceUUIDLabel.text = [advertisementData description];
    cell.deviceRSSILabel.text = [RSSI stringValue];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *info = self.devices[indexPath.row];
    CBPeripheral *peripheral = info[@"peripheral"];
    
    [self.manager.cbcManager connectPeripheral:peripheral options:nil];
    
    [SVProgressHUD showWithStatus:@"Connecting..." maskType:SVProgressHUDMaskTypeGradient];
}

#pragma mark - CBCentralManagerDelegate

#pragma mark - Monitoring Connections with Peripherals

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [SVProgressHUD dismiss];
    
//    ConnectDeviceViewController *cdvc = [[ConnectDeviceViewController alloc] initWithDevice:peripheral];
//    [self.navigationController pushViewController:cdvc animated:YES];
    
    JStyleViewController *jsvc = [[JStyleViewController alloc] initWithDevice:peripheral];
    [self.navigationController pushViewController:jsvc animated:YES];
    
    [self scanBtnPressed:nil];

    NSLog(@"didConnectPeripheral");
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral");
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didFailToConnectPeripheral");
}

#pragma mark - Discovering and Retrieving Peripherals

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    if(self.isScanning)
    {
        NSDictionary *result = @{@"peripheral": peripheral,
                                 @"advertisementData": advertisementData,
                                 @"RSSI": RSSI};
        
        [self.devices addObject:result];
        [self.deviceTableView reloadData];
    }
    
    NSLog(@"didDiscoverPeripheral: %@", peripheral.name);
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    NSLog(@"didRetrieveConnectedPeripherals");
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"didRetrievePeripherals");
}

#pragma mark - Monitoring Changes to the Central Manager’s State

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState");
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    NSLog(@"willRestoreState");
}

@end
