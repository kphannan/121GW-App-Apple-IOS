//
//  DeviceListPopupView.h
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceListPopupView : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *peripherals;

- (id)initPopupOnView:(UIView*)mainView;
- (void)showHideView;



@end
