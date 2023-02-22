//
//  ViewController.m
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "AppDelegate.h"
#import "ViewController.h"
#import "GraphView.h"
#import "LayoutManager.h"
#import "DeviceListPopupView.h"
#import "DataProvider.h"
#import "Samples.h"

static unsigned char KEYCODE_RANGE[] = {0xF4, 0x30, 0x31, 0x30, 0x31};
static unsigned char KEYCODE_HOLD[] =  {0xF4, 0x30, 0x32, 0x30, 0x32};
static unsigned char KEYCODE_REL[] =   {0xF4, 0x30, 0x33, 0x30, 0x33};
static unsigned char KEYCODE_PEAK[] =  {0xF4, 0x30, 0x34, 0x30, 0x34};
static unsigned char KEYCODE_MODE[] =  {0xF4, 0x30, 0x35, 0x30, 0x35};
static unsigned char KEYCODE_MINMAX[] ={0xF4, 0x30, 0x36, 0x30, 0x36};
static unsigned char KEYCODE_MEM[] =   {0xF4, 0x30, 0x37, 0x30, 0x37};
static unsigned char KEYCODE_SETUP[] = {0xF4, 0x30, 0x38, 0x30, 0x38};

static unsigned char KEYCODE_LONG_RANGE[] = {0xF4, 0x38, 0x31, 0x38, 0x31};
static unsigned char KEYCODE_LONG_HOLD[] =  {0xF4, 0x38, 0x32, 0x38, 0x32};
static unsigned char KEYCODE_LONG_REL[] =   {0xF4, 0x38, 0x33, 0x38, 0x33};
static unsigned char KEYCODE_LONG_PEAK[] =  {0xF4, 0x38, 0x34, 0x38, 0x34};
static unsigned char KEYCODE_LONG_MODE[] =  {0xF4, 0x38, 0x35, 0x38, 0x35};
static unsigned char KEYCODE_LONG_MINMAX[] ={0xF4, 0x38, 0x36, 0x38, 0x36};
static unsigned char KEYCODE_LONG_MEM[] =   {0xF4, 0x38, 0x37, 0x38, 0x37};
static unsigned char KEYCODE_LONG_SETUP[] = {0xF4, 0x38, 0x38, 0x38, 0x38};

static float kMinRefreshRate = 0.1;  // 100 ms

@interface ViewController (){
    LayoutManager *layout;
    NSMutableDictionary *viewObjs;
    UIImage *upBtnImage, *downBtnImage;
    UIImage *portrait_background_img, *landscape_background_img, *bt_connect_img;
    DataProtocol *protocol;
    NSTimer *displayTimer, *loggingTimer;
    double refreshRate;
    Boolean bLogging;
    Boolean b2GraphShow, b1GraphShow, bFuncBtnShow, bLogShow, bMenuShow;
    Samples *sampleData;
    DeviceListPopupView *devicePopupList;
    DataProvider *dataProvider;
}

@property (nonatomic, strong)GraphView *mDualPlot, *mSiglePlot;
@property (nonatomic, readonly) SystemSoundID button_click_sound_ssid;          // for button click sound
@property (nonatomic, readonly) BOOL bButtonSound, bButtonVibration;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // loading setting
    _bButtonSound = ![[NSUserDefaults standardUserDefaults] boolForKey:K_BUTTON_CLICK_SOUND];
    _bButtonVibration = [[NSUserDefaults standardUserDefaults] boolForKey:K_BUTTON_CLICK_VIBRATION];
    refreshRate = (double)[[NSUserDefaults standardUserDefaults] integerForKey:K_REFRESH_RATE]/1000.0;
    if (refreshRate <= kMinRefreshRate) refreshRate = kMinRefreshRate;
    
    NSUInteger maxSamples = [[NSUserDefaults standardUserDefaults]integerForKey:K_MAX_SAMPLES];
    if (maxSamples < K_DEFAULT_MAX_SAMPLES) maxSamples = K_DEFAULT_MAX_SAMPLES;
    
    NSUInteger samplingInterval = [[NSUserDefaults standardUserDefaults]integerForKey:K_SAMPLING_INTERVAL];
    if (samplingInterval < K_DEFAULT_SAMPLING_INTERVAL) samplingInterval = K_DEFAULT_SAMPLING_INTERVAL;
    
    bool bContinuousSaving = [[NSUserDefaults standardUserDefaults]boolForKey:K_CONTINUOUS_RECORDING];

    // init images
    portrait_background_img = [UIImage imageNamed:@"portrait_background.png"];
    landscape_background_img = [UIImage imageNamed:@"landscape_background.png"];
    bt_connect_img = [UIImage imageNamed:@"bluetooth.png"];
    
    // create button click sound
    NSString *sndPath = [[NSBundle mainBundle] pathForResource:@"button_press" ofType:@"caf"];
    CFURLRef sndURL = (CFURLRef)CFBridgingRetain([[NSURL alloc] initFileURLWithPath:sndPath]);
    AudioServicesCreateSystemSoundID(sndURL, &_button_click_sound_ssid);
    
    // get screen size and init layout data
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    layout = [[LayoutManager alloc] initWithScreenSize: screenFrame.size];

    // init function status
    bMenuShow = bLogShow = b2GraphShow = b1GraphShow = bFuncBtnShow = false;
    
    // load graph view
    self.mSiglePlot = [[GraphView alloc] initWithFrame:[layout getSize:UPPER_GRAPH] axis:1];
    [self.mSiglePlot setXTitle: @"time(unit: 1 second)"];
    [self.mSiglePlot setYTitle: @"abc" at:K_LEFT_YAXIS];
    [self.mSiglePlot show:NO onView:self.view];
    self.mDualPlot = [[GraphView alloc] initWithFrame:[layout getSize:LOWER_GRAPH] axis:2];
    [self.mDualPlot setXTitle: @"time(unit: 1 second)"];
    [self.mDualPlot setYTitle: @"abc" at:K_LEFT_YAXIS];
    [self.mDualPlot setYTitle: @"cde" at:K_RIGHT_YAXIS];
    [self.mDualPlot show:NO onView:self.view];
    
    [self initViewObjs];
    
    devicePopupList = [[DeviceListPopupView alloc] initPopupOnView:self.view];
    [devicePopupList.view setFrame:[layout getSize:DEVICE_LIST]];
    
    // get data provider which provide data from bluetooth device
    if (dataProvider == nil){
        dataProvider = [(AppDelegate*)[[UIApplication sharedApplication] delegate] dataProvider];
        protocol = [(AppDelegate*)[[UIApplication sharedApplication] delegate] protocol];
        dataProvider.mainView = self;
        dataProvider.connectImage = (UIImageView*)[self getView:BT_CONNECT_IMG];
        [dataProvider.connectImage setHidden:![dataProvider bConnected]];
        
        dataProvider.listPopupView = devicePopupList;
    }
    
    // create timer to display data
    displayTimer = [NSTimer scheduledTimerWithTimeInterval:refreshRate
                                                    target:self
                                                  selector:@selector(displayData)
                                                  userInfo:nil
                                                   repeats:YES];
    
    loggingTimer = [NSTimer scheduledTimerWithTimeInterval:samplingInterval
                                                    target:self
                                                  selector:@selector(recordData)
                                                  userInfo:nil
                                                   repeats:YES];
    
    // create sample data
    sampleData = [[Samples alloc]initWithCapacity:maxSamples
                                 samplingInterval:samplingInterval
                                 continuousSaving:bContinuousSaving];
    
    // when the screen is landscape
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeRight ||
        orientation == UIInterfaceOrientationLandscapeLeft){
        [_backgroundImage setImage:landscape_background_img];
        [self objPositionWithOrientation:LANDSCAPE];
    } else {
        [self objPositionWithOrientation:PORTRAIT];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)putView:(id)view forKey:(ObjectID)id{
    [viewObjs setObject:view forKey:[NSNumber numberWithInt:id]];
}

- (id)getViewforKey:(ObjectID)id{
    return [viewObjs objectForKey:[NSNumber numberWithInt:id]];
}

// create view objects and register them into viewObjs dictionary
- (void)initViewObjs
{
    upBtnImage = [UIImage imageNamed:@"button_up.png"];
    downBtnImage = [UIImage imageNamed:@"button_down.png"];
    viewObjs = [NSMutableDictionary dictionaryWithCapacity:NUM_OF_OBJECTS];
    
    [self putView:self.view forKey:BACKGROUND];
    
    [self createButtonWithObjectID:AUTOHODE_BTN title:NSLocalizedString(@"menu_auto_hold",  @"AutoHold")    hidden:NO];
    [self createButtonWithObjectID:RELATIVE_BTN title:NSLocalizedString(@"menu_relative",   @"Relative")    hidden:NO];
    [self createButtonWithObjectID:RANGE_BTN    title:NSLocalizedString(@"menu_range",      @"Range")       hidden:NO];
    [self createButtonWithObjectID:MODE_BTN     title:NSLocalizedString(@"menu_mode",       @"Mode")        hidden:NO];
    [self createButtonWithObjectID:MENU_BTN     title:NSLocalizedString(@"menu_menu",       @"Menu")        hidden:NO];
    [self createButtonWithObjectID:LOGGING_BTN  title:NSLocalizedString(@"menu_logging",    @"Logging")     hidden:NO];
    [self createButtonWithObjectID:FUNC_BTN     title:NSLocalizedString(@"menu_func",       @"Func...")     hidden:NO];
    [self createButtonWithObjectID:GRAPH_BTN    title:NSLocalizedString(@"menu_graph",      @"Graph")       hidden:NO];
    
    [self createImageviewWithObjectID:BT_CONNECT_IMG imageFileName:@"bluetooth.png" mode:UIViewContentModeScaleAspectFill hidden:NO];
    
    [self createImageviewWithObjectID:FUNC_BTN_BACK imageFileName:@"button_background.png" mode:UIViewContentModeScaleToFill hidden:YES];
    [self createButtonWithObjectID:PEAK_BTN     title:NSLocalizedString(@"menu_peak",       @"1msPEAK")     hidden:YES];
    [self createButtonWithObjectID:SETUP_BTN    title:NSLocalizedString(@"menu_setup",      @"SET UP")      hidden:YES];
    [self createButtonWithObjectID:MAXMIN_BTN   title:NSLocalizedString(@"menu_maxmin",     @"MAX/MIN")     hidden:YES];
    [self createButtonWithObjectID:KHZ_BTN      title:NSLocalizedString(@"menu_khz",        @"1kHz")        hidden:YES];
    
    [self createImageviewWithObjectID:MENU_BTN_BACK imageFileName:@"button_background.png" mode:UIViewContentModeScaleToFill hidden:YES];
    [self createButtonWithObjectID:CONNECT_BTN  title:NSLocalizedString(@"menu_connect",    @"Connect")     hidden:YES];
    [self createButtonWithObjectID:SETTINGS_BTN title:NSLocalizedString(@"menu_settings",   @"Settings")    hidden:YES];
    [self createButtonWithObjectID:INFO_BTN     title:NSLocalizedString(@"menu_info",       @"Info.")       hidden:YES];
    
    [self createImageviewWithObjectID:LOG_BTN_BACK imageFileName:@"button_background.png"  mode:UIViewContentModeScaleToFill hidden:YES];
    [self createButtonWithObjectID:RECORD_BTN   title:NSLocalizedString(@"menu_record",     @"Record")      hidden:YES];
    [self createButtonWithObjectID:LOGS_BTN     title:NSLocalizedString(@"menu_logs",       @"Logs")        hidden:YES];
    [self createButtonWithObjectID:SD_LOGS_BTN  title:NSLocalizedString(@"menu_sdlogs",     @"SD Logs")     hidden:YES];
    [self createButtonWithObjectID:SD_MEM_BTN   title:NSLocalizedString(@"menu_sdmem",      @"SD MEM")      hidden:YES];

    [self createLabelWithObjectID:RECORD_TXT            title:@"10 samples" align:NSTextAlignmentLeft   color:[UIColor redColor]];
    [self createLabelWithObjectID:SUB_LCD_NUMBER_TXT    title:@"0.0000"     align:NSTextAlignmentRight  color:[UIColor redColor]];
    [self createLabelWithObjectID:MAIN_LCD_NUMBER_TXT   title:@"0.0000"     align:NSTextAlignmentRight  color:[UIColor blueColor]];
    [self createLabelWithObjectID:SUB_LCD_UNIT_TXT      title:@"Hz"         align:NSTextAlignmentLeft   color:[UIColor blackColor]];
    [self createLabelWithObjectID:MAIN_LCD_UNIT_TXT     title:@"mV"         align:NSTextAlignmentLeft   color:[UIColor blackColor]];
    [self createLabelWithObjectID:SUB_LCD_MODE_TXT      title:@"Mode"       align:NSTextAlignmentLeft   color:[UIColor blackColor]];
    [self createLabelWithObjectID:MAIN_LCD_MODE_TXT     title:@"Mode"       align:NSTextAlignmentLeft   color:[UIColor blackColor]];
    
    [self createLabelWithObjectID:SUB_LCD_ACDC_TXT      title:@"AC"         align:NSTextAlignmentLeft   color:[UIColor blackColor]];
    [self createLabelWithObjectID:MAIN_LCD_ACDC_TXT     title:@"AC+DC"      align:NSTextAlignmentLeft   color:[UIColor blackColor]];
    [self createLabelWithObjectID:AUTO_TXT              title:NSLocalizedString(@"menu_auto", @"AUTO")  align:NSTextAlignmentLeft   color:[UIColor blueColor]];
    [self createLabelWithObjectID:APO_TXT               title:NSLocalizedString(@"menu_apo", @"APO")    align:NSTextAlignmentLeft   color:[UIColor blueColor]];
    [self createLabelWithObjectID:LOW_BAT_TXT           title:NSLocalizedString(@"menu_low_bat", @"Low Bat")        align:NSTextAlignmentLeft   color:[UIColor blueColor]];
    [self createLabelWithObjectID:AHOLD_TXT             title:@"A-HOLD"     align:NSTextAlignmentLeft   color:[UIColor blueColor]];
    [self createLabelWithObjectID:MAXMIN_TXT            title:@"MAX/MIN/AVG"  align:NSTextAlignmentLeft color:[UIColor blueColor]];
}

// create a new label
- (UILabel*)createLabelWithObjectID:(ObjectID)objID title:(NSString*)title align:(NSTextAlignment)alignment color:(UIColor*)color
{
    UILabel *label = [[UILabel alloc] init];
    
    label.text = title;
    label.opaque = NO;
    label.textAlignment = alignment;
    label.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    label.frame = [layout getSize:objID];
    label.font = [UIFont boldSystemFontOfSize:[layout getTextSize:objID]];
    label.tag = objID;
    label.textColor = color;
    label.adjustsFontSizeToFitWidth = YES;
    
    [self.view addSubview:label];
    [viewObjs setObject:label forKey:[NSNumber numberWithInt:objID]];
    
    return label;
}

// create the button object
- (void)createButtonWithObjectID:(ObjectID)objID title:(NSString*)title hidden:(Boolean)bHidden
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    // position in the parent view and set the size of the button
    button.frame = [layout getSize:objID];
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:[layout getTextSize:objID]]];
    button.tag = objID;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    // Add image to button for normal state
    [button setBackgroundImage:upBtnImage forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    
    // Add image to button for pressed state
    [button setBackgroundImage:downBtnImage forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
    [button setTitle:title forState:UIControlStateHighlighted];
    
    // add targets and actions
    [button addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    switch(objID){
        case AUTOHODE_BTN: case RELATIVE_BTN: case RANGE_BTN: case MODE_BTN: case PEAK_BTN:
        case SETUP_BTN: case SD_MEM_BTN: case MAXMIN_BTN:
            [button addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longClick:)]];
        default: break;
    }
    
    // add to a some parent view.
    [self.view addSubview:button];
    [button setHidden:bHidden];
    [self putView:button forKey:objID];
}
         
// create a new image view
// mode: UIViewContentModeScaleAspectFill, UIViewContentModeScaleToFill
- (void)createImageviewWithObjectID:(ObjectID)objID imageFileName:(NSString*)fileName
                               mode:(UIViewContentMode)mode hidden:(Boolean)bHidden
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:fileName]];
    
    imageView.frame = [layout getSize:objID];
    imageView.contentMode = mode;
    
    [self.view addSubview:imageView];
    [imageView setHidden:bHidden];
    [viewObjs setObject:imageView forKey:[NSNumber numberWithInt:objID]];
}

- (void)show2Graph
{
    b2GraphShow = !b2GraphShow;
    if (b1GraphShow && !b2GraphShow) b1GraphShow = false;
    if (b2GraphShow){
        _mDualPlot.frame = [layout getSize:LOWER_GRAPH];
    }
    [_mDualPlot show:b2GraphShow onView:self.view];
    [_mSiglePlot show:b2GraphShow onView:self.view];

    if (_mDualPlot.bShow)
        [self slideShow:BACKGROUND from:[layout getSize:BACKGROUND] to:[layout getSize:BACKGROUND_DOWN]];
    else
        [self slideShow:BACKGROUND from:[layout getSize:BACKGROUND_DOWN] to:[layout getSize:BACKGROUND]];
    
    if (_mDualPlot.bShow){
        [_mDualPlot reset];
        [_mSiglePlot reset];
    }

    [self changeButtonState:GRAPH_BTN pressed:_mDualPlot.bShow];
}

- (void)show1Graph
{
    b1GraphShow = !b1GraphShow;
    if (b2GraphShow){
        b2GraphShow = false;
        [_mDualPlot show:b2GraphShow onView:self.view];
        [_mSiglePlot show:b2GraphShow onView:self.view];

        [self slideShow:BACKGROUND from:[layout getSize:BACKGROUND_DOWN] to:[layout getSize:BACKGROUND]];
    }
    if(b1GraphShow) {
        _mDualPlot.frame = [layout getSize:GRAPH];
    }
    [_mDualPlot show:b1GraphShow onView:self.view];
}

- (void)showLogging
{
    if (bMenuShow) [self showMenu];
    if (bFuncBtnShow) [self showFuncBtn];
    
    bLogShow = !bLogShow;
    [self changeButtonState:LOGGING_BTN pressed:bLogShow];
    
    int deltaY = [layout getSize:RECORD_BTN].size.height;
    if (bLogShow){
        [self slideShow:LOG_BTN_BACK   from:[self makeDeltaFrame:LOG_BTN_BACK deltaY:deltaY]
                     to:[layout getSize:LOG_BTN_BACK]];
        [self slideShow:RECORD_BTN        from:[self makeDeltaFrame:RECORD_BTN deltaY:deltaY]
                     to:[layout getSize:RECORD_BTN]];
        [self slideShow:LOGS_BTN       from:[self makeDeltaFrame:LOGS_BTN deltaY:deltaY]
                     to:[layout getSize:LOGS_BTN]];
        [self slideShow:SD_LOGS_BTN      from:[self makeDeltaFrame:SD_LOGS_BTN deltaY:deltaY]
                     to:[layout getSize:SD_LOGS_BTN]];
        [self slideShow:SD_MEM_BTN      from:[self makeDeltaFrame:SD_MEM_BTN deltaY:deltaY]
                     to:[layout getSize:SD_MEM_BTN]];
    } else {
        [self slideHide:LOG_BTN_BACK   from:[layout getSize:LOG_BTN_BACK]
                     to:[self makeDeltaFrame:LOG_BTN_BACK deltaY:deltaY]];
        [self slideHide:RECORD_BTN        from:[layout getSize:RECORD_BTN]
                     to:[self makeDeltaFrame:RECORD_BTN deltaY:deltaY]];
        [self slideHide:LOGS_BTN       from:[layout getSize:LOGS_BTN]
                     to:[self makeDeltaFrame:LOGS_BTN deltaY:deltaY]];
        [self slideHide:SD_LOGS_BTN      from:[layout getSize:SD_LOGS_BTN]
                     to:[self makeDeltaFrame:SD_LOGS_BTN deltaY:deltaY]];
        [self slideHide:SD_MEM_BTN      from:[layout getSize:SD_MEM_BTN]
                     to:[self makeDeltaFrame:SD_MEM_BTN deltaY:deltaY]];
    }
}

- (void)showMenu
{
    if (bLogShow) [self showLogging];
    if (bFuncBtnShow) [self showFuncBtn];
    
    bMenuShow = !bMenuShow;
    [self changeButtonState:MENU_BTN pressed:bMenuShow];
    
    int deltaY = [layout getSize:CONNECT_BTN].size.height;
    if (bMenuShow){
        [self slideShow:MENU_BTN_BACK   from:[self makeDeltaFrame:MENU_BTN_BACK deltaY:deltaY]
                     to:[layout getSize:MENU_BTN_BACK]];
        [self slideShow:CONNECT_BTN        from:[self makeDeltaFrame:CONNECT_BTN deltaY:deltaY]
                     to:[layout getSize:CONNECT_BTN]];
        [self slideShow:SETTINGS_BTN       from:[self makeDeltaFrame:SETTINGS_BTN deltaY:deltaY]
                     to:[layout getSize:SETTINGS_BTN]];
        [self slideShow:INFO_BTN      from:[self makeDeltaFrame:INFO_BTN deltaY:deltaY]
                     to:[layout getSize:INFO_BTN]];
    } else {
        [self slideHide:MENU_BTN_BACK   from:[layout getSize:MENU_BTN_BACK]
                     to:[self makeDeltaFrame:MENU_BTN_BACK deltaY:deltaY]];
        [self slideHide:CONNECT_BTN        from:[layout getSize:CONNECT_BTN]
                     to:[self makeDeltaFrame:CONNECT_BTN deltaY:deltaY]];
        [self slideHide:SETTINGS_BTN       from:[layout getSize:SETTINGS_BTN]
                     to:[self makeDeltaFrame:SETTINGS_BTN deltaY:deltaY]];
        [self slideHide:INFO_BTN      from:[layout getSize:INFO_BTN]
                     to:[self makeDeltaFrame:INFO_BTN deltaY:deltaY]];
    }
}

- (CGRect)makeDeltaFrame:(ObjectID)id deltaY:(int)delY
{
    CGRect frame = [layout getSize:id];
    frame.origin.y += delY;
    
    return frame;
}

- (void)changeButtonState:(ObjectID)buttonId pressed:(bool)bPressed
{
    [(UIButton*)[self getView:buttonId] setTitleColor:(bPressed ? [UIColor greenColor] : [UIColor whiteColor]) forState:UIControlStateNormal];
}

- (void)showFuncBtn
{
    if (bMenuShow) [self showMenu];
    if (bLogShow) [self showLogging];
    
    bFuncBtnShow = !bFuncBtnShow;
    
    [self changeButtonState:FUNC_BTN pressed:bFuncBtnShow];
    int deltaY = [layout getSize:PEAK_BTN].size.height;
    if (bFuncBtnShow){
        [self slideShow:FUNC_BTN_BACK   from:[self makeDeltaFrame:FUNC_BTN_BACK deltaY:deltaY]
                     to:[layout getSize:FUNC_BTN_BACK]];
        [self slideShow:PEAK_BTN        from:[self makeDeltaFrame:PEAK_BTN deltaY:deltaY]
                     to:[layout getSize:PEAK_BTN]];
        [self slideShow:SETUP_BTN       from:[self makeDeltaFrame:SETUP_BTN deltaY:deltaY]
                     to:[layout getSize:SETUP_BTN]];
        [self slideShow:MAXMIN_BTN      from:[self makeDeltaFrame:MAXMIN_BTN deltaY:deltaY]
                     to:[layout getSize:MAXMIN_BTN]];
        [self slideShow:KHZ_BTN         from:[self makeDeltaFrame:KHZ_BTN deltaY:deltaY]
                     to:[layout getSize:KHZ_BTN]];
    } else {
        [self slideHide:FUNC_BTN_BACK   from:[layout getSize:FUNC_BTN_BACK]
                     to:[self makeDeltaFrame:FUNC_BTN_BACK deltaY:deltaY]];
        [self slideHide:PEAK_BTN        from:[layout getSize:PEAK_BTN]
                     to:[self makeDeltaFrame:PEAK_BTN deltaY:deltaY]];
        [self slideHide:SETUP_BTN       from:[layout getSize:SETUP_BTN]
                     to:[self makeDeltaFrame:SETUP_BTN deltaY:deltaY]];
        [self slideHide:MAXMIN_BTN      from:[layout getSize:MAXMIN_BTN]
                     to:[self makeDeltaFrame:MAXMIN_BTN deltaY:deltaY]];
        [self slideHide:KHZ_BTN         from:[layout getSize:KHZ_BTN]
                     to:[self makeDeltaFrame:KHZ_BTN deltaY:deltaY]];
    }
}

- (void)connectStatus:(BOOL)bConnected
{
    UIButton *connectBtn = [viewObjs objectForKey:[NSNumber numberWithInt:CONNECT_BTN]];
    NSString *title = bConnected ? NSLocalizedString(@"menu_disconnect", @"Disconnect") :
                                    NSLocalizedString(@"menu_connect", @"Connect");

    [connectBtn setTitle:title forState:UIControlStateNormal];
    [connectBtn setTitle:title forState:UIControlStateHighlighted];
}

- (IBAction)longClick:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan){
        if (_bButtonSound) AudioServicesPlaySystemSound(_button_click_sound_ssid);
        if (_bButtonVibration) AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        
        switch(sender.view.tag){
            case AUTOHODE_BTN:
                [dataProvider send:KEYCODE_LONG_HOLD length:5];
                break;
            case RELATIVE_BTN:
                [dataProvider send:KEYCODE_LONG_REL length:5];
                break;
            case RANGE_BTN:
                [dataProvider send:KEYCODE_LONG_RANGE length:5];
                break;
            case MODE_BTN:
                [dataProvider send:KEYCODE_LONG_MODE length:5];
                break;
            case PEAK_BTN:
                [dataProvider send:KEYCODE_LONG_PEAK length:5];
                break;
            case SETUP_BTN:
                [dataProvider send:KEYCODE_LONG_SETUP length:5];
                break;
            case SD_MEM_BTN:
                [dataProvider send:KEYCODE_LONG_MEM length:5];
                break;
            case MAXMIN_BTN:
                [dataProvider send:KEYCODE_LONG_MINMAX length:5];
                break;
        }
    }
}

- (void)click:(UIButton*)sender{
    if (_bButtonSound) AudioServicesPlaySystemSound(_button_click_sound_ssid);
    if (_bButtonVibration) AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);

    switch (sender.tag) {
        case FUNC_BTN:
            [self showFuncBtn];
            break;
        case GRAPH_BTN:
            [self show2Graph];
            break;
        case RANGE_BTN:
            [dataProvider send:KEYCODE_RANGE length:5];
            break;
        case AUTOHODE_BTN:
            [dataProvider send:KEYCODE_HOLD length:5];
            break;
        case RELATIVE_BTN:
            [dataProvider send:KEYCODE_REL length:5];
            break;
        case PEAK_BTN:
            [dataProvider send:KEYCODE_PEAK length:5];
            break;
        case MODE_BTN:
            [dataProvider send:KEYCODE_MODE length:5];
            break;
        case MAXMIN_BTN:
            [dataProvider send:KEYCODE_MINMAX length:5];
            break;
        case SETUP_BTN:
            [dataProvider send:KEYCODE_SETUP length:5];
            break;
        case LOGGING_BTN:
            [self showLogging];
            break;
        case RECORD_BTN:
            [self showLogging];
            [self recordBtnAction];
            break;
        case LOGS_BTN:
            [self showLogging];
            if (bLogging)
                [self recordBtnAction];
            [self performSegueWithIdentifier:@"logListViewSegue" sender:self];
            break;
        case SD_MEM_BTN:
            [dataProvider send:KEYCODE_MEM length:5];
            break;
        case MENU_BTN:
            [self showMenu];
            break;
        case INFO_BTN:
            [self performSegueWithIdentifier:@"infoViewSegue" sender:self];
            break;
        case SETTINGS_BTN:
            [self performSegueWithIdentifier:@"settingsViewSegue" sender:self];
            break;
        case CONNECT_BTN:
            [self showMenu];
            if ([dataProvider bConnected])
                [dataProvider disconnect];
            else
                [dataProvider connect];
            break;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    switch(interfaceOrientation){
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
            [_backgroundImage setImage:portrait_background_img];
            [self objPositionWithOrientation:PORTRAIT];
            if (b2GraphShow)
                [self slideShow:BACKGROUND from:[layout getSize:BACKGROUND] to:[layout getSize:BACKGROUND_DOWN]];
            else
                [self slideShow:BACKGROUND from:[layout getSize:BACKGROUND_DOWN] to:[layout getSize:BACKGROUND]];
            
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [_backgroundImage setImage:landscape_background_img];
            [self objPositionWithOrientation:LANDSCAPE];
            ((UIView*)[self getViewforKey:BACKGROUND]).frame = [layout getSize:BACKGROUND];
            
            break;
        default:
            break;
    }
}

- (void)objPositionWithOrientation:(Orientation)orientation
{
    [layout setOrientation:orientation];
    for (NSNumber *key in viewObjs){
        UIView *viewObj = [viewObjs objectForKey:key];
        viewObj.frame = [layout getSize:[key intValue]];
        
        if ([layout getObjType:(ObjectID)viewObj.tag] == BUTTON_TYPE){
            if (UIAccessibilityIsBoldTextEnabled())
                [((UIButton*)viewObj).titleLabel setFont:[UIFont systemFontOfSize:[layout getTextSize:(ObjectID)viewObj.tag]]];
            else
                [((UIButton*)viewObj).titleLabel setFont:[UIFont boldSystemFontOfSize:[layout getTextSize:(ObjectID)viewObj.tag]]];
            
        } else if ([layout getObjType:(ObjectID)viewObj.tag] == LABEL_TYPE){
            if (UIAccessibilityIsBoldTextEnabled())
                [((UILabel*)viewObj) setFont:[UIFont systemFontOfSize:[layout getTextSize:(ObjectID)viewObj.tag]]];
            else
                [((UILabel*)viewObj) setFont:[UIFont boldSystemFontOfSize:[layout getTextSize:(ObjectID)viewObj.tag]]];
        }
    }
    
    [self.mSiglePlot reFrame:[layout getSize:UPPER_GRAPH]];
    [self.mDualPlot reFrame:[layout getSize:LOWER_GRAPH]];
    [devicePopupList.view setFrame:[layout getSize:DEVICE_LIST]];
}

- (void)slideShow:(ObjectID)id from:(CGRect)fromFrame to:(CGRect)toFrame
{
    ((UIView*)[self getViewforKey:id]).frame = fromFrame;
    [[self getViewforKey:id] setHidden:NO];
    [UIView animateWithDuration:0.5 animations:^{((UIView*)[self getViewforKey:id]).frame = toFrame;}];
}

- (void)slideHide:(ObjectID)id from:(CGRect)fromFrame to:(CGRect)toFrame
{
    ((UIView*)[self getViewforKey:id]).frame = fromFrame;
    [UIView animateWithDuration:0.5 animations:^{((UIView*)[self getViewforKey:id]).frame = toFrame;}
                     completion:^(BOOL finished){((UIView*)[self getViewforKey:id]).hidden = finished;}];
}

// get view object by object id
- (UIView*)getView:(ObjectID)objID
{
    return [viewObjs objectForKey:[NSNumber numberWithInt:objID]];
}

- (void)recordBtnAction
{
    bLogging = !bLogging;
    if (bLogging){
        [sampleData startWriteToFile];
        [(UIButton*)[self getView:RECORD_BTN] setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    } else {
        [sampleData endWriteToFile];
        [(UIButton*)[self getView:RECORD_BTN] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

- (void)recordData
{
    if (bLogging){
        if (dataProvider.bConnected){
            if ([sampleData addSamples:[protocol getMeasuredValue] olValues:[protocol getOFLvalue]]){
                return; // loggging is successful.
            }
        }
        
        // logging fails
        [(UIButton*)[self getView:RECORD_BTN] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        bLogging = !bLogging;
    }
}

- (void)displayData
{
    if ([sampleData.modes[MAIN_LCD] intValue] != [protocol.modes[MAIN_LCD] intValue] ||
        [sampleData.modes[SUB_LCD] intValue] != [protocol.modes[SUB_LCD] intValue] ||
        ![sampleData.unitStrings[MAIN_LCD] isEqualToString:protocol.unitStrings[MAIN_LCD]] ||
        ![sampleData.unitStrings[SUB_LCD] isEqualToString:protocol.unitStrings[SUB_LCD]] ||
        ![sampleData.recFuncString isEqualToString:protocol.recFuncString]){
        [sampleData setMode:protocol.modes modeStrings:protocol.modeStrings unitStrings:protocol.unitStrings recFunc:protocol.recFuncString];
        [self.mDualPlot setYTitle:protocol.modeStrings[SUB1] at:K_LEFT_YAXIS];
        [self.mDualPlot setYTitle:protocol.modeStrings[SUB2] at:K_RIGHT_YAXIS];
        [self.mSiglePlot setYTitle:protocol.modeStrings[MAIN_LCD] at:K_LEFT_YAXIS];

        [self.mDualPlot reset];
        [self.mSiglePlot reset];
        
    }
    
    if (b2GraphShow || b1GraphShow){
        [self.mDualPlot insertLeftData:[protocol measuredValue:SUB1] rightValue:[protocol measuredValue:SUB2]];
        [self.mSiglePlot insertLeftData:[protocol measuredValue:MAIN_LCD] rightValue:0.0];
    }
    
    // display Icon
    [(UILabel*)[self getView:AHOLD_TXT] setText:protocol.aHoldString];
    [(UILabel*)[self getView:MAXMIN_TXT] setText:protocol.recFuncString];
    [[self getView:APO_TXT] setHidden:protocol.bApo ? NO : YES];
    [[self getView:AUTO_TXT] setHidden:protocol.bAuto ? NO : YES];
    [[self getView:LOW_BAT_TXT] setHidden:protocol.bLowBat ? NO : YES];
    
    // display number, mode, unit string
    [(UILabel*)[self getView:SUB_LCD_NUMBER_TXT] setText:[protocol valueString:SUB_LCD]];
    [(UILabel*)[self getView:MAIN_LCD_NUMBER_TXT] setText:[protocol valueString:MAIN_LCD]];
    [(UILabel*)[self getView:SUB_LCD_MODE_TXT] setText:protocol.modeStrings[SUB_LCD]];
    [(UILabel*)[self getView:MAIN_LCD_MODE_TXT] setText:protocol.modeStrings[MAIN_LCD]];
    [(UILabel*)[self getView:SUB_LCD_UNIT_TXT] setText:protocol.unitStrings[SUB_LCD]];
    [(UILabel*)[self getView:MAIN_LCD_UNIT_TXT] setText:protocol.unitStrings[MAIN_LCD]];
    [(UILabel*)[self getView:SUB_LCD_ACDC_TXT] setText:[protocol acdcString:SUB_LCD]];
    [(UILabel*)[self getView:MAIN_LCD_ACDC_TXT] setText:[protocol acdcString:MAIN_LCD]];

    [self changeButtonState:RELATIVE_BTN pressed:protocol.bRel];
    [self changeButtonState:PEAK_BTN pressed:protocol.bMs];
    [self changeButtonState:KHZ_BTN pressed:protocol.bKhz];
    [self changeButtonState:SD_MEM_BTN pressed:protocol.mem != 0];
    [self changeButtonState:MAXMIN_BTN pressed:protocol.recFunc != 0];
    [self changeButtonState:AUTOHODE_BTN pressed:protocol.aHold != 0];
    
    if (bLogging)
        [(UILabel*)[self getView:RECORD_TXT] setText:[NSString stringWithFormat:@"%i %@",(int)[sampleData count], NSLocalizedString(@"samples", @"samples")]];
    else
        [(UILabel*)[self getView:RECORD_TXT] setText:@""];

}

@end
