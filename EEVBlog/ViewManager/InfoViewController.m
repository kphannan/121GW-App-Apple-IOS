//
//  InfoViewController.m
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [_appInformation setText:NSLocalizedString(@"info_app_info",  @"App Information")];
    [_appName setText:NSLocalizedString(@"info_app_name",  @"App Name: EEVBlog 121GW")];
    [_versionText setText:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"info_app_version",  @"App Version:"),version]];
    [_acknowledgement setText:NSLocalizedString(@"info_acknowledge",  @"Acknowledgements")];
    [_ackNotes setText:NSLocalizedString(@"info_ack_note",  @"ACK NOTES")];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    // Return YES for supported orientations
    return NO;
    
}

@end
