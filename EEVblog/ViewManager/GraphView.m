//
//  GraphView.m
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import "GraphView.h"

#define Y_AXIS_COLOR    (yAxisNum == K_LEFT_YAXIS ? [CPTColor redColor] : [CPTColor blueColor])
#define NUM_Y_AXIS  2
#define SHOW_HIDE_BTN_WIDTH     60
#define SHOW_HIDE_BTN_HEIGHT    20

static int K_MAX_DISPLAY_DATA = 10000;            // max. number of data to display in the graph view
static int K_MIN_DISPLAY_DATA = 10;             // min. number of data to display; it is used in zoom mode

@interface GraphView()
{
    int minorTickInterval;                      // space(pixels) between minor ticks(one data is one minor tick)
    int majorTickInterval;                      // number of minorTick between major ticks
    NSMutableArray *plotData[NUM_Y_AXIS];       // data array
    NSUInteger maxXValue;                       // max value at the X axis
    int currentIndex;                           // current inserted data's index
    CGRect orgFrame;                            // original frame size; it is used to show view-sliding
    CPTMutableLineStyle *majorGridLineStyle;    // grid line style
    CPTMutableLineStyle *axisLineStyle;         // axis line style
    CPTXYAxis *xAxis, *yAxis[NUM_Y_AXIS];
    CPTScatterPlot *plots[NUM_Y_AXIS];
    CPTXYPlotSpace *plotSpace[NUM_Y_AXIS];
    float yMin[NUM_Y_AXIS], yMax[NUM_Y_AXIS];
    float lastScale;                            // for Zooming
    int zoomXpoint;                             // for Zooming
    int zoomDisplayPoints;                      // display points in zoom mode
    int zoomStartXpoint;                        // start x position in zoom mode; this is used to move the graph
    int lastMovePoint;                          // for moving
    
    int realStartXpoint;                        // start x position in real graph mode
    bool bIsRealMode;                           // real graph mode;

    bool bShowRightAxis, bShowLeftAxis;
    UIButton *rightAxisBtn, *leftAxisBtn;
    
    UIPinchGestureRecognizer    *pinchGesture;
    UIPanGestureRecognizer      *panGesture;
    
    NSMutableSet *xAxisMajorTickLocs;           // locations for X Axis's major tics locations
    NSMutableSet *xAxisMajorLabels;             // X Axis's labels in sample graph
    
    CPTMutableTextStyle *labelTextStyle;
    CPTMutableTextStyle *axisTitleStyle;
    NSString *XAxisTitle, *YAxisTitle[NUM_Y_AXIS];
    int _nAxis;                                  // number of Y Axis
}

@property (nonatomic, strong)CPTGraph *graph;
@property (nonatomic, strong)CPTGraphHostingView *graphView;

@property (nonatomic, strong)NSMutableSet *xMajorTickLocations;

@end

@implementation GraphView

// to dynamically insert data into the graph
- (id)initWithFrame:(CGRect)frame axis:(int)nAxis
{
    self = [super initWithFrame:frame];
    if (self){
        plotData[K_LEFT_YAXIS] = [[NSMutableArray alloc] init];
        plotData[K_RIGHT_YAXIS] = [[NSMutableArray alloc] init];
        
        self.backgroundColor = [UIColor whiteColor];
        _nAxis = nAxis;
        currentIndex = 0;
        zoomDisplayPoints = 0;
        zoomStartXpoint = 0;
        realStartXpoint = 0;
        _bShow = NO;
        bShowLeftAxis = bShowRightAxis = YES;
        orgFrame = frame;
        XAxisTitle = @"X axis title";
        YAxisTitle[K_LEFT_YAXIS] = @"Y left title";
        YAxisTitle[K_RIGHT_YAXIS] = @"Y right title";
        
        bIsRealMode = NO;
        
        minorTickInterval = 5;
        majorTickInterval = 1;
        xAxisMajorTickLocs = [NSMutableSet set];
        xAxisMajorLabels = [NSMutableSet set];
        
        // default y axis values
        yMin[K_LEFT_YAXIS] = 0.0;
        yMax[K_LEFT_YAXIS] = 1.0;
        yMin[K_RIGHT_YAXIS] = 0.0;
        yMax[K_RIGHT_YAXIS] = 1.0;
        
        labelTextStyle = [CPTMutableTextStyle textStyle];
        labelTextStyle.fontName = @"Helvetica-Bold";
        labelTextStyle.fontSize = 10.0;
        labelTextStyle.color = [CPTColor redColor];
        
        axisTitleStyle = [CPTMutableTextStyle textStyle];
        axisTitleStyle.color = [CPTColor blackColor];
        axisTitleStyle.fontName = @"Helvetica";
        axisTitleStyle.fontSize = 12.0f;
        
        [self initPlot:frame];
        
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoom:)];
        [self addGestureRecognizer: pinchGesture];
        
        panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
        [panGesture setMinimumNumberOfTouches:1];
        [panGesture setMaximumNumberOfTouches:1];
        [self addGestureRecognizer:panGesture];
        
        if (nAxis == 2){
            rightAxisBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [rightAxisBtn addTarget:self action:@selector(showHideRightAxis) forControlEvents:UIControlEventTouchDown];
            [rightAxisBtn setTitle:NSLocalizedString(@"graph_hide", @"Hide") forState:UIControlStateNormal];
            [rightAxisBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            rightAxisBtn.titleLabel.font = [UIFont systemFontOfSize:15];
            rightAxisBtn.frame = CGRectMake(frame.size.width-60, frame.size.height-20, SHOW_HIDE_BTN_WIDTH, SHOW_HIDE_BTN_HEIGHT);
            [self addSubview:rightAxisBtn];
            
            leftAxisBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [leftAxisBtn addTarget:self action:@selector(showHideLeftAxis) forControlEvents:UIControlEventTouchDown];
            [leftAxisBtn setTitle:NSLocalizedString(@"graph_hide", @"Hide") forState:UIControlStateNormal];
            [leftAxisBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            leftAxisBtn.titleLabel.font = [UIFont systemFontOfSize:15];
            leftAxisBtn.frame = CGRectMake(0, frame.size.height-20, SHOW_HIDE_BTN_WIDTH, SHOW_HIDE_BTN_HEIGHT);
            [self addSubview:leftAxisBtn];
        }
        
        [self reFrame:frame];
    }
    
    return self;
}

- (void)reFrame:(CGRect)frame
{
    orgFrame = frame;
    self.frame = frame;
    self.graphView.frame = CGRectMake(0,
                                      0, // to remove title's space
                                      frame.size.width,
                                      frame.size.height);
    if (!self.bShow){
        self.frame = CGRectMake(orgFrame.origin.x, -orgFrame.size.height,
                                orgFrame.size.width, orgFrame.size.height);
    }
    
    rightAxisBtn.frame = CGRectMake(frame.size.width-60, frame.size.height-20, SHOW_HIDE_BTN_WIDTH, SHOW_HIDE_BTN_HEIGHT);
    leftAxisBtn.frame = CGRectMake(0, frame.size.height-20, SHOW_HIDE_BTN_WIDTH, SHOW_HIDE_BTN_HEIGHT);
}

- (void)show:(Boolean)bShow onView:(UIView*)view
{
    if (bShow == _bShow) return;
    
    if (bShow){
        self.frame = CGRectMake(orgFrame.origin.x, -(orgFrame.size.height),
                                orgFrame.size.width, orgFrame.size.height);
        [view addSubview:self];
        [view bringSubviewToFront:self];
    }
    
    _bShow = bShow;
    
    NSInteger orginY;
    if (bShow) orginY = orgFrame.origin.y;
    else orginY = -orgFrame.size.height - 30;
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.frame = CGRectMake(orgFrame.origin.x, orginY,
                                                 orgFrame.size.width, orgFrame.size.height);
                     }];
}

- (void)zoom:(UIPinchGestureRecognizer *)sender {
    if ([sender numberOfTouches] < 2)
        return;
    
    int totalXPoints = (int)[plotData[K_LEFT_YAXIS] count];
    
    if (totalXPoints <= K_MIN_DISPLAY_DATA)  // 데이터가 작아서 확대가 안되는 경우
        return;

    if (sender.state == UIGestureRecognizerStateBegan) {
        lastScale = 1.0;
        CGPoint zoomPoint = [sender locationInView:self];
        if (zoomDisplayPoints == 0){
            zoomDisplayPoints = totalXPoints;
            zoomStartXpoint = 0;
        }
        zoomXpoint = (zoomPoint.x/orgFrame.size.width) * zoomDisplayPoints + zoomStartXpoint;
    }
    
    // Scale
    CGFloat scale = 1.0 - (lastScale - sender.scale);
    lastScale = sender.scale;
    
    int prevZoomDisplayPoints = zoomDisplayPoints;
    zoomDisplayPoints = zoomDisplayPoints/scale;
    if (zoomDisplayPoints > totalXPoints){      // 최대로 축소한 경우
        zoomDisplayPoints = totalXPoints;
        zoomXpoint = zoomDisplayPoints/2;
    } else if (zoomDisplayPoints < K_MIN_DISPLAY_DATA)    // 최대로 확대한 경우
        zoomDisplayPoints = (int)K_MIN_DISPLAY_DATA;
    
    if (prevZoomDisplayPoints == zoomDisplayPoints) // 확대/축소가 일어나지 않았음
        return;
    
    zoomStartXpoint = (int)(zoomXpoint - zoomDisplayPoints/2);
    if (zoomStartXpoint < 0) zoomStartXpoint = 0;
    
    CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:@(zoomStartXpoint)
                                                          length:@(zoomDisplayPoints)];
    
    yAxis[K_RIGHT_YAXIS].orthogonalPosition = @(zoomStartXpoint + zoomDisplayPoints);
    yAxis[K_LEFT_YAXIS].orthogonalPosition = @(zoomStartXpoint);
    
    plotSpace[K_LEFT_YAXIS].xRange = newRange;
    plotSpace[K_RIGHT_YAXIS].xRange = newRange;
    
    NSUInteger interval = zoomDisplayPoints / K_MIN_DISPLAY_DATA;
    if (interval == 0) interval = 1;
    if (zoomDisplayPoints % K_MIN_DISPLAY_DATA != 0) interval++;        // for round operation
    
    xAxisMajorTickLocs = [NSMutableSet set];
    xAxisMajorLabels = [NSMutableSet set];
    for (int location=0; location < totalXPoints; location+=interval){
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%d", location] textStyle:labelTextStyle];
        label.tickLocation = @(location);
        label.offset = -15.0f;
        
        [xAxisMajorTickLocs addObject:[NSNumber numberWithInt:location]];
        [xAxisMajorLabels addObject:label];
    }
    xAxis.axisLabels = xAxisMajorLabels;
    xAxis.majorTickLocations = xAxisMajorTickLocs;
}

- (void)move:(UIPanGestureRecognizer *)sender {
    int totalPoints = (int)[plotData[K_LEFT_YAXIS] count];
    
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self];
    if (sender.state == UIGestureRecognizerStateBegan) {
        lastMovePoint = translatedPoint.x;
    }
    
    // calculate moved amount(=length)
    CGFloat moveAmount = translatedPoint.x - lastMovePoint;
    lastMovePoint += ((int)moveAmount / minorTickInterval) * minorTickInterval;
    
    // in zooming mode
    if (zoomDisplayPoints != 0 && zoomDisplayPoints != totalPoints){
        zoomStartXpoint -= (int)moveAmount / minorTickInterval;
        if (zoomStartXpoint < 0)
            zoomStartXpoint = 0;
        else if (zoomStartXpoint + zoomDisplayPoints > totalPoints)
            zoomStartXpoint = totalPoints - zoomDisplayPoints;
    
        CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:@(zoomStartXpoint)
                                                              length:@(zoomDisplayPoints)];
    
        yAxis[K_RIGHT_YAXIS].orthogonalPosition = @(zoomStartXpoint + zoomDisplayPoints);
        yAxis[K_LEFT_YAXIS].orthogonalPosition = @(zoomStartXpoint);
    
        plotSpace[K_LEFT_YAXIS].xRange = newRange;
        plotSpace[K_RIGHT_YAXIS].xRange = newRange;
    }
    
    // in real graph mode
    if (bIsRealMode && totalPoints > self.frame.size.width/minorTickInterval){
        int displayPoints = self.frame.size.width / minorTickInterval;
        
        realStartXpoint -= (int)moveAmount / minorTickInterval;
        if (realStartXpoint < 0)
            realStartXpoint = 0;
        else if (realStartXpoint + displayPoints > totalPoints)
            realStartXpoint = totalPoints - displayPoints;
        
        CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:@(realStartXpoint)
                                                              length:@(displayPoints)];
        
        yAxis[K_LEFT_YAXIS].orthogonalPosition = @(realStartXpoint);
        yAxis[K_RIGHT_YAXIS].orthogonalPosition = @(realStartXpoint + displayPoints);
        
        plotSpace[K_LEFT_YAXIS].xRange = newRange;
        plotSpace[K_RIGHT_YAXIS].xRange = newRange;
    }
}
    
-(CGPoint)plotSpace:(CPTPlotSpace *)space willDisplaceBy:(CGPoint)proposedDisplacementVector
{
    return CGPointMake(0, 0);
}

- (void) initPlot:(CGRect)frame
{
    self.graphView = [[CPTGraphHostingView alloc] initWithFrame:CGRectMake(0,
                                                                           0, // to remove title's space
                                                                           frame.size.width,
                                                                           frame.size.height)];
    self.graphView.allowPinchScaling = NO;
    [self addSubview: self.graphView];
    
    // configure the graph
	self.graph = [[CPTXYGraph alloc] initWithFrame: self.graphView.bounds];   // graphView ? scrollView?
    self.graph.paddingLeft = [self getPaddingSizeWithYMaxSize:yMax[K_LEFT_YAXIS]] + 10;
    self.graph.paddingRight = [self getPaddingSizeWithYMaxSize:yMax[K_RIGHT_YAXIS]]+10;
    
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
	self.graphView.hostedGraph = self.graph;
    
    self.graph.plotAreaFrame.masksToBorder = NO;
    self.graph.plotAreaFrame.borderLineStyle = nil;
    
    maxXValue = self.graphView.frame.size.width / minorTickInterval;
    
    // configure Axis
    // Grid line styles
    majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.2;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
    // Line styles
    axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 0.75;
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    xAxis  = axisSet.xAxis;
    xAxis.labelingPolicy              = CPTAxisLabelingPolicyNone;
    xAxis.orthogonalPosition          = @(0.0);
    xAxis.tickDirection               = CPTSignPositive;
    xAxis.axisLineStyle               = axisLineStyle;
    xAxis.majorGridLineStyle          = majorGridLineStyle;
    xAxis.majorTickLength             = 0;
    xAxis.title                       = XAxisTitle;
    xAxis.titleOffset                 = -22.0f;
    xAxis.titleTextStyle              = axisTitleStyle;
    
    for (int i=0; i < maxXValue*2; i+=K_X_AXIS_TICK_INTERVAL)        // for landscape, maxXValue * 2
        [xAxisMajorTickLocs addObject:[NSNumber numberWithInt:i]];
    xAxis.majorTickLocations = xAxisMajorTickLocs;

    yAxis[K_LEFT_YAXIS] = axisSet.yAxis;
    yAxis[K_RIGHT_YAXIS] = [[CPTXYAxis alloc] initWithFrame:CGRectZero];
    self.graph.axisSet.axes = [NSArray arrayWithObjects:xAxis, yAxis[K_LEFT_YAXIS], yAxis[K_RIGHT_YAXIS], nil];
    
    [self configurePlotSpace:K_LEFT_YAXIS];
    if (_nAxis == 2)[self configurePlotSpace:K_RIGHT_YAXIS];
}

- (float)getPaddingSizeWithYMaxSize:(float)yMaxValue
{
    if (yMaxValue > 400.0) return 40.0;
    else if (yMaxValue >= 100.0) return 35.0;
    else if (yMaxValue >= 10.0) return 30.0;
    else return 25.0;
}

- (void) configurePlotSpace:(int)yAxisNum
{
    // Enable user interactions for plot space
    if (yAxisNum == K_LEFT_YAXIS)
        plotSpace[yAxisNum] = (CPTXYPlotSpace*)self.graph.defaultPlotSpace;
    else {
        plotSpace[yAxisNum] = [[CPTXYPlotSpace alloc]init];
        [self.graph addPlotSpace:plotSpace[yAxisNum]];
    }
    
    plotSpace[yAxisNum].allowsUserInteraction = YES;
    plotSpace[yAxisNum].delegate = self;
    
    // configure Plot
	plots[yAxisNum] = [[CPTScatterPlot alloc] init];
	plots[yAxisNum].dataSource = self;
    plots[yAxisNum].identifier = [NSNumber numberWithInt:yAxisNum];
    
	[self.graph addPlot:plots[yAxisNum] toPlotSpace:plotSpace[yAxisNum]];
    CPTMutableLineStyle *lineStyle = [plots[yAxisNum].dataLineStyle mutableCopy];
	lineStyle.lineWidth = 1.5;
	lineStyle.lineColor = Y_AXIS_COLOR;
	plots[yAxisNum].dataLineStyle = lineStyle;
    
    // configure y ranges
	[plotSpace[yAxisNum] scaleToFitPlots:[NSArray arrayWithObjects:plots[yAxisNum], nil]];
    CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:@(yMin[yAxisNum])
                                                          length:@(yMax[yAxisNum] - yMin[yAxisNum])];
    [plotSpace[yAxisNum] setYRange:newRange];
    
    // configure x ranges
    newRange = [CPTPlotRange plotRangeWithLocation:@(0)
                                            length:@(maxXValue)];
    [plotSpace[yAxisNum] setXRange:newRange];
    
    // add up/down space in graph
    CPTMutablePlotRange *yRange = [plotSpace[yAxisNum].yRange mutableCopy];
	[yRange expandRangeByFactor:@(1.1f)];
	plotSpace[yAxisNum].yRange = yRange;
    
    // Left Y axis
    labelTextStyle = [CPTMutableTextStyle textStyle];
    labelTextStyle.fontName = @"Helvetica-Bold";
    labelTextStyle.fontSize = 10.0;
    labelTextStyle.color = Y_AXIS_COLOR;
    
    NSMutableSet *yMajorTickLocations = [NSMutableSet set];
    NSMutableSet *yMajorTickLabels = [NSMutableSet set];
    for ( NSUInteger loc = 0; loc <= 6; loc += 1 ) {
        float value = yMin[yAxisNum] + (yMax[yAxisNum] - yMin[yAxisNum])/6.0 * loc;
        [yMajorTickLocations addObject:[NSDecimalNumber numberWithFloat:value]];
        CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%.1f", value]
                                                          textStyle:labelTextStyle];
        newLabel.tickLocation = @(value);
        newLabel.offset = 0;
        
        [yMajorTickLabels addObject:newLabel];
    }
    
    yAxis[yAxisNum].coordinate                  = CPTCoordinateY;
    yAxis[yAxisNum].plotSpace                   = plotSpace[yAxisNum];
    yAxis[yAxisNum].orthogonalPosition          = yAxisNum == K_LEFT_YAXIS ? @(0.0) : @(maxXValue);
    yAxis[yAxisNum].labelingPolicy              = CPTAxisLabelingPolicyNone;
    yAxis[yAxisNum].tickDirection               = yAxisNum == K_LEFT_YAXIS ? CPTSignNegative : CPTSignPositive;
    yAxis[yAxisNum].axisLineStyle               = axisLineStyle;
    yAxis[yAxisNum].majorGridLineStyle          = majorGridLineStyle;
    yAxis[yAxisNum].majorTickLocations          = yMajorTickLocations;
    yAxis[yAxisNum].majorIntervalLength         = @((yMax[yAxisNum]-yMin[yAxisNum])/7.0f);
    yAxis[yAxisNum].axisLabels                  = yMajorTickLabels;
    yAxis[yAxisNum].labelAlignment              = yAxisNum == K_LEFT_YAXIS ? CPTAlignmentRight : CPTAlignmentLeft;
    yAxis[yAxisNum].labelOffset                 = yAxisNum == K_LEFT_YAXIS ? -5.0 : -3.0;
    
    yAxis[yAxisNum].title = YAxisTitle[yAxisNum];
    yAxis[yAxisNum].titleOffset = 0.0 - YAxisTitle[yAxisNum].length * 1.0;
    yAxis[yAxisNum].titleRotation = 0;
    yAxis[yAxisNum].titleLocation = @(yMax[yAxisNum] + yMax[yAxisNum] * 0.1);
    yAxis[yAxisNum].titleTextStyle = axisTitleStyle;
}

- (void) changeYAxisSpace:(int)yAxisNum
{
    // configure y ranges
    CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:@(yMin[yAxisNum])
                                                          length:@(yMax[yAxisNum] - yMin[yAxisNum])];
    [plotSpace[yAxisNum] setYRange:newRange];
    
    // add up/down space in graph
    CPTMutablePlotRange *yRange = [plotSpace[yAxisNum].yRange mutableCopy];
	[yRange expandRangeByFactor:@(1.1f)];
	plotSpace[yAxisNum].yRange = yRange;
    
    // Left Y axis
    labelTextStyle = [CPTMutableTextStyle textStyle];
    labelTextStyle.fontName = @"Helvetica-Bold";
    labelTextStyle.fontSize = 10.0;
    labelTextStyle.color = Y_AXIS_COLOR;
    
    if (yAxisNum == K_LEFT_YAXIS)
        labelTextStyle.color = [CPTColor redColor];
    else
        labelTextStyle.color = [CPTColor blueColor];
    
    NSMutableSet *yMajorTickLocations = [NSMutableSet set];
    NSMutableSet *yMajorTickLabels = [NSMutableSet set];
    for ( NSUInteger loc = 0; loc <= 6; loc += 1 ) {
        float value = yMin[yAxisNum] + (yMax[yAxisNum] - yMin[yAxisNum])/6.0 * loc;
        [yMajorTickLocations addObject:[NSDecimalNumber numberWithFloat:value]];
        CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%.1f", value]
                                                          textStyle:labelTextStyle];
        newLabel.tickLocation = @(value);
        newLabel.offset = 0;
        
        [yMajorTickLabels addObject:newLabel];
    }
    
    yAxis[yAxisNum].majorTickLocations          = yMajorTickLocations;
    yAxis[yAxisNum].axisLabels                  = yMajorTickLabels;
    
    yAxis[yAxisNum].title = YAxisTitle[yAxisNum];
    yAxis[yAxisNum].titleOffset = -2.0 * YAxisTitle[yAxisNum].length;
    yAxis[yAxisNum].titleRotation = 0;
    yAxis[yAxisNum].titleLocation = @(yMax[yAxisNum] + yMax[yAxisNum] * 0.15);

    xAxis.title = XAxisTitle;
}

// for CPTPlotDataSource
- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot;
{
    return [plotData[[(NSNumber*)plot.identifier intValue]] count];
}

// for CPTPlotDataSource
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    int yAxisNum = [(NSNumber*)plot.identifier intValue];
    
    if (yAxisNum == K_RIGHT_YAXIS && !bShowRightAxis) return nil;
    if (yAxisNum == K_LEFT_YAXIS && !bShowLeftAxis) return nil;
    
    switch (fieldEnum){
        case CPTScatterPlotFieldX:
            return [NSNumber numberWithInteger:idx + currentIndex - plotData[yAxisNum].count];
        case CPTScatterPlotFieldY:
            return [plotData[yAxisNum] objectAtIndex:idx];
    }
    return nil;
}

// insert new data into the graph
- (void)insertLeftData:(double)lValue rightValue:(double)rValue
{
    if (!_bShow) return;
    
    if (pinchGesture != nil || panGesture != nil){
        [self removeGestureRecognizer:pinchGesture];
        pinchGesture = nil;
    }
    
    bIsRealMode = YES;
    // when inserted data is larger than the max number of data(=K_MAX_DISPLAY_DATA)
    if ([plotData[K_LEFT_YAXIS] count] >= K_MAX_DISPLAY_DATA){
        [plotData[K_LEFT_YAXIS] removeObjectAtIndex:0];
        [plots[K_LEFT_YAXIS] deleteDataInIndexRange:NSMakeRange(0, 1)];
        [plotData[K_RIGHT_YAXIS] removeObjectAtIndex:0];
        [plots[K_RIGHT_YAXIS] deleteDataInIndexRange:NSMakeRange(0, 1)];
    }
    
    int nDisplayedPoints = self.frame.size.width/minorTickInterval;
    if (currentIndex <= realStartXpoint + nDisplayedPoints){
        int location = currentIndex - nDisplayedPoints + 2;
        
        if (location < 0) location = 0;
        
        realStartXpoint = currentIndex;
        CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:@(location)
                                                              length:@(nDisplayedPoints)];
        
        yAxis[K_LEFT_YAXIS].orthogonalPosition = @(location);
        yAxis[K_RIGHT_YAXIS].orthogonalPosition = @(location + nDisplayedPoints);
        
        plotSpace[K_LEFT_YAXIS].xRange = newRange;
        plotSpace[K_RIGHT_YAXIS].xRange = newRange;
    }
    
    // configure y axis based min/max value
    Boolean bChanged = YES;
    
    if (lValue < yMin[K_LEFT_YAXIS])
        yMin[K_LEFT_YAXIS] = lValue;
    else if (lValue > yMax[K_LEFT_YAXIS])
        yMax[K_LEFT_YAXIS] = lValue;
    else
        bChanged = NO;
    
    if (bChanged)
        [self changeYAxisSpace:K_LEFT_YAXIS];
    
    bChanged = YES;
    if (rValue < yMin[K_RIGHT_YAXIS])
        yMin[K_RIGHT_YAXIS] = rValue;
    else if (rValue > yMax[K_RIGHT_YAXIS])
        yMax[K_RIGHT_YAXIS] = rValue;
    else
        bChanged = NO;
    
    if (bChanged)
        [self changeYAxisSpace:K_RIGHT_YAXIS];
 
    if (currentIndex > nDisplayedPoints){
        if (currentIndex % K_X_AXIS_TICK_INTERVAL == 0) // added 2015/7/20 for x axis ticks
            [xAxisMajorTickLocs addObject:[NSNumber numberWithInt:currentIndex]];
    }
    
    currentIndex ++;
    [plotData[K_LEFT_YAXIS] addObject:[NSNumber numberWithDouble:lValue]];
    [plots[K_LEFT_YAXIS] insertDataAtIndex:plotData[K_LEFT_YAXIS].count-1 numberOfRecords:1];
    [plotData[K_RIGHT_YAXIS] addObject:[NSNumber numberWithDouble:rValue]];
    [plots[K_RIGHT_YAXIS] insertDataAtIndex:plotData[K_RIGHT_YAXIS].count-1 numberOfRecords:1];
}

- (void)insertLeftDataList:(NSArray *)lDataList rightDataList:(NSArray *)rDataList
{
    // calucuate min/max values
    for (NSNumber *data in lDataList){
        if ([data floatValue] < yMin[K_LEFT_YAXIS])
            yMin[K_LEFT_YAXIS] = [data floatValue];
        else if ([data floatValue] > yMax[K_LEFT_YAXIS])
            yMax[K_LEFT_YAXIS] = [data floatValue];
    }
    [self changeYAxisSpace:K_LEFT_YAXIS];
    
    if (rDataList != nil){
        for (NSNumber *data in rDataList){
            if ([data floatValue] < yMin[K_RIGHT_YAXIS])
                yMin[K_RIGHT_YAXIS] = [data floatValue];
            else if ([data floatValue] > yMax[K_RIGHT_YAXIS])
                yMax[K_RIGHT_YAXIS] = [data floatValue];
        }
        [self changeYAxisSpace:K_RIGHT_YAXIS];
    }
    
    currentIndex = (int)lDataList.count;
    
    plotData[K_LEFT_YAXIS] = [[NSMutableArray alloc] init];
    [plotData[K_LEFT_YAXIS] addObjectsFromArray:lDataList];
    [plots[K_LEFT_YAXIS] insertDataAtIndex:0 numberOfRecords:[plotData[K_LEFT_YAXIS] count]];
    
    if (rDataList != nil){
        plotData[K_RIGHT_YAXIS] = [[NSMutableArray alloc] init];
        [plotData[K_RIGHT_YAXIS] addObjectsFromArray:rDataList];
        [plots[K_RIGHT_YAXIS] insertDataAtIndex:0 numberOfRecords:[plotData[K_RIGHT_YAXIS] count]];
    }

    NSUInteger maxX = [plotData[K_LEFT_YAXIS] count] == 0 ? maxXValue : [plotData[K_LEFT_YAXIS] count];
    CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:@(0) length:@(maxX)];
    
    plotSpace[K_LEFT_YAXIS].xRange = newRange;
    if (rDataList != nil){
        yAxis[K_RIGHT_YAXIS].orthogonalPosition = @(maxX);
        plotSpace[K_RIGHT_YAXIS].xRange = newRange;
    }
    
    xAxis.title = NSLocalizedString(@"graph_sample_number", @"sample number");
    xAxis.titleOffset = -30.0f;
    
    NSUInteger interval = maxX / K_MIN_DISPLAY_DATA;
    if (interval == 0) interval = 1;
    if (maxX % K_MIN_DISPLAY_DATA != 0) interval++;        // for round operation
    
    xAxisMajorTickLocs = [NSMutableSet set];
    for (int location=0; location < maxX; location+=interval){
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%d", location] textStyle:labelTextStyle];
        label.tickLocation = @(location);
        label.offset = -15.0f;
        
        [xAxisMajorTickLocs addObject:[NSNumber numberWithInt:location]];
        [xAxisMajorLabels addObject:label];
    }
    
    xAxis.axisLabels = xAxisMajorLabels;
    xAxis.majorTickLocations = xAxisMajorTickLocs;
    
    [self reFrame:orgFrame];    // 초기상태에서 버턴의 위치를 조정하기 위함
}

- (void)saveGraphIntoFile:(NSString*)fileName path:(NSString*)path format:(int)format
{
    UIImage *image = [self.graph imageOfLayer];
    NSData *data;
    
    switch (format) {
        case K_JPG_FORMAT:
            data = UIImageJPEGRepresentation(image, 0.5);
            break;
            
        case K_PNG_FORMAT:
            data = UIImagePNGRepresentation(image);
            break;

        default:
            break;
    }
    
    NSString *filePath=[NSString stringWithFormat:@"%@/%@", path, fileName];
    
    [data writeToFile:filePath atomically:YES];
}

// delete all data and set the graph view into the initial size
- (void)reset
{
    [plots[K_LEFT_YAXIS] deleteDataInIndexRange:NSMakeRange(0, plotData[K_LEFT_YAXIS].count)];
    [plotData[K_LEFT_YAXIS] removeAllObjects];
    [plots[K_RIGHT_YAXIS] deleteDataInIndexRange:NSMakeRange(0, plotData[K_LEFT_YAXIS].count)];
    [plotData[K_RIGHT_YAXIS] removeAllObjects];
    
    currentIndex = 0;
    
    maxXValue = self.graphView.frame.size.width/minorTickInterval;
    CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:@(0)
                                                          length:@(maxXValue)];
    [plotSpace[K_LEFT_YAXIS] setXRange:newRange];
    [plotSpace[K_RIGHT_YAXIS] setXRange:newRange];
    
    yAxis[K_LEFT_YAXIS].orthogonalPosition = @(0.0);
    yAxis[K_RIGHT_YAXIS].orthogonalPosition = @(maxXValue);
    
    // default y axis values
    yMin[K_LEFT_YAXIS] = 0.0;
    yMax[K_LEFT_YAXIS] = 1.0;
    yMin[K_RIGHT_YAXIS] = 0.0;
    yMax[K_RIGHT_YAXIS] = 1.0;
    
    [self changeYAxisSpace:K_LEFT_YAXIS];
    if (_nAxis == 2) [self changeYAxisSpace:K_RIGHT_YAXIS];
}

- (void)showHideRightAxis
{
    bShowRightAxis = !bShowRightAxis;
    [plots[K_RIGHT_YAXIS] reloadData];
    
    if (bShowRightAxis)
        [rightAxisBtn setTitle:NSLocalizedString(@"graph_hide", @"Hide") forState:UIControlStateNormal];
    else
        [rightAxisBtn setTitle:NSLocalizedString(@"graph_show", @"Show") forState:UIControlStateNormal];
}

- (void)showHideLeftAxis
{
    bShowLeftAxis = !bShowLeftAxis;
    [plots[K_LEFT_YAXIS] reloadData];
    
    if (bShowLeftAxis)
        [leftAxisBtn setTitle:NSLocalizedString(@"graph_hide", @"Hide") forState:UIControlStateNormal];
    else
        [leftAxisBtn setTitle:NSLocalizedString(@"graph_show", @"Show") forState:UIControlStateNormal];

}

- (void)setXTitle:(NSString *)title
{
    XAxisTitle = title;
}

- (void)setYTitle:(NSString *)title at:(int)pos
{
    YAxisTitle[pos] = title;
}

@end
