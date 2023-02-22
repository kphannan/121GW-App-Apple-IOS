//
//  Samples.m
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import "Samples.h"
#import "ToastMessage.h"
#import "AppDelegate.h"

static NSString *kSAMPLE_LIST = @"SAMPLE_LIST";
static NSString *kSAMPLE_OL_LIST = @"SAMPLE_OL_LIST";
static NSString *kSTART_TIME = @"START_TIME";
static NSString *kCAPACITY = @"CAPACITY";
static NSString *kMODE_LIST = @"MODE_LIST";
static NSString *kMODE_STRING_LIST = @"MODE_STRING_LIST";
static NSString *kUNIT_STRING_LIST = @"UNIT_STRING_LIST";
static NSString *kSUM_LIST = @"SUM_LIST";
static NSString *kMIN_LIST = @"MIN_LIST";
static NSString *kMAX_LIST = @"MAX_LIST";
static NSString *kREC_FUNC_STRING = @"REC_FUNC_STRING";
static NSString *kSAMPLING_INTERVAL = @"SAMPLING_INTERVAL";
static NSString *kTITLE = @"TITLE";
static NSString *kMEMO = @"MEMO";
static NSString *path = nil;
static NSFileManager *fm;

@interface Samples ()
{
    NSArray *sampleList;
    NSArray *sampleOLList;   // -1:-O.L., 1:O.L., 0:none
    NSUInteger listCapacity;
    Boolean bWriteToFile;
    ToastMessage *toastMessage;
    bool bContinuousSaving;
}
@end

@implementation Samples

- (Samples*)initWithCapacity:(NSUInteger)capacity samplingInterval:(double)interval continuousSaving:(BOOL)bContinuous
{
    self = [super init];
    if (self == nil) return nil;
    
    sampleList = [NSArray arrayWithObjects:[NSMutableArray arrayWithCapacity:capacity], [NSMutableArray arrayWithCapacity:capacity],
                  [NSMutableArray arrayWithCapacity:capacity], [NSMutableArray arrayWithCapacity:capacity], nil];
    sampleOLList = [NSArray arrayWithObjects:[NSMutableArray arrayWithCapacity:capacity], [NSMutableArray arrayWithCapacity:capacity],
                    [NSMutableArray arrayWithCapacity:capacity], [NSMutableArray arrayWithCapacity:capacity], nil];
    
    listCapacity = capacity;
    _startTime = [NSDate date];
    bWriteToFile = NO;
    _samplingInterval = interval;
    bContinuousSaving = bContinuous;
    
    _recFuncString = @"";
    _modes = [NSMutableArray arrayWithObjects:@-1, @-1, @-1, @-1, nil];
    _modeStrings = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    _unitStrings = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    [self reset];
    
    if (path == nil){
        path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        path = [path stringByAppendingString:@"/LOG"];
        fm = [NSFileManager defaultManager];
    }
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    // init toast message box
    toastMessage = [[ToastMessage alloc]init];
    
    return self;
}

- (NSUInteger)count
{
    return [[sampleList objectAtIndex:MAIN_LCD] count];
}

- (bool)addSamples:(double*)values olValues:(int*)olValues
{
    if (!bWriteToFile) return false;
    
    if ([self count] >= listCapacity){
        [self saveToDiskWithFileName:[self makeFileName]];
        [self reset];
        if (!bContinuousSaving){
            bWriteToFile = NO;
            return false;
        }
    }
    
    for (int pos=0; pos<4; pos++){
        [[sampleList objectAtIndex:pos] addObject:[NSNumber numberWithDouble:values[pos]]];
        [[sampleOLList objectAtIndex:pos] addObject:[NSNumber numberWithInt:olValues[pos]]];

        double value = values[pos];
        _sumValues[pos] = [NSNumber numberWithDouble:value+[_sumValues[pos] doubleValue]];
        if ([_minValues[pos] doubleValue] > value) _minValues[pos] = [NSNumber numberWithDouble:value];
        if ([_maxValues[pos] doubleValue] < value) _maxValues[pos] = [NSNumber numberWithDouble:value];
    }
        
    return true;
}

- (void)reset
{
    _sumValues = [NSMutableArray arrayWithObjects:@0, @0, @0, @0, nil];
    _minValues = [NSMutableArray arrayWithObjects:@100000, @100000, @100000, @100000, nil];
    _maxValues = [NSMutableArray arrayWithObjects:@-100000, @-100000, @-100000, @-100000, nil];
    
    [[sampleList objectAtIndex:MAIN_LCD] removeAllObjects];
    [[sampleList objectAtIndex:SUB_LCD] removeAllObjects];
    [[sampleList objectAtIndex:SUB1] removeAllObjects];
    [[sampleList objectAtIndex:SUB2] removeAllObjects];
    [[sampleOLList objectAtIndex:MAIN_LCD] removeAllObjects];
    [[sampleOLList objectAtIndex:SUB_LCD] removeAllObjects];
    [[sampleOLList objectAtIndex:SUB1] removeAllObjects];
    [[sampleOLList objectAtIndex:SUB2] removeAllObjects];
    
    _startTime = [NSDate date];
}

- (void)setMode:(NSArray*)modes modeStrings:(NSArray*)modeStrings unitStrings:(NSArray*)unitStrings recFunc:(NSString*)recFuncString
{
    if (sampleList.count > 0 && bWriteToFile)
        [self saveToDiskWithFileName:[self makeFileName]];
    
    [self reset];
    [_modes setArray:modes];
    [_modeStrings setArray:modeStrings];
    [_unitStrings setArray:unitStrings];
    _recFuncString = recFuncString;
}

- (NSDate*)sampleDateAtIndex:(NSUInteger)index
{
    return [_startTime dateByAddingTimeInterval:index * _samplingInterval];
}

- (NSString*)sampleValueStringAtIndex:(NSUInteger)index pos:(DataPos)pos
{
    NSMutableArray *dataArray = [sampleList objectAtIndex:pos];
    NSString *unitString = _unitStrings[pos];
    
    double value = [dataArray[index] doubleValue];
 
    NSMutableArray *dataOLArray = [sampleOLList objectAtIndex:pos];
    int olValue = [dataOLArray[index] intValue];
    if (olValue == -1) return [NSString stringWithFormat:@"-%@ %@",OFL_STRING,unitString];
    else if (olValue == 1) return [NSString stringWithFormat:@"%@ %@",OFL_STRING,unitString];
    
    return [NSString stringWithFormat:@"%.3f %@", value, unitString];
}

- (NSArray*)sampleListAtPos:(int)pos
{
    return [sampleList objectAtIndex:pos];
}

- (NSArray*)sampleOLListAtPos:(int)pos
{
    return [sampleOLList objectAtIndex:pos];
}

#pragma mark - For File Operations
+ (NSArray*)getSampleFileList
{
    if (path == nil){
        path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        path = [path stringByAppendingString:@"/LOG"];
        fm = [NSFileManager defaultManager];
    }
    
    NSArray *fileList = [fm contentsOfDirectoryAtPath:path error:nil];
    return [fileList sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [(NSString*)obj2 compare:(NSString*)obj1];
    }];
}

- (NSString*)makeFileName
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd(HH:mm:ss)"];
    NSString *dateFileName = [dateFormat stringFromDate:_startTime];
    
    return dateFileName;
}

+ (NSString*)makeFilePath:(NSString*)fileName
{
    return [NSString stringWithFormat:@"%@/%@", path, fileName];
}

- (void)saveToDiskWithFileName:(NSString*)fileName
{
    [toastMessage showWithMessage:NSLocalizedString(@"samples_saved_log", @"saved log") withContinuous:NO];
    [NSKeyedArchiver archiveRootObject:self toFile:[Samples makeFilePath:fileName]];
}

+ (Samples*)readToDiskWithFileName:(NSString*)fileName
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[Samples makeFilePath:fileName]];
}

+ (void)deleteSampleFile:(NSString *)fileName
{
    [fm removeItemAtPath:[Samples makeFilePath:fileName] error:nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    sampleList          = [aDecoder decodeObjectForKey:kSAMPLE_LIST];
    sampleOLList        = [aDecoder decodeObjectForKey:kSAMPLE_OL_LIST];
    _startTime          = [aDecoder decodeObjectForKey:kSTART_TIME];
    listCapacity        = [aDecoder decodeIntegerForKey:kCAPACITY];
    _modes              = [aDecoder decodeObjectForKey:kMODE_LIST];
    _modeStrings        = [aDecoder decodeObjectForKey:kMODE_STRING_LIST];
    _unitStrings        = [aDecoder decodeObjectForKey:kUNIT_STRING_LIST];
    _sumValues          = [aDecoder decodeObjectForKey:kSUM_LIST];
    _minValues          = [aDecoder decodeObjectForKey:kMIN_LIST];
    _maxValues          = [aDecoder decodeObjectForKey:kMAX_LIST];
    _recFuncString      = [aDecoder decodeObjectForKey:kREC_FUNC_STRING];
    _samplingInterval   = [aDecoder decodeDoubleForKey:kSAMPLING_INTERVAL];
    _title              = [aDecoder decodeObjectForKey:kTITLE];
    _memo               = [aDecoder decodeObjectForKey:kMEMO];
    
    bWriteToFile = NO;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:sampleList         forKey:kSAMPLE_LIST];
    [aCoder encodeObject:sampleOLList       forKey:kSAMPLE_OL_LIST];
    [aCoder encodeObject:_startTime         forKey:kSTART_TIME];
    [aCoder encodeInteger:listCapacity      forKey:kCAPACITY];
    [aCoder encodeObject:_modes             forKey:kMODE_LIST];
    [aCoder encodeObject:_modeStrings       forKey:kMODE_STRING_LIST];
    [aCoder encodeObject:_unitStrings       forKey:kUNIT_STRING_LIST];
    [aCoder encodeObject:_sumValues         forKey:kSUM_LIST];
    [aCoder encodeObject:_minValues         forKey:kMIN_LIST];
    [aCoder encodeObject:_maxValues         forKey:kMAX_LIST];
    [aCoder encodeObject:_recFuncString     forKey:kREC_FUNC_STRING];
    [aCoder encodeDouble:_samplingInterval  forKey:kSAMPLING_INTERVAL];
    [aCoder encodeObject:_memo              forKey:kMEMO];
    [aCoder encodeObject:_title             forKey:kTITLE];
}

- (void)startWriteToFile
{
    bWriteToFile = YES;
    [self reset];
}

- (void)endWriteToFile
{
    if (bWriteToFile){
        _memo = @"";
        _title = [NSString stringWithFormat:@"%@/%@/%@ - %lu %@", _modeStrings[MAIN_LCD], _modeStrings[SUB1], _modeStrings[SUB2],
                  (unsigned long)[self count], NSLocalizedString(@"samples_log_name", @"samples")];
        
        bWriteToFile = NO;
        [self saveToDiskWithFileName:[self makeFileName]];
    }
}

@end

