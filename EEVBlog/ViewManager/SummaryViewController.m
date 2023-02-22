//
//  SummaryViewController.m
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import "SummaryViewController.h"
#import "SummaryTableCell.h"
#import "GraphView.h"

static double kLandGraphHeightRatio = 0.65;
static int kPortGraphHeight = 150;

@interface SummaryViewController ()
{
    GraphView *mDualPlot, *mSinglePlot;
    int landGraphHeight;
}
@end

@implementation SummaryViewController

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
    
    self.infoTable.delegate = self;
    self.infoTable.dataSource = self;
    
    self.graphArea.userInteractionEnabled = YES;
    
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    landGraphHeight = screenFrame.size.height < screenFrame.size.width ? screenFrame.size.height : screenFrame.size.width;
    landGraphHeight *= kLandGraphHeightRatio;
    
    [self.graphArea setFrame:CGRectMake(0, 62, self.graphArea.frame.size.width, 2 * kPortGraphHeight + 40)]; // show/hide 버튼이 인식되도록...

    // load graph view
    mSinglePlot = [[GraphView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kPortGraphHeight) axis:1];
    [mSinglePlot setYTitle:_samples.modeStrings[MAIN_LCD] at:K_LEFT_YAXIS];
    [mSinglePlot show:YES onView:self.graphArea];
    mSinglePlot.userInteractionEnabled = YES;
    
    mDualPlot = [[GraphView alloc] initWithFrame:CGRectMake(0, kPortGraphHeight, self.view.frame.size.width, kPortGraphHeight) axis:2];
    [mDualPlot setYTitle:_samples.modeStrings[SUB1] at:K_LEFT_YAXIS];
    [mDualPlot setYTitle:_samples.modeStrings[SUB2] at:K_RIGHT_YAXIS];
    [mDualPlot show:YES onView:self.graphArea];
    mDualPlot.userInteractionEnabled = YES;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        CGRect screenFrame = [[UIScreen mainScreen] bounds];
        
        [self.infoTable setHidden:YES];
        [self.graphArea setFrame:CGRectMake(0, 62, screenFrame.size.width, landGraphHeight * 2)]; // 350은 초기 화면을 설정하기 위함
        [mSinglePlot reFrame:CGRectMake(0, 0, screenFrame.size.width/2, landGraphHeight)];
        [mDualPlot reFrame:CGRectMake(screenFrame.size.width/2, 0, screenFrame.size.width/2, landGraphHeight)];
    }
    
    [mSinglePlot insertLeftDataList:[_samples sampleListAtPos:MAIN_LCD] rightDataList:nil];
    [mDualPlot insertLeftDataList:[_samples sampleListAtPos:SUB1] rightDataList:[_samples sampleListAtPos:SUB2]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch(orientation){
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
            [self.infoTable setHidden:NO];
            [self.graphArea setFrame:CGRectMake(0, 62, screenFrame.size.width, kPortGraphHeight * 2)];
            [mSinglePlot reFrame:CGRectMake(0, 0, screenFrame.size.width, kPortGraphHeight)];
            [mDualPlot reFrame:CGRectMake(0, kPortGraphHeight, self.graphArea.frame.size.width, kPortGraphHeight)];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [self.infoTable setHidden:YES];
            [self.graphArea setFrame:CGRectMake(0, 62, screenFrame.size.width, landGraphHeight * 2)];
            [mSinglePlot reFrame:CGRectMake(0, 0, screenFrame.size.width/2, landGraphHeight)];
            [mDualPlot reFrame:CGRectMake(screenFrame.size.width/2, 0, screenFrame.size.width/2, landGraphHeight)];
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    
    switch(interfaceOrientation){
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
            [self.infoTable setHidden:NO];
            [self.graphArea setFrame:CGRectMake(0, 62, screenFrame.size.width, kPortGraphHeight * 2)];
            [mSinglePlot reFrame:CGRectMake(0, 0, screenFrame.size.width, kPortGraphHeight)];
            [mDualPlot reFrame:CGRectMake(0, kPortGraphHeight, self.graphArea.frame.size.width, kPortGraphHeight)];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [self.infoTable setHidden:YES];
            [self.graphArea setFrame:CGRectMake(0, 62, screenFrame.size.width, landGraphHeight * 2)];
            [mSinglePlot reFrame:CGRectMake(0, 0, screenFrame.size.width/2, landGraphHeight)];
            [mDualPlot reFrame:CGRectMake(screenFrame.size.width/2, 0, screenFrame.size.width/2, landGraphHeight)];
            break;
        default:
            break;
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 19;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"infoCell";
    SummaryTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd [HH:mm:ss]"];
    NSString *dateString = [dateFormat stringFromDate:_samples.startTime];
    
    NSString *valFormat = [NSString stringWithFormat:@"%%.3f %%@"];
    
    cell.title.textColor = [UIColor blackColor];
    cell.title.textAlignment = NSTextAlignmentLeft;
    switch (indexPath.row)
    {
        case 0:
            cell.title.text = NSLocalizedString(@"summary_date", @"Date");
            cell.value.text = dateString;
            break;
        case 1:
            cell.title.text = NSLocalizedString(@"summary_interval", @"Recording Interval");
            if (_samples.samplingInterval > 60)
                cell.value.text = [NSString stringWithFormat:@"%i %@ %i %@", (int)(_samples.samplingInterval / 60), NSLocalizedString(@"summary_min", @"min."),
                                   (int)(_samples.samplingInterval % 60), NSLocalizedString(@"summary_sec", @"sec.")];
            else
                cell.value.text = [NSString stringWithFormat:@"%i %@", (int)_samples.samplingInterval, NSLocalizedString(@"summary_sec", @"sec.")];
            break;
        case 2:
            cell.title.text = NSLocalizedString(@"summary_num_of_samples", @"Number of Samples");
            cell.value.text = [NSString stringWithFormat:@"%i", (int)[_samples count]];
            break;
        case 3:
            cell.title.text = NSLocalizedString(@"summary_main_lcd", @"Main LCD");
            cell.title.textColor = [UIColor redColor];
            cell.title.textAlignment = NSTextAlignmentCenter;
            cell.value.text = @"";
            break;
        case 4:
            cell.title.text = NSLocalizedString(@"summary_rec_func", @"Rec Function");
            cell.value.text = _samples.recFuncString;
            break;
        case 5:
            cell.title.text = NSLocalizedString(@"summary_mode", @"Mode");
            cell.value.text = [_samples.modeStrings objectAtIndex:MAIN_LCD];
            break;
        case 6:
            cell.title.text = NSLocalizedString(@"summary_max_value", @"Maximum Value");
            cell.value.text = [NSString stringWithFormat:valFormat, [_samples.maxValues[MAIN_LCD] doubleValue], _samples.unitStrings[MAIN_LCD]];
            break;
        case 7:
            cell.title.text = NSLocalizedString(@"summary_avg_value", @"Average Value");
            cell.value.text = [NSString stringWithFormat:valFormat, [_samples.sumValues[MAIN_LCD] doubleValue]/ [_samples count], _samples.unitStrings[MAIN_LCD]];
            break;
        case 8:
            cell.title.text = NSLocalizedString(@"summary_min_value", @"Minimum Value");
            cell.value.text = [NSString stringWithFormat:valFormat, [_samples.minValues[MAIN_LCD] doubleValue], _samples.unitStrings[MAIN_LCD]];
            break;
        case 9:
            cell.title.text = NSLocalizedString(@"summary_sub1", @"Sub1");
            cell.title.textColor = [UIColor redColor];
            cell.title.textAlignment = NSTextAlignmentCenter;
            cell.value.text = @"";
            break;
        case 10:
            cell.title.text = NSLocalizedString(@"summary_mode", @"Mode");
            cell.value.text = [_samples.modeStrings objectAtIndex:SUB1];
            break;
        case 11:
            cell.title.text = NSLocalizedString(@"summary_max_value", @"Maximum Value");
            cell.value.text = [NSString stringWithFormat:valFormat, [_samples.maxValues[SUB1] doubleValue], _samples.unitStrings[SUB1]];
            break;
        case 12:
            cell.title.text = NSLocalizedString(@"summary_avg_value", @"Average Value");
            cell.value.text = [NSString stringWithFormat:valFormat, [_samples.sumValues[SUB1] doubleValue] / [_samples count], _samples.unitStrings[SUB1]];
            break;
        case 13:
            cell.title.text = NSLocalizedString(@"summary_min_value", @"Minimum Value");
            cell.value.text = [NSString stringWithFormat:valFormat, [_samples.minValues[SUB1] doubleValue], _samples.unitStrings[SUB1]];
            break;
        case 14:
            cell.title.text = NSLocalizedString(@"summary_sub2", @"Sub2");
            cell.title.textColor = [UIColor blueColor];
            cell.title.textAlignment = NSTextAlignmentCenter;
            cell.value.text = @"";
            break;
        case 15:
            cell.title.text = NSLocalizedString(@"summary_mode", @"Mode");
            cell.value.text = [_samples.modeStrings objectAtIndex:SUB2];
            break;
        case 16:
            cell.title.text = NSLocalizedString(@"summary_max_value", @"Maximum Value");
            cell.value.text = [NSString stringWithFormat:valFormat, [_samples.maxValues[SUB2] doubleValue], _samples.unitStrings[SUB2]];
            break;
        case 17:
            cell.title.text = NSLocalizedString(@"summary_avg_value", @"Average Value");
            cell.value.text = [NSString stringWithFormat:valFormat, [_samples.sumValues[SUB2] doubleValue] / [_samples count], _samples.unitStrings[SUB2]];
            break;
        case 18:
            cell.title.text = NSLocalizedString(@"summary_min_value", @"Minimum Value");
            cell.value.text = [NSString stringWithFormat:valFormat, [_samples.minValues[SUB2] doubleValue], _samples.unitStrings[SUB2]];
            break;
    }
    
    return cell;
}

- (IBAction)viewMemo:(id)sender {
    UIAlertView *memoView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"summary_memo", @"Memo") message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"summary_ok", @"OK"),nil];
    if ([_samples.memo isEqualToString:@""])
        [memoView setMessage:NSLocalizedString(@"summary_no_memo", @"NO MEMO !!")];
    else
        [memoView setMessage:_samples.memo];
    [memoView show];
}

@end
