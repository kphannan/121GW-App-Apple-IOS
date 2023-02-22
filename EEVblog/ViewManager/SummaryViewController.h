//
//  SummaryViewController.h
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Samples.h"

@interface SummaryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong)Samples *samples;
@property (weak, nonatomic) IBOutlet UIView *graphArea;
@property (weak, nonatomic) IBOutlet UITableView *infoTable;

- (IBAction)viewMemo:(id)sender;
@end
