//
//  LogEditPopupView.h
//  PressureTracker
//
//  Created by sangho on 2015. 7. 23..
//  Copyright (c) 2015년 finest. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LogListViewController.h"

@interface LogEditPopupView : UIViewController

@property NSInteger row;
@property (weak, nonatomic) IBOutlet UITextField *titleText;
@property (weak, nonatomic) IBOutlet UITextView *memoText;

- (IBAction)okBtn:(id)sender;
- (IBAction)cancelBtn:(id)sender;
- (id)initPopupOnView:(LogListViewController*)mainController;
- (void)setHidden:(BOOL)bHidded;
@end
