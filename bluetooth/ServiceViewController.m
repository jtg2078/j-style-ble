//
//  ServiceViewController.m
//  bluetooth
//
//  Created by jason on 4/4/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import "ServiceViewController.h"

@interface ServiceViewController () <CBPeripheralDelegate>
@property (nonatomic, strong) CBService *service;
@property (nonatomic, strong) CBPeripheral *device;
@property (nonatomic, strong) NSArray *characteristics;
@end

@implementation ServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype)initWithService:(CBService *)service device:(CBPeripheral *)device
{
    self = [super init];
    if (self) {
        self.service = service;
        self.device = device;
    }
    return self;
}

#pragma mark - memory management

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
    // -------------------- view related --------------------
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // -------------------- device related --------------------
    
    self.device.delegate = self;
    
    [self.device discoverCharacteristics:nil forService:self.service];
    
    [SVProgressHUD showWithStatus:@"Getting Characteristics..."
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
    return [self.characteristics count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CharacteristicTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:CellIdentifier];
    }
    
    [self configureScheduleCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureScheduleCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBCharacteristic *characteristic = self.characteristics[indexPath.row];
    
    cell.textLabel.text = [characteristic description];
    
    NSLog(@"%@", [characteristic description]);
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [SVProgressHUD showWithStatus:@"Reading..." maskType:SVProgressHUDMaskTypeGradient];
    CBCharacteristic *characteristic = self.characteristics[indexPath.row];
    [self.device readValueForCharacteristic:characteristic];
    
    
    [self.device discoverDescriptorsForCharacteristic:characteristic];
}

#pragma mark - CBPeripheralDelegate
#pragma mark - Discovering Characteristics and Characteristic Descriptors

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    self.characteristics = service.characteristics;
    [self.characteristicTableView reloadData];
    [SVProgressHUD dismiss];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    for(CBDescriptor *descriptor in characteristic.descriptors)
    {
        [self.device readValueForDescriptor:descriptor];
    }
}

#pragma mark - Retrieving Characteristic and Characteristic Descriptor Values

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [SVProgressHUD dismiss];
    
    NSData *data = characteristic.value;
    
    NSLog(@"%@", [data description]);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    NSLog(@"%@", [descriptor description]);
}

@end
