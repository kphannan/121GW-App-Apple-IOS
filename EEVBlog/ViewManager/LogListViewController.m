//
//  LogListViewController.m
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import "LogListViewController.h"
#import "LogListCell.h"
#import "Samples.h"
#import "SampleListViewController.h"
#import "LogEditPopupView.h"
#import "LayoutManager.h"


@interface LogListViewController ()
{
    NSMutableArray *logList;
    NSString *path;
    NSFileManager *fm;
    LogEditPopupView *logEditView;
    LayoutManager *layout;
}
@end

@implementation LogListViewController

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

    self.logListTable.dataSource = self;
    self.logListTable.delegate = self;
    
    // load file name
    NSArray *files = [Samples getSampleFileList];
    logList = [[NSMutableArray alloc] initWithArray:files];
    
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    layout = [[LayoutManager alloc] initWithScreenSize: screenFrame.size];
    
    logEditView = [[LogEditPopupView alloc] initPopupOnView:self];
    [logEditView.view setFrame:[layout getSize:LOG_EDIT_MODAL]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)click:(UIButton*)sender{
    logEditView.row = sender.tag;
    NSString *fileName = [logList objectAtIndex:logEditView.row];
    Samples *sample = [Samples readToDiskWithFileName:fileName];
    
    [logEditView.titleText setText:sample.title];
    [logEditView.memoText setText:sample.memo];
    [logEditView setHidden:NO];
}

- (void)logEditComplete
{
    NSString *fileName = [logList objectAtIndex:logEditView.row];
    Samples *sample = [Samples readToDiskWithFileName:fileName];
    sample.title = logEditView.titleText.text;
    sample.memo = logEditView.memoText.text;
    [sample saveToDiskWithFileName:fileName];
    
    [self.logListTable reloadData];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    switch(interfaceOrientation){
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
            [layout setOrientation:PORTRAIT];
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [layout setOrientation:LANDSCAPE];
            break;
        default:
            break;
    }
    
    [logEditView setHidden:YES];
    logEditView = [[LogEditPopupView alloc] initPopupOnView:self];
    [logEditView.view setFrame:[layout getSize:LOG_EDIT_MODAL]];
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
    return [logList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LogCell";
    LogListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell == nil)
    {
        cell = [[LogListCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] ;
    }
    
    NSString *fileName = [logList objectAtIndex:indexPath.row];
    Samples *sample = [Samples readToDiskWithFileName:fileName];
    cell.title.text = sample.title;
    cell.subTitle.text = fileName;
    
    [cell.edit addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    cell.edit.tag = indexPath.row;

    [cell.edit setHidden: !self.logListTable.editing];
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.logListTable.editing)
    {
        return UITableViewCellEditingStyleDelete;
    }
    
    return UITableViewCellEditingStyleNone;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        int index = (int)indexPath.row;
        [Samples deleteSampleFile:[logList objectAtIndex:index]];
        [logList removeObjectAtIndex:index];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (IBAction)enableEdit:(id)sender {
    if (self.logListTable.editing){
        [self.editButton setTitle:NSLocalizedString(@"log_edit", @"Edit")];
        self.logListTable.editing = NO;
    } else {
        [self.editButton setTitle:NSLocalizedString(@"log_done", @"Done")];
        self.logListTable.editing = YES;
    }
    
    [self.logListTable reloadData];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (![segue.identifier isEqualToString:@"SampleDetail"])
        return;

    NSIndexPath *selectedIndexPath = self.logListTable.indexPathForSelectedRow;
    NSString *fileName = [logList objectAtIndex:selectedIndexPath.row];
    
    Samples *sample = [Samples readToDiskWithFileName:fileName];
    UITabBarController *tabBarController = segue.destinationViewController;
    SampleListViewController *sampleListViewController;
    
    sampleListViewController = [[tabBarController viewControllers] objectAtIndex:0];
    sampleListViewController.samples = sample;
    sampleListViewController = [[tabBarController viewControllers] objectAtIndex:1];
    sampleListViewController.samples = sample;
    sampleListViewController = [[tabBarController viewControllers] objectAtIndex:2];
    sampleListViewController = [sampleListViewController.childViewControllers objectAtIndex:0];
    sampleListViewController.samples = sample;
}

@end
