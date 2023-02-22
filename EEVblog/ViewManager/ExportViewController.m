//
//  ExportViewController.m
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import "ExportViewController.h"
#import "GraphView.h"

static NSString *kCSV = @"CSV";
static NSString *kPNG = @"PNG";
static NSString *kJPG = @"JPG";

static int kGraphHeight = 176;
static NSFileManager *fm;

@interface ExportViewController ()
{
    GraphView *mDualPlot, *mSinglePlot;
    NSString *path;
}
@end

@implementation ExportViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    path = nil;
    // load setting
    _csvSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kCSV];
    _pngSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kPNG];
    _jpgSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kJPG];
    
    // load graph view
    mSinglePlot = [[GraphView alloc] initWithFrame:CGRectMake(0, 10, self.view.frame.size.width, kGraphHeight) axis:1];
    [mSinglePlot setYTitle:_samples.modeStrings[MAIN_LCD] at:K_LEFT_YAXIS];
    
    mDualPlot = [[GraphView alloc] initWithFrame:CGRectMake(0, 10, self.view.frame.size.width, kGraphHeight) axis:2];
    [mDualPlot setYTitle:_samples.modeStrings[SUB1] at:K_LEFT_YAXIS];
    [mDualPlot setYTitle:_samples.modeStrings[SUB2] at:K_RIGHT_YAXIS];

    [mSinglePlot insertLeftDataList:[_samples sampleListAtPos:MAIN_LCD] rightDataList:nil];
    [mDualPlot insertLeftDataList:[_samples sampleListAtPos:SUB1] rightDataList:[_samples sampleListAtPos:SUB2]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return;
}

- (IBAction)mailSend:(id)sender {
    NSString *filePath;
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd [HH:mm:ss]"];
    NSString *subject = [NSString stringWithFormat:@"%@(%@)\n",
                         NSLocalizedString(@"export_mail_title", @"EEVBlog Exports"),
                         [dateFormat stringFromDate:_samples.startTime]];
    
    [self saveFiles];
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:subject];
    [controller setMessageBody:NSLocalizedString(@"export_mail_body", @"EEVBlog's log files are attached:") isHTML:YES];
    
    if (_pngSwitch.on){
        filePath = [NSString stringWithFormat:@"%@/%@", path, @"graph1.png"];
        [controller addAttachmentData:[NSData dataWithContentsOfFile:filePath] mimeType:@"png" fileName:@"graph1.png"];
        filePath = [NSString stringWithFormat:@"%@/%@", path, @"graph2.png"];
        [controller addAttachmentData:[NSData dataWithContentsOfFile:filePath] mimeType:@"png" fileName:@"graph2.png"];
    }
    
    if (_jpgSwitch.on){
        filePath = [NSString stringWithFormat:@"%@/%@", path, @"graph1.jpg"];
        [controller addAttachmentData:[NSData dataWithContentsOfFile:filePath] mimeType:@"jpg" fileName:@"graph1.jpg"];
        filePath = [NSString stringWithFormat:@"%@/%@", path, @"graph2.jpg"];
        [controller addAttachmentData:[NSData dataWithContentsOfFile:filePath] mimeType:@"jpg" fileName:@"graph2.jpg"];
    }
    
    if (_csvSwitch.on){
        filePath = [NSString stringWithFormat:@"%@/%@", path, @"data.csv"];
        [controller addAttachmentData:[NSData dataWithContentsOfFile:filePath] mimeType:@"text/csv" fileName:@"data.csv"];
    }
    
    if (controller)
        [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)csvSwitchChange:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[_csvSwitch isOn] forKey:kCSV];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)pngSwitchChange:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[_pngSwitch isOn] forKey:kPNG];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)jpgSwitchChange:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[_jpgSwitch isOn] forKey:kJPG];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveFiles
{
    if (path == nil){
        path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        path = [path stringByAppendingString:@"/Temp"];
        fm = [NSFileManager defaultManager];
    }
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    if (_pngSwitch.on){
        [mSinglePlot saveGraphIntoFile:@"graph1.png" path:path format:K_PNG_FORMAT];
        [mDualPlot saveGraphIntoFile:@"graph2.png" path:path format:K_PNG_FORMAT];
    }
    
    if (_jpgSwitch.on){
        [mSinglePlot saveGraphIntoFile:@"graph1.jpg" path:path format:K_JPG_FORMAT];
        [mDualPlot saveGraphIntoFile:@"graph2.jpg" path:path format:K_JPG_FORMAT];
    }
    
    if (_csvSwitch.on){
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", path, @"data.csv"];
        
        // create the file and write title
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
        [dateFormat setDateFormat:@"yyyy-MM-dd [HH:mm:ss]"];
        NSString *fileData = [NSString stringWithFormat:@"\357\273\277%@: %@\n", // include BOM(Byte Order Marker);단위에 사용되는 특수문자 출력을 위함.
                              NSLocalizedString(@"export_title", @"Title:"), _samples.title];
        [fileData writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        // file open
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [fileHandle seekToEndOfFile];
        
        // write measured date and time
        fileData = [NSString stringWithFormat:@"%@ %@\n", NSLocalizedString(@"export_measured_date", @"Measured Date:"), [dateFormat stringFromDate:_samples.startTime]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        // write sample interval
        if (_samples.samplingInterval > 60)
            fileData = [NSString stringWithFormat:@"%@: %i %@ %i %@\n",
                        NSLocalizedString(@"export_recording_interval", @"Recording Interval:"),
                        (int)(_samples.samplingInterval / 60), NSLocalizedString(@"export_min", @"min."),
                        (int)(_samples.samplingInterval % 60), NSLocalizedString(@"export_sec", @"sec.")];
        else
            fileData = [NSString stringWithFormat:@"%@ %i %@\n", NSLocalizedString(@"export_recording_interval", @"Recording Interval:"),
                        (int)_samples.samplingInterval, NSLocalizedString(@"export_sec", @"sec.")];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        // main lcd position
        fileData = [NSString stringWithFormat:NSLocalizedString(@"export_main_lcd_position", @"Main LCD Information\n")];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %@\n", NSLocalizedString(@"export_rec_function", @"Rec Function:"), _samples.recFuncString];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %@\n", NSLocalizedString(@"export_mode", @"Mode:"), _samples.modeStrings[MAIN_LCD]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %.3f\n", NSLocalizedString(@"export_max_value", @"Maximum Value:"), [_samples.maxValues[MAIN_LCD] doubleValue]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %.3f\n", NSLocalizedString(@"export_avg_value", @"Average Value:"), [_samples.sumValues[MAIN_LCD] doubleValue] / [_samples count]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %.3f\n", NSLocalizedString(@"export_min_value", @"Minimum Value:"), [_samples.minValues[MAIN_LCD] doubleValue]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        // sub1 position
        fileData = [NSString stringWithFormat:NSLocalizedString(@"export_sub1_position", @"Sub1 Information\n")];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %@\n", NSLocalizedString(@"export_mode", @"Mode:"), _samples.modeStrings[SUB1]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %.3f\n", NSLocalizedString(@"export_max_value", @"Maximum Value:"), [_samples.maxValues[SUB1] doubleValue]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %.3f\n", NSLocalizedString(@"export_avg_value", @"Average Value:"), [_samples.sumValues[SUB1] doubleValue] / [_samples count]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %.3f\n", NSLocalizedString(@"export_min_value", @"Minimum Value:"), [_samples.minValues[SUB1] doubleValue]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];

        // sub2 position
        fileData = [NSString stringWithFormat:NSLocalizedString(@"export_sub2_position", @"Sub2 Information\n")];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %@\n", NSLocalizedString(@"export_mode", @"Mode:"), _samples.modeStrings[SUB2]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %.3f\n", NSLocalizedString(@"export_max_value", @"Maximum Value:"), [_samples.maxValues[SUB2] doubleValue]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %.3f\n", NSLocalizedString(@"export_avg_value", @"Average Value:"), [_samples.sumValues[SUB2] doubleValue] / [_samples count]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %.3f\n", NSLocalizedString(@"export_min_value", @"Minimum Value:"), [_samples.minValues[SUB2] doubleValue]];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        fileData = [NSString stringWithFormat:@"%@ %@\n", NSLocalizedString(@"export_memo", @"Memo:"), _samples.memo];
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        // write field name
        fileData = NSLocalizedString(@"export_cvs_head", @",No.,Main LCD Value,Main LCD Unit,Sub1 Value,Sub1 Unit,Sub2 Value,Sub2 Unit\n");
        [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSArray *mainLCDDataList= [_samples sampleListAtPos:MAIN_LCD];
        NSArray *sub1DataList = [_samples sampleListAtPos:SUB1];
        NSArray *sub2DataList = [_samples sampleListAtPos:SUB2];
        NSArray *mainLCDOLDataList = [_samples sampleOLListAtPos:MAIN_LCD];
        NSArray *sub1OLDataList = [_samples sampleOLListAtPos:SUB1];
        NSArray *sub2OLDataList = [_samples sampleOLListAtPos:SUB2];
        for (int count=0; count < mainLCDDataList.count; count++) {
            NSString *valueString;
            NSNumber *olValue;
            
            fileData = [NSString stringWithFormat:@",%i,", count];
            olValue = [mainLCDOLDataList objectAtIndex:count];
            if ([olValue intValue] == -1) valueString = [NSString stringWithFormat:@"'-O.L.',%@,",_samples.unitStrings[MAIN_LCD]];
            else if ([olValue intValue] == 1) valueString = [NSString stringWithFormat:@"'O.L.',%@,",_samples.unitStrings[MAIN_LCD]];
            else valueString = [NSString stringWithFormat:@"%.3f,%@,",[[mainLCDDataList objectAtIndex:count] doubleValue], _samples.unitStrings[MAIN_LCD]];
            fileData = [fileData stringByAppendingString:valueString];
            
            olValue = [sub1OLDataList objectAtIndex:count];
            if ([olValue intValue] == -1) valueString = [NSString stringWithFormat:@"'-O.L.',%@,",_samples.unitStrings[SUB1]];
            else if ([olValue intValue] == 1) valueString = [NSString stringWithFormat:@"'O.L.',%@,",_samples.unitStrings[SUB1]];
            else valueString = [NSString stringWithFormat:@"%.3f,%@,",[[sub1DataList objectAtIndex:count] doubleValue], _samples.unitStrings[SUB1]];
            fileData = [fileData stringByAppendingString:valueString];
            
            olValue = [sub2OLDataList objectAtIndex:count];
            if ([olValue intValue] == -1) valueString = [NSString stringWithFormat:@"'-O.L.',%@\n", _samples.unitStrings[SUB2]];
            else if ([olValue intValue] == 1) valueString = [NSString stringWithFormat:@"'O.L.',%@\n", _samples.unitStrings[SUB2]];
            else valueString = [NSString stringWithFormat:@"%.3f,%@\n",[[sub2DataList objectAtIndex:count] doubleValue], _samples.unitStrings[SUB2]];
            fileData = [fileData stringByAppendingString:valueString];
            
            [fileHandle writeData:[fileData dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
}

@end
