//
//  SampleListViewController.h
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Samples.h"

@interface SampleListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong)Samples *samples;
@property (weak, nonatomic) IBOutlet UITableView *sampleListTable;

@end
