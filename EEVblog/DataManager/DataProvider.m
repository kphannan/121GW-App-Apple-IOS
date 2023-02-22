//
//  DataProvider.m
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//
#import "DataProvider.h"
#import "ToastMessage.h"
#import "DeviceCell.h"

#define MAX_SCAN_NUM            5
#define SERVICE_UUID            @"0bd51666-e7cb-469b-8e4d-2742f1ba77cc"
#define CHARACTERISTICS_UUID    @"e7add780-b042-4876-aae1-112855353cc1"

static unsigned char KEYCODE_BUZZER[5] =    {0xF4, 0x30, 0x39, 0x30, 0x39};

@interface DataProvider()
{
    UIAlertView     *errorMessageView;
    NSTimer *reTryConn;
    int nReTry;
    bool bRetry;
    NSString *disconnectErrorMsg;
}

@end

@implementation DataProvider

- (id)initWithProtocol:(DataProtocol *)protocol
{
    self = [super init];
    if (self == nil) return self;
    
    _protocol = protocol;
    
    _manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
    
    _connectedPeripheral=nil;
    _bConnected = NO;
    _bIdentify = NO;
    [_mainView connectStatus:_bConnected];
    [_connectImage setHidden:YES];
    
    _toastMessageView = [[ToastMessage alloc]init];
    errorMessageView = [[UIAlertView alloc]initWithTitle:nil message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"ble_exit", @"Exit")
                                       otherButtonTitles:NSLocalizedString(@"ble_continue", @"Continue"), nil];
    
    bRetry = NO;
    
    return self;
}

#pragma mark Bluetooth Connection
// for CBCentralManagerDelegate (required)
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSString *managerStrings[]={
        NSLocalizedString(@"ble_unknown", @"Unknown"),
        NSLocalizedString(@"ble_resetting", @"Resetting"),
        NSLocalizedString(@"ble_unsupported", @"Unsupported"),
        NSLocalizedString(@"ble_unauthorized", @"Unauthorized"),
        NSLocalizedString(@"ble_powered_off", @"Powered Off"),
        NSLocalizedString(@"ble_powered_on", @"Powered On")
    };
    
    if ( central.state == CBCentralManagerStatePoweredOn){
        [_listPopupView.peripherals removeAllObjects];
        
        // connect bluetooth
        NSArray * services=[NSArray arrayWithObjects:
                            [CBUUID UUIDWithString:SERVICE_UUID],
                            nil
                            ];
        [_manager scanForPeripheralsWithServices:services
                                         options: [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                                              forKey:CBCentralManagerScanOptionAllowDuplicatesKey]];
        return;
    }
    
    // connection failure
    [self showErrorMessage:managerStrings[central.state] withTitle:NSLocalizedString(@"ble_status", @"Bluetooth Status")];
    _bConnected = NO;
    [_mainView connectStatus:_bConnected];
    [_connectImage setHidden:YES];
}

static int scanCount = 0;
// Called when scanner finds device
- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI
{
    BOOL (^test)(id obj, NSUInteger idx, BOOL *stop);
    test = ^ (id obj, NSUInteger idx, BOOL *stop) {
        if([[[[obj peripheral] identifier] UUIDString] compare:[peripheral.identifier UUIDString]] == NSOrderedSame)
            return YES;
        return NO;
    };
    
    DeviceCell *cell;
    NSUInteger t=[_listPopupView.peripherals indexOfObjectPassingTest:test];
    if(t!= NSNotFound)
    {
        cell=[_listPopupView.peripherals objectAtIndex:t];
    }else{
        cell=[[DeviceCell alloc] init];
        [_listPopupView.peripherals addObject: cell];
    }
    cell.peripheral=peripheral;
    cell.rssi=RSSI;
    [_listPopupView.tableView reloadData];
    
    if (++scanCount == MAX_SCAN_NUM){
        scanCount = 0;
        [_manager stopScan];
        
        if ([_listPopupView.peripherals count] == 1){
            _peripheral = peripheral;
            [_peripheral setDelegate:self];
            [_manager connectPeripheral:_peripheral options:nil];
        } else {
            [_listPopupView showHideView];
        }
    }
}

// Called when peripheral is connected
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSArray *serviceUUID = [NSArray arrayWithObjects:
                            [CBUUID UUIDWithString:SERVICE_UUID],
                            nil];
    [_peripheral discoverServices:serviceUUID];
}

// Called when peripheral is disconnected
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error != nil){
        // retry connection
        [self connect];
        [_connectImage setHidden:YES];
        bRetry = YES;
        _bConnected = NO;
        reTryConn = [NSTimer scheduledTimerWithTimeInterval:2           // 순간 블루투스 단절을 2초까지 허용함
                                                     target:self
                                                   selector:@selector(disconnect)
                                                   userInfo:nil
                                                    repeats:NO];
        disconnectErrorMsg = [error localizedDescription];
        return;
    }
}

// Called when service is discovered
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    CBService *service = [_peripheral.services objectAtIndex:0];
    if([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID]])
    {
        _characteristic=nil;
        [_peripheral discoverCharacteristics:[NSArray arrayWithObject:[CBUUID UUIDWithString:CHARACTERISTICS_UUID]] forService:service];
    }
}

// Called when characteristics is discovered
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if(error != nil){
        [self showErrorMessage:[error localizedDescription] withTitle:NSLocalizedString(@"ble_error", @"ERROR")];
        return;
    }
    
    NSEnumerator *e = [service.characteristics objectEnumerator];
    if ( (_characteristic = [e nextObject]) ) {
        [peripheral setNotifyValue:YES forCharacteristic: _characteristic];
    }
    
    if (bRetry == NO && !_bIdentify)
        [_toastMessageView showWithMessage:NSLocalizedString(@"ble_connected", @"Connected") withContinuous:NO];
    _bConnected = YES;
    [_mainView connectStatus:_bConnected];
    [_connectImage setHidden:NO];
    
    if (_bIdentify){
        [self send:KEYCODE_BUZZER length:5];
        [self disconnect];
        _bIdentify = NO;
    }
}

// Called when device have a changed data
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error != nil){
        [self showErrorMessage:[error localizedDescription] withTitle:NSLocalizedString(@"ble_error", @"ERROR")];
        return;
    }
    
    unsigned char buffer[32];
    NSUInteger len=characteristic.value.length;
    memcpy(buffer,[characteristic.value bytes],len);
    
    [_protocol putData:buffer bufLen:(int)len];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        //handle error
        _characteristic=nil;
        _bConnected = NO;
        [_mainView connectStatus:_bConnected];
        [_connectImage setHidden:YES];
        [self showErrorMessage:[error localizedDescription] withTitle:NSLocalizedString(@"ble_error", @"ERROR")];
    }
}

// send data to the device
- (void)send:(unsigned char*)buffer length:(int)len
{
    NSData *data=[NSData dataWithBytes:buffer length:len];
    [_peripheral writeValue:data forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)disconnect
{
    if (bRetry && _bConnected){
        bRetry = NO;
        return;
    }
    
    [_manager cancelPeripheralConnection:_peripheral];
    _bConnected = NO;
    [_mainView connectStatus:_bConnected];
    [_connectImage setHidden:YES];
    
    if (bRetry){    // finish retry
        bRetry = NO;
        [self showErrorMessage:disconnectErrorMsg withTitle:NSLocalizedString(@"ble_disconnected", @"DISCONNECTED")];
    }
}

- (void)connectWithPeripheral:(CBPeripheral *)peripheral
{
    _peripheral = peripheral;
    [_peripheral setDelegate:self];
    [_manager connectPeripheral:_peripheral options:nil];
}

- (void)connect
{
    if (_manager.state == CBCentralManagerStateUnknown) // when _manager is about to created
        return;                                         // this is called only once when the application is launched
    
    [self centralManagerDidUpdateState:_manager];
}

#pragma mark Message APIs
// for UIAlterViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[alertView buttonTitleAtIndex:buttonIndex] compare: NSLocalizedString(@"ble_exit", @"Exit")] == NSOrderedSame)
        exit(1);
    
    if ([[alertView title] compare:NSLocalizedString(@"ble_disconnected", @"DISCONNECTED")] == NSOrderedSame &&
        [[alertView buttonTitleAtIndex:buttonIndex] compare:NSLocalizedString(@"ble_continue", @"Continue")] == NSOrderedSame)
        [self connect];
}

- (void)showErrorMessage:(NSString*)message withTitle:(NSString*)title
{
    [errorMessageView setMessage:message];
    [errorMessageView setTitle:title];
    [errorMessageView show];
}


@end
