//
//  LayoutManager.h
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define NUM_OF_OBJECTS  50

typedef enum
{
    BACKGROUND, BACKGROUND_DOWN, AUTOHODE_BTN, RELATIVE_BTN, RANGE_BTN, MODE_BTN, MENU_BTN, LOGGING_BTN, FUNC_BTN, GRAPH_BTN,
    PEAK_BTN, SETUP_BTN, MAXMIN_BTN, KHZ_BTN,
    CONNECT_BTN, SETTINGS_BTN, INFO_BTN,
    RECORD_BTN, LOGS_BTN, SD_LOGS_BTN, SD_MEM_BTN,
    BT_CONNECT_IMG, RECORD_TXT, SUB_LCD_NUMBER_TXT, MAIN_LCD_NUMBER_TXT, SUB_LCD_UNIT_TXT, MAIN_LCD_UNIT_TXT,
    SUB_LCD_MODE_TXT, MAIN_LCD_MODE_TXT, SUB_LCD_ACDC_TXT, MAIN_LCD_ACDC_TXT,
    AUTO_TXT, MAXMIN_TXT, AHOLD_TXT, APO_TXT, LOW_BAT_TXT,
    GRAPH, UPPER_GRAPH, LOWER_GRAPH,
    FUNC_BTN_BACK, LOG_BTN_BACK, MENU_BTN_BACK,
    LOG_EDIT_MODAL, DEVICE_LIST } ObjectID;

typedef enum
{
    BUTTON_TYPE, LABEL_TYPE, IMAGE_TYPE, GRAPH_TYPE, MODAL_TYPE
} ObjectType;

typedef enum
{
    LANDSCAPE, PORTRAIT
} Orientation;

@interface ObjectInfo : NSObject
{
@private
    double portrait_x_ratio, portrait_y_ratio, portrait_w_ratio, portrait_h_ratio;
    double landscape_x_ratio, landscape_y_ratio, landscape_w_ratio, landscape_h_ratio;
}

@property float  landscape_x, landscape_y, portrait_x, portrait_y;
@property float	 landscape_w, landscape_h, portrait_w, portrait_h;

- initWithRatio:(NSArray*)ratios;
- (void)calculateWithScreenSize:(CGSize)screenSize;

@end

@interface LayoutManager : NSObject
{
@private
    NSMutableDictionary *objectInfoMap;
    CGSize _screenSize;
}

@property(nonatomic) Orientation orientation;

- initWithScreenSize:(CGSize)screenSize;
- (CGRect)getSize:(ObjectID)objID;
- (int)getTextSize:(ObjectID)objID;
- (ObjectType)getObjType:(ObjectID)objID;
- (int)getScreenSizeWidth;
- (int)getScreenSizeHeight;

@end
