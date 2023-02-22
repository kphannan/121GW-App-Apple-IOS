//
//  ExportViewController.h
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "Samples.h"

@interface ExportViewController : UITableViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) Samples *samples;
@property (weak, nonatomic) IBOutlet UISwitch *csvSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *pngSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *jpgSwitch;

- (IBAction)mailSend:(id)sender;
- (IBAction)csvSwitchChange:(id)sender;
- (IBAction)pngSwitchChange:(id)sender;
- (IBAction)jpgSwitchChange:(id)sender;

@end
