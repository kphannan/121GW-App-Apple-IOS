//
//  DeviceListPopupView.m
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import "DeviceListPopupView.h"
#import "DeviceListPopupCell.h"
#import "DeviceCell.h"
#import "DataProvider.h"
#import "AppDelegate.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface DeviceListPopupView ()
{
    UIView *mainView;
    Boolean bShow;
}
@end

@implementation DeviceListPopupView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initPopupOnView:(UIView *)view
{
    self = [super initWithNibName:@"DeviceListPopupView" bundle:nil];
    if (self){
        mainView = view;
        [mainView addSubview:self.view];
        [self.view setHidden:YES];
        bShow = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        _peripherals = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)showHideView
{
    [self.view setHidden:bShow];
    [self.tableView reloadData];
    bShow = !bShow;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DeviceCell";
    
    DeviceListPopupCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        [tableView registerNib:[UINib nibWithNibName:@"DeviceListPopupCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    
    DeviceCell *dataCell = [_peripherals objectAtIndex:indexPath.row];
    NSString *uuidString = [NSString stringWithFormat:@"UUID: %@", [[dataCell.peripheral identifier] UUIDString]];
    NSString *rssiString = [NSString stringWithFormat:@"RSSI: %@", [dataCell.rssi stringValue]];
    [cell.uuidString setText:uuidString];
    [cell.rssiString setText:rssiString];
    
    [cell.identifyButton addTarget:self action:@selector(identifyClicked:) forControlEvents:UIControlEventTouchUpInside];
    cell.identifyButton.tag = indexPath.row;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DataProvider *dataProvider = [(AppDelegate*)[[UIApplication sharedApplication] delegate] dataProvider];
    
    [self showHideView];
    [dataProvider connectWithPeripheral:[[self.peripherals objectAtIndex:indexPath.row] peripheral]];
}

- (void)identifyClicked:(UIButton*)sender
{
    DataProvider *dataProvider = [(AppDelegate*)[[UIApplication sharedApplication] delegate] dataProvider];
    
    [dataProvider connectWithPeripheral:[[self.peripherals objectAtIndex:sender.tag] peripheral]];
    dataProvider.bIdentify = YES;
}

@end
