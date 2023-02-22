//
//  LayoutManager.m
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import "LayoutManager.h"

@implementation ObjectInfo

- initWithRatio:(NSArray*)ratios
{
    self = [super init];
    if (self == nil) return nil;
    
    portrait_x_ratio = [(NSNumber*)[ratios objectAtIndex:0] floatValue];
    portrait_y_ratio = [(NSNumber*)[ratios objectAtIndex:1] floatValue];
    portrait_w_ratio = [(NSNumber*)[ratios objectAtIndex:2] floatValue];
    portrait_h_ratio = [(NSNumber*)[ratios objectAtIndex:3] floatValue];
    landscape_x_ratio = [(NSNumber*)[ratios objectAtIndex:4] floatValue];
    landscape_y_ratio = [(NSNumber*)[ratios objectAtIndex:5] floatValue];
    landscape_w_ratio = [(NSNumber*)[ratios objectAtIndex:6] floatValue];
    landscape_h_ratio = [(NSNumber*)[ratios objectAtIndex:7] floatValue];
    
    return self;
}

// to prevent the blurred text, position's value and size's value is rounded into integer
- (void)calculateWithScreenSize:(CGSize)screenSize
{
    self.landscape_x = (int)(screenSize.height * landscape_x_ratio);
    self.landscape_y = (int)(screenSize.width  * landscape_y_ratio);
    self.landscape_w = (int)(screenSize.height * landscape_w_ratio);
    self.landscape_h = (int)(screenSize.width  * landscape_h_ratio);
    
    self.portrait_x  = (int)(screenSize.width  * portrait_x_ratio);
    self.portrait_y  = (int)(screenSize.height * portrait_y_ratio);
    self.portrait_w  = (int)(screenSize.width  * portrait_w_ratio);
    self.portrait_h  = (int)(screenSize.height * portrait_h_ratio);
}

@end

@implementation LayoutManager

- (id)initWithScreenSize:(CGSize)screenSize
{
    self = [super init];
    if (self == nil) return nil;
    
    objectInfoMap = [NSMutableDictionary dictionaryWithCapacity:NUM_OF_OBJECTS];
    if (screenSize.width > screenSize.height){
        _screenSize.width = screenSize.height;
        _screenSize.height = screenSize.width;
        _orientation = LANDSCAPE;
    } else {
        _screenSize = screenSize;
        _orientation = PORTRAIT;
    }
    
    // register ralative position infomation of the objects
    [self setObjectPos:BACKGROUND posInfo:[NSArray arrayWithObjects:
                                        @0.000,		@0.000,		@1.000,		@1.000,
                                        @0.000,		@0.000,		@1.000,		@1.000,     nil]];
    [self setObjectPos:BACKGROUND_DOWN posInfo:[NSArray arrayWithObjects:
                                        @0.000,		@0.083,		@1.000,		@1.000,
                                        @0.000,		@0.000,		@1.000,		@1.000,     nil]];
    [self setObjectPos:AUTOHODE_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.024,     @0.312,     @0.222,     @0.052,
                                        @0.016,	    @0.884,     @0.128,     @0.092,     nil]];
    [self setObjectPos:RELATIVE_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.266,     @0.312,     @0.222,     @0.052,
                                        @0.155,	    @0.884,     @0.128,     @0.092,     nil]];
    [self setObjectPos:RANGE_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.506,     @0.312,     @0.222,     @0.052,
                                        @0.295,	    @0.884,     @0.128,     @0.092,     nil]];
    [self setObjectPos:MODE_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.748,     @0.312,     @0.222,     @0.052,
                                        @0.435,	    @0.884,     @0.128,     @0.092,     nil]];
    [self setObjectPos:MENU_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.024,	    @0.852,     @0.222,     @0.052,
                                        @1.000,	    @1.000,     @0.128,     @0.092,     nil]];
    [self setObjectPos:LOGGING_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.266,	    @0.852,     @0.222,     @0.052,
                                        @0.576,	    @0.884,     @0.128,     @0.092,     nil]];
    [self setObjectPos:FUNC_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.506,	    @0.852,     @0.222,     @0.052,
                                        @0.715,	    @0.884,     @0.128,     @0.092,     nil]];
    [self setObjectPos:GRAPH_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.748,	    @0.852,     @0.222,     @0.052,
                                        @0.856,	    @0.884,     @0.128,     @0.092,     nil]];
    
    [self setObjectPos:FUNC_BTN_BACK posInfo:[NSArray arrayWithObjects:
                                        @0.000,     @0.749,     @1.000,     @0.083,
                                        @0.418,	    @0.704,     @0.582,     @0.152,     nil]];
    [self setObjectPos:PEAK_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.024,	    @0.767,     @0.222,     @0.052,
                                        @0.435,	    @0.736,     @0.128,     @0.092,     nil]];
    [self setObjectPos:SETUP_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.266,	    @0.767,     @0.222,     @0.052,
                                        @0.576,	    @0.736,     @0.128,     @0.092,     nil]];
    [self setObjectPos:MAXMIN_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.506,	    @0.767,     @0.222,     @0.052,
                                        @0.715,	    @0.736,     @0.128,     @0.092,     nil]];
    [self setObjectPos:KHZ_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.748,	    @0.767,     @0.222,     @0.052,
                                        @0.856,	    @0.736,     @0.128,     @0.092,     nil]];
    
    [self setObjectPos:MENU_BTN_BACK posInfo:[NSArray arrayWithObjects:
                                        @0.000,     @0.749,     @0.842,     @0.083,
                                        @0.418,	    @0.704,     @0.504,     @0.152,     nil]];
    [self setObjectPos:CONNECT_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.024,	    @0.767,     @0.252,     @0.052,
                                        @0.435,	    @0.736,     @0.148,     @0.092,     nil]];
    [self setObjectPos:SETTINGS_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.296,	    @0.767,     @0.252,     @0.052,
                                        @0.596,	    @0.736,     @0.148,     @0.092,     nil]];
    [self setObjectPos:INFO_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.566,	    @0.767,     @0.252,     @0.052,
                                        @0.755,	    @0.736,     @0.148,     @0.092,     nil]];
    
    [self setObjectPos:LOG_BTN_BACK posInfo:[NSArray arrayWithObjects:
                                        @0.000,     @0.749,     @1.000,     @0.083,
                                        @0.418,	    @0.704,     @0.582,     @0.152,     nil]];
    [self setObjectPos:RECORD_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.024,	    @0.767,     @0.222,     @0.052,
                                        @0.435,	    @0.736,     @0.128,     @0.092,     nil]];
    [self setObjectPos:LOGS_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.266,	    @0.767,     @0.222,     @0.052,
                                        @0.576,	    @0.736,     @0.128,     @0.092,     nil]];
    [self setObjectPos:SD_LOGS_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.506,	    @0.767,     @0.222,     @0.052,
                                        @0.715,	    @0.736,     @0.128,     @0.092,     nil]];
    [self setObjectPos:SD_MEM_BTN posInfo:[NSArray arrayWithObjects:
                                        @0.748,	    @0.767,     @0.222,     @0.052,
                                        @0.856,	    @0.736,     @0.128,     @0.092,     nil]];
    
    [self setObjectPos:BT_CONNECT_IMG posInfo:[NSArray arrayWithObjects:
                                        @0.060,	    @0.414,     @0.054,     @0.036,
                                        @0.058,	    @0.076,     @0.046,     @0.068,     nil]];
    [self setObjectPos:RECORD_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.068,	    @0.443,     @0.300,     @0.040,
                                        @0.068,	    @0.168,     @0.300,     @0.090,     nil]];
    [self setObjectPos:SUB_LCD_NUMBER_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.298,	    @0.486,     @0.574,     @0.120,
                                        @0.316,	    @0.198,     @0.493,     @0.250,     nil]];
    [self setObjectPos:MAIN_LCD_NUMBER_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.178,	    @0.620,     @0.696,     @0.160,
                                        @0.213,	    @0.430,     @0.596,     @0.350,     nil]];
    [self setObjectPos:SUB_LCD_UNIT_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.870,	    @0.550,     @0.110,     @0.040,
                                        @0.810,	    @0.306,     @0.110,     @0.090,     nil]];
    [self setObjectPos:MAIN_LCD_UNIT_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.870,	    @0.713,     @0.110,     @0.040,
                                        @0.810,	    @0.632,     @0.110,     @0.090,     nil]];
    [self setObjectPos:SUB_LCD_MODE_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.394,	    @0.478,     @0.500,     @0.030,
                                        @0.480,	    @0.170,     @0.342,     @0.070,     nil]];
    [self setObjectPos:MAIN_LCD_MODE_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.394,	    @0.611,     @0.400,     @0.040,
                                        @0.480,	    @0.428,     @0.222,     @0.090,     nil]];
    [self setObjectPos:SUB_LCD_ACDC_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.214,	    @0.515,     @0.072,     @0.030,
                                        @0.370,	    @0.234,     @0.052,     @0.070,     nil]];
    [self setObjectPos:MAIN_LCD_ACDC_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.005,	    @0.652,     @0.200,     @0.040,
                                        @0.150,	    @0.524,     @0.200,     @0.090,     nil]];
    [self setObjectPos:AUTO_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.170,	    @0.414,     @0.150,     @0.040,
                                        @0.170,	    @0.074,     @0.150,     @0.090,     nil]];
    [self setObjectPos:APO_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.348,	    @0.414,     @0.112,     @0.040,
                                        @0.348,	    @0.074,     @0.112,     @0.090,     nil]];
    [self setObjectPos:LOW_BAT_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.500,	    @0.414,     @0.300,     @0.040,
                                        @0.500,	    @0.074,     @0.300,     @0.090,     nil]];
    [self setObjectPos:AHOLD_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.750,	    @0.414,     @0.250,     @0.040,
                                        @0.750,	    @0.074,     @0.250,     @0.090,     nil]];
    [self setObjectPos:MAXMIN_TXT posInfo:[NSArray arrayWithObjects:
                                        @0.068,	    @0.763,     @0.418,     @0.040,
                                        @0.068,	    @0.720,     @0.418,     @0.090,     nil]];
    
    [self setObjectPos:GRAPH posInfo:[NSArray arrayWithObjects:
                                        @0.000,	    @0.000,     @1.000,     @0.295,
                                        @0.000,	    @0.000,     @1.000,     @0.852,     nil]];
    [self setObjectPos:UPPER_GRAPH posInfo:[NSArray arrayWithObjects:
                                        @0.000,	    @-0.083,     @1.000,     @0.231,
                                        @0.000,	    @0.000,     @0.500,     @0.852,     nil]];
    [self setObjectPos:LOWER_GRAPH posInfo:[NSArray arrayWithObjects:
                                        @0.000,     @0.148,     @1.000,     @0.231,
                                        @0.500,	    @0.000,     @0.500,     @0.852,     nil]];
    
    [self setObjectPos:LOG_EDIT_MODAL posInfo:[NSArray arrayWithObjects:
                                        @0.100,     @0.200,     @0.800,     @0.350,
                                        @0.200,	    @0.100,     @0.600,     @0.600,     nil]];
    [self setObjectPos:DEVICE_LIST posInfo:[NSArray arrayWithObjects:
                                        @0.100,     @0.344,     @0.800,     @0.350,
                                        @0.253,     @0.205,     @0.500,     @0.600,   nil]];
    
    for (NSNumber *objID in objectInfoMap){
        [[objectInfoMap objectForKey:objID] calculateWithScreenSize:_screenSize];
    }
    
    return self;
}

- (void)setObjectPos:(ObjectID)id posInfo:(NSArray*)info
{
    [objectInfoMap setObject:[[ObjectInfo alloc]initWithRatio:info] forKey:[NSNumber numberWithInt:id]];
}


- (CGRect)getSize:(ObjectID)objID
{
    CGRect frame;
    ObjectInfo *obj = [objectInfoMap objectForKey:[NSNumber numberWithInt:objID]];
    
    if (self.orientation == PORTRAIT){
        frame.origin.x = obj.portrait_x;
        frame.origin.y = obj.portrait_y;
        frame.size.width = obj.portrait_w;
        frame.size.height = obj.portrait_h;
    } else {
        frame.origin.x = obj.landscape_x;
        frame.origin.y = obj.landscape_y;
        frame.size.width = obj.landscape_w;
        frame.size.height = obj.landscape_h;
    }
    
    return frame;
}

- (int)getTextSize:(ObjectID)objID
{
    ObjectInfo *obj = [objectInfoMap objectForKey:[NSNumber numberWithInt:objID]];
    
    float viewHeight = (_orientation == PORTRAIT) ? obj.portrait_h : obj.landscape_h;
    
    if ([self getObjType:objID] == LABEL_TYPE)
        return (int)(viewHeight/1.3f);
    else if ([self getObjType:objID] == BUTTON_TYPE)
        return (int)(viewHeight/2.2f);
    else return 0;
}

- (ObjectType)getObjType:(ObjectID)objID
{
    switch(objID) {
        case BACKGROUND: case BACKGROUND_DOWN: case BT_CONNECT_IMG: case FUNC_BTN_BACK:
        case LOG_BTN_BACK: case MENU_BTN_BACK:
            return IMAGE_TYPE;
        case AUTOHODE_BTN: case RELATIVE_BTN: case RANGE_BTN: case MODE_BTN: case MENU_BTN:
        case LOGGING_BTN: case FUNC_BTN: case GRAPH_BTN: case PEAK_BTN: case SETUP_BTN:
        case MAXMIN_BTN: case KHZ_BTN: case CONNECT_BTN: case SETTINGS_BTN: case INFO_BTN:
        case RECORD_BTN: case LOGS_BTN: case SD_LOGS_BTN: case SD_MEM_BTN:
            return BUTTON_TYPE;
        case RECORD_TXT: case SUB_LCD_NUMBER_TXT: case MAIN_LCD_NUMBER_TXT: case SUB_LCD_UNIT_TXT:
        case MAIN_LCD_UNIT_TXT: case SUB_LCD_MODE_TXT: case MAIN_LCD_MODE_TXT: case SUB_LCD_ACDC_TXT:
        case MAIN_LCD_ACDC_TXT: case AUTO_TXT: case MAXMIN_TXT: case AHOLD_TXT: case APO_TXT: case LOW_BAT_TXT:
            return LABEL_TYPE;
        case GRAPH: case UPPER_GRAPH: case LOWER_GRAPH:
            return GRAPH_TYPE;
        case LOG_EDIT_MODAL: case DEVICE_LIST:
            return MODAL_TYPE;
    }
}

- (int)getScreenSizeWidth
{
    return self.orientation == PORTRAIT ? _screenSize.width : _screenSize.height;
}

- (int)getScreenSizeHeight
{
    return self.orientation == PORTRAIT ? _screenSize.height : _screenSize.width;
}


@end
