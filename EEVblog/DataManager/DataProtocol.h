//
//  DataProtocol.h
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {MAIN_LCD, SUB_LCD, SUB1, SUB2} DataPos;

@interface DataProtocol : NSObject

@property(readonly) bool bAckTime, bKhz, bMs, bAuto, bApo, bLowBat, bRel;
@property(readonly) NSString *recFuncString, *aHoldString;
@property(readonly) int recFunc, aHold, mem;
@property(readonly) NSMutableArray *modeStrings, *unitStrings, *modes;

- (id)init;
- (void)putData:(unsigned char[])buffer bufLen:(int)len;

- (NSString*)valueString:(DataPos)pos;
- (NSString*)acdcString:(DataPos)pos;
- (double)measuredValue:(DataPos)pos;
- (int)measuredOLValue:(DataPos)pos;
- (int)nMeasuredValues:(DataPos)pos;
- (int)range:(DataPos)pos;
- (double*)getMeasuredValue;
- (int*)getOFLvalue;

@end

// etc. string
#define OFL_STRING          @"OFL"

