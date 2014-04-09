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

@property (assign) BOOL isGettingActivity;
@property (assign) int lastTimeStep;
@property (nonatomic, strong) NSMutableArray *todayActivities;


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
                     @"查看個人資料",
                     @"今天活動記錄",
                     @"目前數據",
                     @"目前進度"];
    
    // -------------------- bt related --------------------
    
    [SVProgressHUD showWithStatus:@"起始中..." maskType:SVProgressHUDMaskTypeGradient];
    
    self.lastTimeStep = 0;
    self.isGettingActivity = NO;
    self.todayActivities = [NSMutableArray array];
    
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
        case 2:
            [self showTodayActivity];
            break;
        case 3:
            [self showTodaySummary];
            break;
        case 4:
            [self showCurrentProgress];
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
    
    [self.device setNotifyValue:YES
              forCharacteristic:self.rxCharacteristic];
}

- (void)showCurrentTime
{
    [self executeOption:0x41];
}

- (void)showPersonalSetting
{
    [self executeOption:0x42];
}

- (void)showTodayActivity
{
    [self executeOption:0x43];
}

- (void)showTodaySummary
{
    [self executeOption:0x07];
}

- (void)showCurrentProgress
{
    [self executeOption:0x08];
}

#pragma mark - CBPeripheralDelegate

#pragma mark - Discovering Services

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
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
        [self handleTodayActivity:hexArray];
        [self handleTodaySummary:hexArray];
        [self handleCurrentProgress:hexArray];
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

- (void)handleTodayActivity:(NSArray *)hexArray
{
    if([hexArray[0] isEqual: @"43"])
    {
        self.isGettingActivity = YES;
        NSString *line = nil;
        
        int timeScale = [[hexArray[5] hexToDecimal] intValue];
        NSString *timeString = [NSString stringWithFormat:@"%d ~ %d 分鐘",
                                timeScale * 15,
                                (timeScale + 1) * 15];
        
        NSString *activityMode = [hexArray[6] isEqualToString:@"00"] ? @"正常模式" : @"睡眠模式";
        
        NSLog(@"timeScle: hex:%@ dec:%d", hexArray[5], timeScale);
        
        if([activityMode isEqualToString:@"正常模式"])
        {
            NSString *calorie = [[NSString stringWithFormat:@"0x%@%@", hexArray[8], hexArray[7]] hexToDecimal];
            // need to divide calorie by 100 according to spec
            calorie = [NSString stringWithFormat:@"%.02f", [calorie integerValue] / 100.0];
            
            NSString *steps = [[NSString stringWithFormat:@"0x%@%@", hexArray[10], hexArray[9]] hexToDecimal];
            NSString *distance = [[NSString stringWithFormat:@"0x%@%@", hexArray[12], hexArray[11]] hexToDecimal];
            NSString *runningSteps = [[NSString stringWithFormat:@"0x%@%@", hexArray[14], hexArray[13]] hexToDecimal];
            
            
            line = [NSString stringWithFormat:@"Time:%@|Mode:%@|Calorie:%@|Steps:%@|Distance:%@|Running Steps:%@",
                    timeString,
                    activityMode,
                    calorie,
                    steps,
                    distance,
                    runningSteps];
            
            NSLog(@"%@", line);
        }
        else
        {
            NSString *sleepQuality2 = [hexArray[7] hexToDecimal];
            NSString *sleepQuality4 = [hexArray[8] hexToDecimal];
            NSString *sleepQuality6 = [hexArray[9] hexToDecimal];
            NSString *sleepQuality8 = [hexArray[10] hexToDecimal];
            NSString *sleepQuality10 = [hexArray[11] hexToDecimal];
            NSString *sleepQuality12 = [hexArray[12] hexToDecimal];
            NSString *sleepQuality14 = [hexArray[13] hexToDecimal];
            NSString *sleepQuality16 = [hexArray[14] hexToDecimal];
            
            line = [NSString stringWithFormat:@"Time:%@|Mode:%@|睡眠1:%@|睡眠2:%@|睡眠3:%@|睡眠4:%@|睡眠5:%@|睡眠6:%@|睡眠7:%@|睡眠8:%@",
                    timeString,
                    activityMode,
                    sleepQuality2,
                    sleepQuality4,
                    sleepQuality6,
                    sleepQuality8,
                    sleepQuality10,
                    sleepQuality12,
                    sleepQuality14,
                    sleepQuality16];
            
            NSLog(@"%@", line);
        }

        // looks like we need to keep asking in order to iterate through
        if(self.lastTimeStep > timeScale)
        {
            NSLog(@"Getting today's activity completed");
            self.lastTimeStep = 0;
            self.isGettingActivity = NO;
            
            NSString *summary = [self.todayActivities componentsJoinedByString:@"\n"];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"今天活動記錄" message:summary delegate:self cancelButtonTitle:@"確定" otherButtonTitles:nil];
            
            [alert show];
            
            self.todayActivities = [NSMutableArray array];
        }
        else
        {
            [self.todayActivities addObject:line];
            
            self.lastTimeStep = timeScale;
            
            [self showTodayActivity];
        }
    }
}

- (void)handleTodaySummary:(NSArray *)hexArray
{
    /*
     9.Read someday’s total activity data
     Command format:
     Function:
     Description:
     Commnand response:
     Check right and execute OK, then return: 0x07 AA BB CC DD EE FF GG HH II JJ KK LL MM NN CRC Check error and execute Fail, then return: 0x87 00 00 00 00 00 00 00 00 00 00 00 00 00 00 CRC
     0x07 AA 00 00 00 00 00 00 00 00 00 00 00 00 00 CRC
     Read somedays’s total activity data
     AA = 0 stands for current day, AA = 10 stands for 10 days ago
     Respond description:( total 2 responses, and each one the first five bytes of the same meaning)
     AA stands for the command index values,this command will response two items,the first index values is 0, The second index values is 1.
     BB stands for few days ago’s data.
     CC DD EE stands for year month day. (If year, month, day all is 0, it means no data this day)
     The first response:
     FF GG HH stands for the total steps.
     II JJ KK stands for 3-byte running steps/ aerobic steps, high byte in the front. LL MM NN stands for 3-byte calorie value, high byte in the front.
     The second response:
     FF GG HH stands for 3-byte walking distance, high byte in the front.
     II JJ stands for 2-byte activity time, the unit is minute, KKNN stands for 0.
     */
    
    if([hexArray[0] isEqual: @"07"])
    {
        NSString *totalDistance = [[NSString stringWithFormat:@"0x%@%@%@", hexArray[6], hexArray[7], hexArray[8]] hexToDecimal];
        NSString *totalCalorie = [[NSString stringWithFormat:@"0x%@%@%@", hexArray[12], hexArray[13], hexArray[14]] hexToDecimal];
        
        // divide by 100 to get the unit right
        totalDistance = [NSString stringWithFormat:@"%.02f", [totalDistance integerValue] / 100.0];
        totalCalorie = [NSString stringWithFormat:@"%.02f", [totalCalorie integerValue] / 100.0];
        
        NSString *summary = [NSString stringWithFormat:@"距離: %@\nCalorie: %@", totalDistance, totalCalorie];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"目前數據"
                                                        message:summary
                                                       delegate:self
                                              cancelButtonTitle:@"確定"
                                              otherButtonTitles:nil];
        
        [alert show];
    }
}

- (void)handleCurrentProgress:(NSArray *)hexArray
{
    /*
     10.Read someday’s activity goal achieved rate:
     Command format: Function: Description:
     0x08 AA 00 00 00 00 00 00 00 00 00 00 00 00 00 CRC
     Read someday’s total activity data
     AA = 0 stands for current day, AA = 10 stands for 10 days ago
     Command response:
     Check right and execute OK, then return: 0x08 AA BB CC DD EE FF GG HH II JJ KK LL MM NN CRC Check right and execute OK, then return: 0x88 00 00 00 00 00 00 00 00 00 00 00 00 00 00 CRC
     AA stands for days ago’s data, 0 stands for current day, 1 stands for the day before.
     BB CC DD stands for year,month, day. (If year, month, day all is 0, it means no data this day) EE stands for goal achieved rate: value range: 0100
     */
    
    if([hexArray[0] isEqual: @"08"])
    {
        NSString *progress = [[NSString stringWithFormat:@"0x%@", hexArray[5]] hexToDecimal];
        
        NSString *summary = [NSString stringWithFormat:@"進度: %@%%", progress];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"目前進度"
                                                        message:summary
                                                       delegate:self
                                              cancelButtonTitle:@"確定"
                                              otherButtonTitles:nil];
        
        [alert show];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self showTodaySummary];
        });
    }
}

@end
