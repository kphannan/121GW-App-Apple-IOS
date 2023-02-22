//
//  GraphView.h
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"



@interface GraphView : UIView <CPTPlotDataSource, CPTPlotSpaceDelegate>

@property Boolean bShow;            // does the graph show ?

- (id)initWithFrame:(CGRect)frame axis:(int)nAxis;
- (void)insertLeftData:(double)lValue rightValue:(double)rValue;
- (void)insertLeftDataList:(NSArray*)lDataList rightDataList:(NSArray*)rDataList;
- (void)saveGraphIntoFile:(NSString*)fileName path:(NSString*)path format:(int)format;

- (void)show:(Boolean)bShow onView:(UIView*)view;
- (void)reFrame:(CGRect)frame;
- (void)reset;
- (void)setXTitle:(NSString*)title;
- (void)setYTitle:(NSString*)title at:(int)pos;

@end

#define K_PNG_FORMAT                1
#define K_JPG_FORMAT                2
#define K_X_AXIS_TICK_INTERVAL      10         // length of tick's interval on X Axis

// yAxisNum values
#define K_LEFT_YAXIS                0
#define K_RIGHT_YAXIS               1
