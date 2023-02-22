//
//  SampleListViewController.m
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import "SampleListViewController.h"
#import "SampleListLandscapeCell.h"
#import "SampleListPortraitCell.h"

@interface SampleListViewController ()

@end

@implementation SampleListViewController

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
    
    self.sampleListTable.dataSource = self;
    self.sampleListTable.delegate = self;
    
    UINib *nib = [UINib nibWithNibName:@"SampleListLandscapeCell" bundle:nil];
    [self.sampleListTable registerNib:nib forCellReuseIdentifier:@"SampleLandscapeCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self.sampleListTable reloadData];
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
    return [self.samples count] + 1;
}

-(void)boldFontForLabel:(UILabel *)label{
    UIFont *currentFont = label.font;
    UIFont *newFont = [UIFont fontWithName:[NSString stringWithFormat:@"%@-Bold",currentFont.fontName] size:currentFont.pointSize];
    [label setFont:newFont];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    UITableViewCell *cell;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (indexPath.row == 0){
        
        if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
            CellIdentifier = @"SampleLandscapeCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            SampleListLandscapeCell *landscapeCell = (SampleListLandscapeCell*)cell;
            landscapeCell.date.text = NSLocalizedString(@"sample_list_date",  @"Date");
            landscapeCell.time.text = NSLocalizedString(@"sample_list_time",  @"Time");
            landscapeCell.mainLCD.text = NSLocalizedString(@"sample_list_main_lcd",  @"Main LCD");
            landscapeCell.sub1.text = NSLocalizedString(@"sample_list_sub1",  @"Sub1");
            landscapeCell.sub2.text = NSLocalizedString(@"sample_list_sub2",  @"Sub2");
            [self boldFontForLabel:landscapeCell.time];
            [self boldFontForLabel:landscapeCell.date];
            [self boldFontForLabel:landscapeCell.mainLCD];
            [self boldFontForLabel:landscapeCell.sub1];
            [self boldFontForLabel:landscapeCell.sub2];
        } else {
            CellIdentifier = @"SamplePortraitCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            SampleListPortraitCell *portraitCell = (SampleListPortraitCell*)cell;
            portraitCell.time.text = [NSString stringWithFormat:@"[%@]", NSLocalizedString(@"sample_list_time",  @"Time")];
            portraitCell.date.text = NSLocalizedString(@"sample_list_date",  @"Date");
            portraitCell.mainLCD.text = NSLocalizedString(@"sample_list_main_lcd",  @"Main LCD");
            portraitCell.sub1.text = NSLocalizedString(@"sample_list_sub1",  @"Sub1");
            portraitCell.sub2.text = NSLocalizedString(@"sample_list_sub2",  @"Sub2");
            [self boldFontForLabel:portraitCell.time];
            [self boldFontForLabel:portraitCell.date];
            [self boldFontForLabel:portraitCell.mainLCD];
            [self boldFontForLabel:portraitCell.sub1];
            [self boldFontForLabel:portraitCell.sub2];
        }
        return cell;
    }
    
    NSDate *dateAndTime = [self.samples sampleDateAtIndex:indexPath.row];
    NSString *dateString, *timeString;
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    dateString = [dateFormat stringFromDate:dateAndTime];
    [dateFormat setDateFormat:@"HH:mm:ss"];
    timeString = [dateFormat stringFromDate:dateAndTime];
    
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        CellIdentifier = @"SampleLandscapeCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        SampleListLandscapeCell *landscapeCell = (SampleListLandscapeCell*)cell;
        landscapeCell.date.text = dateString;
        landscapeCell.time.text = timeString;
        landscapeCell.mainLCD.text = [self.samples sampleValueStringAtIndex:indexPath.row-1 pos:MAIN_LCD];
        landscapeCell.sub1.text = [self.samples sampleValueStringAtIndex:indexPath.row-1 pos:SUB1];
        landscapeCell.sub2.text = [self.samples sampleValueStringAtIndex:indexPath.row-1 pos:SUB2];
        
    } else {
        CellIdentifier = @"SamplePortraitCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        SampleListPortraitCell *portraitCell = (SampleListPortraitCell*)cell;
        portraitCell.time.text = [NSString stringWithFormat:@"[%@]", timeString];
        portraitCell.date.text = dateString;
        portraitCell.mainLCD.text = [self.samples sampleValueStringAtIndex:indexPath.row-1 pos:MAIN_LCD];
        portraitCell.sub1.text = [self.samples sampleValueStringAtIndex:indexPath.row-1 pos:SUB1];
        portraitCell.sub2.text = [self.samples sampleValueStringAtIndex:indexPath.row-1 pos:SUB2];
    }
    
    return cell;

}

@end
