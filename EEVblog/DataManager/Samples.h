//
//  Samples.h
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataProtocol.h"

@interface Samples : NSObject <NSCoding>

@property (readonly) NSDate *startTime;
@property (readonly) NSUInteger samplingInterval;   // second unit
@property (readonly) NSMutableArray *modes, *unitStrings, *modeStrings, *sumValues, *minValues, *maxValues;
@property (readwrite)NSString *recFuncString, *title, *memo;

+ (Samples*)readToDiskWithFileName:(NSString*)fileName;
+ (NSArray*)getSampleFileList;
+ (void)deleteSampleFile:(NSString*)fileName;

- (Samples*)initWithCapacity:(NSUInteger)capacity samplingInterval:(double)interval continuousSaving:(BOOL)bContinuous;
- (bool)addSamples:(double*)values olValues:(int*)olValues;
- (void)setMode:(NSArray*)modes modeStrings:(NSArray*)modeStrings unitStrings:(NSArray*)unitStrings recFunc:(NSString*)recFuncString;
- (NSString*)sampleValueStringAtIndex:(NSUInteger)index pos:(DataPos)pos;

- (void)startWriteToFile;
- (void)endWriteToFile;
- (NSUInteger)count;
- (NSDate*)sampleDateAtIndex:(NSUInteger)index;
- (void)saveToDiskWithFileName:(NSString*)fileName;
- (NSArray*)sampleListAtPos:(int)pos;
- (NSArray*)sampleOLListAtPos:(int)pos;

@end

