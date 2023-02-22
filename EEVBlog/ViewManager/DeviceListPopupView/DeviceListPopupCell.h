//
//  DeviceListPopupCell.h
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceListPopupCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *uuidString;
@property (weak, nonatomic) IBOutlet UILabel *rssiString;
@property (weak, nonatomic) IBOutlet UIButton *identifyButton;

- (IBAction)identifyClicked:(id)sender;

@end
