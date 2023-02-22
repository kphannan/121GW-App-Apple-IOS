//
//  DataProvider.h
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "DataProtocol.h"
#import "ToastMessage.h"
#import "DeviceListPopupView.h"
#import "ViewController.h"

@interface DataProvider : NSObject <CBPeripheralDelegate,CBCentralManagerDelegate,UIAlertViewDelegate>
{
@private
    DataProtocol  *_protocol;
    CBCharacteristic *_characteristic;
    CBCentralManager *_manager;
    CBPeripheral *_connectedPeripheral;
}

@property BOOL bConnected;
@property BOOL bIdentify;
@property (nonatomic, strong) ToastMessage  *toastMessageView;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, weak) UIImageView *connectImage;
@property (nonatomic, weak) ViewController *mainView;
@property (nonatomic, weak) DeviceListPopupView *listPopupView;

- (id)initWithProtocol:(DataProtocol*)protocol;
- (void)send:(unsigned char*)buffer length:(int)len;

- (void)connect;
- (void)connectWithPeripheral:(CBPeripheral*)peripheral;
- (void)disconnect;

@end
