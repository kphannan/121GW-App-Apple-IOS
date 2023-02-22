//
//  DeviceCell.h
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface DeviceCell : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSNumber *rssi;

@end
