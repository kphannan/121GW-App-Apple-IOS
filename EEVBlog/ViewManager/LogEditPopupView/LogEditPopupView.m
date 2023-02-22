//
//  LogEditPopupView.m
//  PressureTracker
//
//  Created by sangho on 2015. 7. 23..
//  Copyright (c) 2015년 finest. All rights reserved.
//

#import "LogEditPopupView.h"

@interface LogEditPopupView ()
{
    LogListViewController *logListViewController;
}

@end

@implementation LogEditPopupView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)okBtn:(id)sender {
    [self setHidden:YES];
    [logListViewController logEditComplete];
}

- (IBAction)cancelBtn:(id)sender {
    [self setHidden:YES];
}

- (void)setHidden:(BOOL)bHidded
{
    [self.view setHidden:bHidded];
    if (bHidded){
        [self.memoText resignFirstResponder];
        [self.titleText resignFirstResponder];
    }
}

- (id)initPopupOnView:(LogListViewController *)mainController
{
    self = [super initWithNibName:@"LogEditPopupView" bundle:nil];
    if (self){
        logListViewController = mainController;
        [logListViewController.view addSubview:self.view];
        [self.view setHidden:YES];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
