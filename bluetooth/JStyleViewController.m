//
//  JStyleViewController.m
//  bluetooth
//
//  Created by jason on 4/9/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import "JStyleViewController.h"
#import "NSData+Hex.h"
#import "NSString+Hex.h"

@interface JStyleViewController () <CBPeripheralDelegate>
@property (nonatomic, strong) NSArray *options;
@property (nonatomic, strong) CBPeripheral *device;


@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBUUID *txUUID;
@property (nonatomic, strong) CBUUID *rxUUID;

@property (nonatomic, strong) CBService *service;
@property (nonatomic, strong) CBCharacteristic *txCharacteristic;
@property (nonatomic, strong) CBCharacteristic *rxCharacteristic;

@property (assign) BOOL isSubscribing;


@end

@implementation JStyleViewController

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
    
    // -------------------- options related --------------------
    
    self.options = @[@"查看目前時間",
                     @"查看個人資料"];
    
    // -------------------- bt related --------------------
    
    [SVProgressHUD showWithStatus:@"起始中..." maskType:SVProgressHUDMaskTypeGradient];
    
    [self connectToTargetService];
}

#pragma mark - bt related

- (void)connectToTargetService
{
    // service
    self.serviceUUID = [CBUUID UUIDWithString:@"FFF0"];
    
    // get the intended service
    self.device.delegate = self;
    [self.device discoverServices:@[self.serviceUUID]];
}

- (void)establishConnectionChannel
{
    // transmission channel (TX)
    self.txUUID = [CBUUID UUIDWithString:@"FFF6"];
    
    // receiving channel (RX)
    self.rxUUID = [CBUUID UUIDWithString:@"FFF7"];
    
    // connect to the tx/rx characteristics
    [self.device discoverCharacteristics:@[self.txUUID, self.rxUUID]
                              forService:self.service];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.options count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"OptionTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    
    [self configureScheduleCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureScheduleCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *optionName = self.options[indexPath.row];
    
    cell.textLabel.text = optionName;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
            [self showCurrentTime];
            break;
        case 1:
            [self showPersonalSetting];
            break;
            
        default:
            break;
    }
    
}

#pragma mark - options

- (void)executeOption:(char)ops
{
    [SVProgressHUD showWithStatus:@"讀取中..." maskType:SVProgressHUDMaskTypeGradient];
    
    // from the J-Style spec, the write will not be directly responded
    // any result be will streaming back via notification
    const char command[] = {
        ops,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,ops };
    
    NSData *data = [NSData dataWithBytes:command length:16];
    
    [self.device writeValue:data
          forCharacteristic:self.txCharacteristic
                       type:CBCharacteristicWriteWithResponse];
}

- (void)showCurrentTime
{
    [self executeOption:0x41];
}

- (void)showPersonalSetting
{
    [self executeOption:0x42];
}

#pragma mark - CBPeripheralDelegate

#pragma mark - Discovering Services

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    [SVProgressHUD dismiss];
    
    for(CBService *service in peripheral.services)
    {
        if([service.UUID isEqual:self.serviceUUID])
        {
            self.service = service;
            [self establishConnectionChannel];
            
            break;
        }
    }
}

#pragma mark - Discovering Characteristics and Characteristic Descriptors

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for(CBCharacteristic *characteristic in service.characteristics)
    {
        if([characteristic.UUID isEqual:self.txUUID])
        {
            self.txCharacteristic = characteristic;
        }
        
        if([characteristic.UUID isEqual:self.rxUUID])
        {
            self.rxCharacteristic = characteristic;
        }
    }
    
    if(self.txCharacteristic && self.rxCharacteristic)
    {
        [SVProgressHUD dismiss];
    }
}

#pragma mark - Writing Characteristic and Characteristic Descriptor Values

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        NSLog(@"didWriteValueForCharacteristic errored: %@", error);
    }
    else
    {
        // so here we begin to subscribe to any feedback from BLE
        [self.device setNotifyValue:YES
                  forCharacteristic:self.rxCharacteristic];
    }
    
    [SVProgressHUD dismiss];
}

#pragma mark - Managing Notifications for a Characteristic’s Value

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData *data = characteristic.value;
    
    if(data && data.length == 16)
    {
        NSArray *hexArray = [data hexInArray];
        
        [self handleTimeQuery:hexArray];
        [self handlePersonalSetting:hexArray];
    }

    NSLog(@"didUpdateNotificationStateForCharacteristic: %@", [data description]);
}

#pragma mark - parse data

- (void)handleTimeQuery:(NSArray *)hexArray
{
    if([hexArray[0] isEqual: @"41"])
    {
        int year = 2000 + [hexArray[1] intValue];
        int month = [hexArray[2] intValue];
        int day = [hexArray[3] intValue];
        int Hour = [hexArray[4] intValue];
        int Minute = [hexArray[5] intValue];
        int Second = [hexArray[6] intValue];
        
        NSDateComponents *comp = [[NSDateComponents alloc] init];
        [comp setYear:year];
        [comp setMonth:month];
        [comp setDay:day];
        [comp setHour:Hour];
        [comp setMinute:Minute];
        [comp setSecond:Second];
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *date = [calendar dateFromComponents:comp];
        
        NSString *dateString = [date descriptionWithLocale: [NSLocale currentLocale]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"目前時間" message:dateString delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil];
        
        [alert show];
    }
}

- (void)handlePersonalSetting:(NSArray *)hexArray
{
    if([hexArray[0] isEqual: @"42"])
    {
        NSString *gender = [hexArray[1] isEqualToString:@"00"] ? @"女性" : @"男性";
        NSString *age = hexArray[2];
        NSString *height = [hexArray[3] hexToDecimal];
        NSString *weight = [hexArray[4] hexToDecimal];
        NSString *strideLength = [hexArray[5] hexToDecimal];
        
        NSString *info = [NSString stringWithFormat:@"性別: %@\n年齡: %@\n身高: %@\n體重: %@\n步伐長度: %@",
                          gender, age, height, weight, strideLength];

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"個人資料" message:info delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil];
        
        [alert show];
    }
}

@end
