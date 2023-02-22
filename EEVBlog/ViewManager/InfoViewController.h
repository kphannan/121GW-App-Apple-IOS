//
//  InfoViewController.h
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *appInformation;
@property (weak, nonatomic) IBOutlet UILabel *appName;
@property (weak, nonatomic) IBOutlet UILabel *versionText;
@property (weak, nonatomic) IBOutlet UILabel *acknowledgement;
@property (weak, nonatomic) IBOutlet UILabel *ackNotes;

@end
