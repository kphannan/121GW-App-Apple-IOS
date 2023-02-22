//
//  LogListCell.h
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#ifndef PressureTracker_LogListCell_h
#define PressureTracker_LogListCell_h

#import <UIKit/UIKit.h>

@interface LogListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *subTitle;
@property (weak, nonatomic) IBOutlet UIButton *edit;

@end

#endif
