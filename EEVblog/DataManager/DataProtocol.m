//
//  DataProtocol.m
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import "DataProtocol.h"

#define NOPAREN(...) __VA_ARGS__
#define MODE_INFO(KEY, NAME, RANGE, STRING, UNIT, FORMAT)               \
{                                                                       \
    NSArray *strings = [NSArray arrayWithObjects:NOPAREN STRING, nil];  \
    double units[7] = {NOPAREN UNIT};                                   \
    NSArray *formats = [NSArray arrayWithObjects:NOPAREN FORMAT, nil];  \
    [self setModeInfo:KEY modeName:NAME maxRange:RANGE                  \
    unitStrings:strings units:units formats:formats];                   \
}

NSArray *modeInfoTable, *rangeNumberInfoTable, *rangeUnitInfoTable;

@interface ModeInfo: NSObject {
@public
    NSString *name;
    int maxRange;
    NSString *unitStrings[7];
    double units[7];
    NSString *valueFormats[7];
}
@end

@implementation ModeInfo

-(id)init:(NSString*)modeName maxRange:(int)maxNrange unitStrings:(NSArray*)strings units:(double*)unitList formats:(NSArray*)formats
{
    name = modeName;
    maxRange = maxNrange;
    for (int i=0; i<maxNrange; i++){
        unitStrings[i] = strings[i];
        units[i] = unitList[i];
        valueFormats[i] = formats[i];
    }
    
    return self;
}

@end
// for private data of the DLProtocol Class
@interface DataProtocol () {
    enum DataKind {STATUS, TIME, KEY};
    enum BytePos {HIGH, LOW};
    
    NSMutableDictionary *modeInfoMap;
    
    // values
    NSMutableString *valueStrings[4];
    NSString *acdcStrings[4];
    @public
    double   measuredValues[4];
    int     ofls[4];
    int     ranges[4];
    long    nMeasuredValues[4];
    int     step;
    unsigned char data;
    unsigned char checkSum;
    enum BytePos bytePos;
    enum DataKind dataKind;
    
    // for the parsed temporary data
    int modeTemp[4], rangeTemp[4], oflTemp[4], valueTemp[4], acdcTemp[4];
    bool signTemp[4];
    bool bKhzTemp, bMsTemp, bAutoTemp, bApoTemp, bLowBatTemp, bRelTemp;
    bool bSubLcdKTemp, bSubLcdHzTemp;
    int aHoldTemp, recFuncTemp, memTemp, subLCDPointPosTemp, subLCDHighValueTemp, subLCDLowValueTemp;
}
@end

@implementation DataProtocol

- (id)init
{
    self = [super init];
    if (self == nil) return nil;
    
    step = 0;
    [self initInfoTable];
    _modes = [NSMutableArray arrayWithObjects:@-1, @-1, @-1, @-1, nil];
    _modeStrings = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    _unitStrings = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    
    for (int i=0; i<4; i++)
        valueStrings[i] = [[NSMutableString alloc] init];
    
    return self;
}

- (ModeInfo*)getModeInfo:(int)key
{
    return (ModeInfo*)[modeInfoMap objectForKey:[NSNumber numberWithInt:key]];
}

- (void)setModeInfo:(int)key modeName:(NSString*)modeName maxRange:(int)maxRange unitStrings:(NSArray*)strings units:(double*)unitList formats:(NSArray*)formats
{
    ModeInfo *modeInfo = [[ModeInfo alloc] init:modeName maxRange:maxRange unitStrings:strings units:unitList formats:formats];
    [modeInfoMap setObject:modeInfo forKey:[NSNumber numberWithInt:key]];
}

- (void)initInfoTable
{   // Mode information table
    modeInfoMap = [NSMutableDictionary dictionaryWithCapacity:50];
    MODE_INFO(0,    NSLocalizedString(@"protocol_Low_Z",        @"Logw_Z"),         1, (@"V"),                                      (0.1),                          (@"%.1f"));
    MODE_INFO(1,    NSLocalizedString(@"protocol_DCV",          @"DCV"),            4, (@"V",@"V",@"V",@"V"),                       (0.0001, 0.001, 0.01, 0.1),     (@"%.4f",@"%.3f",@"%.2f",@"%.1f"));
    MODE_INFO(2,    NSLocalizedString(@"protocol_ACV",          @"ACV"),            4, (@"V",@"V",@"V",@"V"),                       (0.0001, 0.001, 0.01, 0.1),		(@"%.4f",@"%.3f",@"%.2f",@"%.1f"));
    MODE_INFO(3,    NSLocalizedString(@"protocol_DCmV",         @"DCmV"),           2, (@"mV",@"mV"),                               (0.001, 0.01),					(@"%.3f",@"%.2f"));
    MODE_INFO(4,    NSLocalizedString(@"protocol_ACmV",         @"ACmV"),           2, (@"mV",@"mV"),                               (0.001, 0.01),					(@"%.3f",@"%.2f"));
    MODE_INFO(5,    NSLocalizedString(@"protocol_Temp",         @"Temp."),          1, (@"°C"),                                     (0.1),							(@"%.1f"));
    MODE_INFO(6,    NSLocalizedString(@"protocol_Hz",           @"Hz"),        5, (@"Hz",@"Hz",@"KHz",@"KHz",@"KHz"),          (0.001,0.01,0.0001,0.001,0.01), (@"%.3f",@"%.2f",@"%.4f",@"%.3f",@"%.2f"));
    MODE_INFO(7,    NSLocalizedString(@"protocol_mS",           @"mS"),             3, (@"ms",@"ms",@"ms"),                         (0.0001,0.001,0.01),            (@"%.4f",@"%.3f",@"%.2f"));
    MODE_INFO(8,    NSLocalizedString(@"protocol_Duty",         @"Duty"),           1, (@"%"),                                      (0.1),                          (@"%.1f"));
    MODE_INFO(9,NSLocalizedString(@"protocol_Resistor",@"Resistor"), 7,(@"Ω",@"Ω",@"KΩ",@"KΩ",@"KΩ",@"MΩ",@"MΩ"),(0.001,0.01,0.0001,0.001,0.01,0.0001,0.001),(@"%.3f",@"%.2f",@"%.4f",@"%.3f",@"%.2f",@"%.4f",@"%.3f"));
    MODE_INFO(10,   NSLocalizedString(@"protocol_Continuity",   @"Continuity"),     1, (@"Ω"),                                      (0.01),							(@"%.2f"));
    MODE_INFO(11,   NSLocalizedString(@"protocol_Diode",        @"Diode"),          2, (@"V",@"V"),                                 (0.0001,0.001),                 (@"%.4f",@"%.3f"));
    MODE_INFO(12,   NSLocalizedString(@"protocol_Capacitor",    @"Capacitor"),      6, (@"nF",@"nF",@"uF",@"uF",@"uF",@"uF"),       (0.01,0.1,0.001,0.01,0.1,1.0),  (@"%.2f",@"%.1f",@"%.3f",@"%.2f",@"%.1f",@"%.0f"));
    MODE_INFO(13,   NSLocalizedString(@"protocol_ACuVA",        @"ACuVA"),          4, (@"uVA",@"uVA",@"uVA",@"uVA"),               (0.01, 0.1, 0.1, 1.0),			(@"%.2f",@"%.1f",@"%.1f",@"%.0f"));
    MODE_INFO(14,   NSLocalizedString(@"protocol_ACmVA",        @"ACmVA"),          4, (@"mVA",@"mVA",@"mVA",@"mVA"),               (0.001, 0.01, 0.01, 0.1),       (@"%.3f",@"%.2f",@"%.2f",@"%.1f"));
    MODE_INFO(15,   NSLocalizedString(@"protocol_ACVA",         @"ACVA"),           4, (@"mVA",@"mVA",@"VA",@"VA"),                 (0.1, 1.0, 0.001, 0.01),        (@"%.1f",@"%.0f",@"%.3f",@"%.2f"));
    MODE_INFO(16,   NSLocalizedString(@"protocol_ACuA",         @"ACuA"),           2, (@"uA",@"uA"),                               (0.001, 0.01),					(@"%.3f",@"%.2f"));
    MODE_INFO(17,   NSLocalizedString(@"protocol_DCuA",         @"DCuA"),           2, (@"uA",@"uA"),                               (0.001, 0.01),					(@"%.3f",@"%.2f"));
    MODE_INFO(18,   NSLocalizedString(@"protocol_ACmA",         @"ACmA"),           2, (@"mA",@"mA"),                               (0.0001, 0.001),				(@"%.4f",@"%.3f"));
    MODE_INFO(19,   NSLocalizedString(@"protocol_DCmA",         @"DCmA"),           2, (@"mA",@"mA"),                               (0.0001, 0.001),				(@"%.4f",@"%.3f"));
    MODE_INFO(20,   NSLocalizedString(@"protocol_ACA",          @"ACA"),            3, (@"mA",@"A",@"A"),                           (0.01, 0.0001, 0.001),			(@"%.2f",@"%.4f",@"%.3f"));
    MODE_INFO(21,   NSLocalizedString(@"protocol_DCA",          @"DCA"),            3, (@"mA",@"A",@"A"),                           (0.01, 0.0001, 0.001),			(@"%.2f",@"%.4f",@"%.3f"));
    MODE_INFO(22,   NSLocalizedString(@"protocol_DCuVA",        @"DCuVA"),          4, (@"uVA",@"uVA",@"uVA",@"uVA"),               (0.01, 0.1, 0.1, 1.0),			(@"%.2f",@"%.1f",@"%.1f",@"%.0f"));
    MODE_INFO(23,   NSLocalizedString(@"protocol_DCmVA",        @"DCmVA"),          4, (@"mVA",@"mVA",@"mVA",@"mVA"),               (0.001, 0.01, 0.01, 0.1),		(@"%.3f",@"%.2f",@"%.2f",@"%.1f"));
    MODE_INFO(24,   NSLocalizedString(@"protocol_DCVA",         @"DCVA"),           4, (@"mVA",@"mVA",@"VA",@"VA"),                 (0.1, 1.0, 0.001, 0.01),		(@"%.1f",@"%.0f",@"%.3f",@"%.2f"));
    MODE_INFO(100,  NSLocalizedString(@"protocol_Temp",         @"Temp."),          1, (@"℃"),                                      (0.1),							(@"%.1f"));
    MODE_INFO(101,  NSLocalizedString(@"protocol_Temp",         @"Temp."),          1, (@"℃"),                                      (0.1),							(@"%.1f"));
    MODE_INFO(105,  NSLocalizedString(@"protocol_Temp",         @"Temp."),          1, (@"℉"),                                      (0.1),							(@"%.1f"));
    MODE_INFO(106,  NSLocalizedString(@"protocol_Temp",         @"Temp."),          1, (@"℉"),                                      (0.1),							(@"%.1f"));
    MODE_INFO(110,  NSLocalizedString(@"protocol_Battery",      @"Battery"),        1, (@"V"),                                      (0.1),							(@"bAt%.1f"));
    MODE_INFO(120,  NSLocalizedString(@"protocol_APO",          @"APO"),            1, (@" "),                                      (1.0),							(@"APO.oN"));
    MODE_INFO(121,  NSLocalizedString(@"protocol_APO",          @"APO"),            1, (@" "),                                      (1.0),							(@"APO.oN"));
    MODE_INFO(125,  NSLocalizedString(@"protocol_APO",          @"APO"),            1, (@" "),                                      (1.0),							(@"APO.oF"));
    MODE_INFO(126,  NSLocalizedString(@"protocol_APO",          @"APO"),            1, (@" "),                                      (1.0),							(@"APO.oF"));
    MODE_INFO(130,  NSLocalizedString(@"protocol_YEAR",         @"YEAR"),           1, (@" "),                                      (1.0),							(@"%.0f"));
    MODE_INFO(131,  NSLocalizedString(@"protocol_YEAR",         @"YEAR"),           1, (@" "),                                      (1.0),							(@"%.0f"));
    MODE_INFO(135,  NSLocalizedString(@"protocol_DATE",         @"DATE"),           1, (@" "),                                      (1.0),							(@"%2d-%2d"));
    MODE_INFO(136,  NSLocalizedString(@"protocol_DATE",         @"DATE"),           1, (@" "),                                      (1.0),							(@"%2d-%2d"));
    MODE_INFO(137,  NSLocalizedString(@"protocol_DATE",         @"DATE"),           1, (@" "),                                      (1.0),							(@"%2d-%2d"));
    MODE_INFO(140,  NSLocalizedString(@"protocol_TIME",         @"TIME"),           1, (@" "),                                      (1.0),							(@"%2d-%2d"));
    MODE_INFO(141,  NSLocalizedString(@"protocol_TIME",         @"TIME"),           1, (@" "),                                      (1.0),							(@"%2d-%2d"));
    MODE_INFO(142,  NSLocalizedString(@"protocol_TIME",         @"TIME"),           1, (@" "),                                      (1.0),							(@"%2d-%2d"));
    MODE_INFO(150,  NSLocalizedString(@"protocol_Burden",       @"Burden Vpltage"),	1, (@"mV"),                                     (0.1),							(@"b%.1f"));
    MODE_INFO(160,  NSLocalizedString(@"protocol_LCD",          @"LCD"),            1, (@" "),                                      (1.0),							(@"Lcd-%.0f"));
    MODE_INFO(170,  NSLocalizedString(@"protocol_Continuity",   @"Continuity"),     1, (@" "),                                      (1.0),                          (@"DN %.0f"));
    MODE_INFO(171,  NSLocalizedString(@"protocol_Continuity",   @"Continuity"),     1, (@" "),                                      (1.0),                          (@"UP %.0f"));
    MODE_INFO(172,  NSLocalizedString(@"protocol_Continuity",   @"Continuity"),     1, (@" "),                                      (1.0),                          (@"DN %.0f"));
    MODE_INFO(173,  NSLocalizedString(@"protocol_Continuity",   @"Continuity"),     1, (@" "),                                      (1.0),                          (@"UP %.0f"));
    MODE_INFO(180,  NSLocalizedString(@"protocol_dBm",          @"dBm"),            1, (@"dBm"),                                    (1.0),                          (@"%.0f"));
    MODE_INFO(190,  NSLocalizedString(@"protocol_Interval",     @"Interval"),       1, (@" "),                                      (1.0),                          (@"In %.0f"));
}

- (NSString*)valueString:(DataPos)pos
{
    return valueStrings[pos];
}

- (NSString*)acdcString:(DataPos)pos
{
    return acdcStrings[pos];
}

- (double)measuredValue:(DataPos)pos
{
    return measuredValues[pos];
}

- (int)measuredOLValue:(DataPos)pos
{
    return ofls[pos];
}

- (int)nMeasuredValues:(DataPos)pos
{
    return (int)nMeasuredValues[pos];
}

- (int)range:(DataPos)pos
{
    return ranges[pos];
}

- (double*)getMeasuredValue
{
    return measuredValues;
}

- (int*)getOFLvalue
{
    return ofls;
}

unsigned char atoHex(unsigned char asciiData)
{
    if (0x30 <= asciiData && asciiData <= 0x39) return asciiData - 0x30; // 0-9
    if (0x41 <= asciiData && asciiData <= 0x46) return asciiData - 55;	// A-F
    if (0x61 <= asciiData && asciiData <= 0x66) return asciiData - 87;	// a-f
    
    return 0;
}

- (void)putData:(unsigned char [])buffer bufLen:(int)length
{
    unsigned char asciiData;
    
    for(int i=0 ; i<length ; i++)
    {
        asciiData = buffer[i];
        
        if (asciiData == 0xF2 || asciiData == 0xF4 || asciiData == 0xF8)
            step = 0;
        
        if (step > 0){
            if (bytePos == HIGH) {
                data =  atoHex(asciiData) << 4;
                bytePos = LOW;
                continue;
            } else {
                data +=  atoHex(asciiData);
                bytePos = HIGH;
            }
        }
        
        switch(step)
        {
            case 0:     // seperator [0xF2 or 0xF4 or 0xF8]
                dataKind = (asciiData == 0xF2) ? STATUS : ((asciiData == 0xF4) ? KEY : TIME);
                step = 1;
                bytePos = HIGH;
                break;
            case 1:     // main LCD mode
                if (dataKind == STATUS)
                    modeTemp[MAIN_LCD] = data;
                step = 2;
                break;
            case 2:		// main LCD, OFL, +/-, range + key checksum check
                if (dataKind == KEY && checkSum == data){	// KEY checksum
                    step = 0;
                    break;
                }
                if (dataKind == STATUS) {
                    rangeTemp[MAIN_LCD] =  (data & 0x0F);
                    oflTemp[MAIN_LCD] = ( (data & 0x80) ==  0x80);
                    signTemp[MAIN_LCD] = ( (data & 0x40) ==  0x40);
                }
                step = 3;
                break;
            case 3: 	//	main LCD, high value
                if (dataKind == STATUS)
                    valueTemp[MAIN_LCD] = data << 8;
                step = 4;
                break;
            case 4:		// main LCD, low value
                if (dataKind == STATUS)
                    valueTemp[MAIN_LCD] += data;
                step = 5;
                break;
            case 5:	// sub LCD mode
                if (dataKind == STATUS)
                    modeTemp[SUB_LCD] = data;
                step = 6;
                break;
            case 6:		// sub LCD, OFL, +/-, range
                if (dataKind == STATUS) {
                    rangeTemp[SUB_LCD] =  0;
                    subLCDPointPosTemp =  (data & 0x07);
                    oflTemp[SUB_LCD] = ((data & 0x80) ==  0x80);
                    signTemp[SUB_LCD] = ((data & 0x40) ==  0x40);
                    bSubLcdKTemp =  ((data & 0x20) == 0x20);
                    bSubLcdHzTemp = ((data & 0x10) == 0x10);
                }
                step = 7;
                break;
            case 7:		// sub LCD high value + time checksum check
                if (dataKind == TIME && checkSum == data){	// TIME checksum
                    _bAckTime = true;
                    step = 0;
                    break;
                }
                if (dataKind == STATUS) {
                    subLCDHighValueTemp = data;
                    valueTemp[SUB_LCD] = data << 8;
                }
                step = 8;
                break;
            case 8:		// sub LCD low value
                if (dataKind == STATUS) {
                    subLCDLowValueTemp = data;
                    valueTemp[SUB_LCD] += data;
                }
                step = 9;
                break;
            case 11:    // Icon LCD
                bKhzTemp = ((data & 0x40) == 0x40);
                bMsTemp = ((data &0x20) == 0x20);
                acdcTemp[MAIN_LCD] = ((data & 0x18) >> 3);
                bAutoTemp = ((data & 0x04) == 0x04);
                bApoTemp = ((data & 0x02) == 0x02);
                bLowBatTemp = ((data & 0x01) == 0x01);
                step = 12;
                break;
            case 12: 	// Icon LCD
                bRelTemp = ((data & 0x10) == 0x10);
                recFuncTemp = (data & 0x07);
                step = 13;
                break;
            case 13:	// Icon LCD
                aHoldTemp = ((data & 0x0C) >> 2);
                acdcTemp[SUB_LCD] = (data & 0x03);
                memTemp = ((data & 0x30) >> 4);
                step = 14;
                break;
            case 14:     // SUB1 mode
                modeTemp[SUB1] = data;
                step = 15;
                break;
            case 15:		// sub1, OFL, +/-, range
                rangeTemp[SUB1] =  (data & 0x0F);
                oflTemp[SUB1] = ( (data & 0x80) ==  0x80);
                signTemp[SUB1] = ( (data & 0x40) ==  0x40);
                step = 16;
                break;
            case 16: 	//	sub1, high value
                valueTemp[SUB1] = data << 8;
                step = 17;
                break;
            case 17:		// sub1, low value
                valueTemp[SUB1] += data;
                step = 18;
                break;
            case 18:     // SUB2 mode
                modeTemp[SUB2] = data;
                step = 19;
                break;
            case 19:		// sub2, OFL, +/-, range
                rangeTemp[SUB2] =  (data & 0x0F);
                oflTemp[SUB2] = ( (data & 0x80) ==  0x80);
                signTemp[SUB2] = ( (data & 0x40) ==  0x40);
                step = 20;
                break;
            case 20: 	//	sub2, high value
                valueTemp[SUB2] = data << 8;
                step = 21;
                break;
            case 21:		// sub2, low value
                valueTemp[SUB2] += data;
                step = 22;
                break;
            case 22:	// Stutus checksum check and fixed data
                step = 0;
                
                // check checksum
                if ( checkSum  != data ) break; // check error
                
                // ************************************************************
                // when the data is parsed successfully, make the status string
                // ************************************************************
                _bKhz = bKhzTemp;
                _bMs = bMsTemp;
                _bAuto = bAutoTemp;
                _bLowBat = bLowBatTemp;
                _bRel = bRelTemp;
                _aHold = aHoldTemp;
                _recFunc = recFuncTemp;
                _bApo = bApoTemp;
                _mem = memTemp;
                _aHoldString = getHoldString(aHoldTemp);
                _recFuncString = getRecFuncString(recFuncTemp);
                acdcStrings[MAIN_LCD] = getACDCString(acdcTemp[MAIN_LCD]);
                acdcStrings[SUB_LCD] = getACDCString(acdcTemp[SUB_LCD]);
                
                [self setValue:MAIN_LCD];
                [self setValue:SUB_LCD];
                [self setValue:SUB1];
                [self setValue:SUB2];
                
                if (bSubLcdKTemp && bSubLcdHzTemp) _unitStrings[SUB_LCD] = @"KHz";
                else if (bSubLcdHzTemp) _unitStrings[SUB_LCD] = @"Hz";
                else if (bSubLcdKTemp) _unitStrings[SUB_LCD] = @"K";
                
                break;
                
            default:
                step ++;
        }	// end of switch
        
        // caculate check sum
        if (step <= 2) checkSum = data;
        else checkSum ^= data;
    } // end of for
}	// end of putData

- (void)setValue:(DataPos) pos
{
    ofls[pos] = oflTemp[pos] ? (signTemp[pos] ? -1 : 1) : 0;
    _modes[pos] = [NSNumber numberWithInt:modeTemp[pos]];
    ranges[pos] = rangeTemp[pos];
    measuredValues[pos] = [self getUnit:pos] * (valueTemp[pos] * (signTemp[pos] ? -1 : 1));
    
    switch([_modes[pos] intValue]){
        case 110:						// battery
            [valueStrings[pos] setString:[NSString stringWithFormat:[NSString stringWithFormat:@"bAt%@", [self getValueFormat:pos]], measuredValues[pos]]];
            break;
        case 130:case 131:		// year
            measuredValues[pos] = subLCDLowValueTemp + 2000;
            [valueStrings[pos] setString:[NSString stringWithFormat:[self getValueFormat:pos], measuredValues[pos]]];
            break;
        case 135:case 136:case 137:case 140:case 141:case 142:
            [valueStrings[pos] setString:[NSString stringWithFormat:[self getValueFormat:pos], subLCDHighValueTemp, subLCDLowValueTemp]];
            break;
        case 150:	// Burden Voltage
            if (measuredValues[pos] >= 0)
                [valueStrings[pos] setString:[NSString stringWithFormat:[NSString stringWithFormat:@"b%@", [self getValueFormat:pos]], measuredValues[pos]]];
            else
                [valueStrings[pos] setString:[NSString stringWithFormat:[NSString stringWithFormat:@"-b%@", [self getValueFormat:pos]], measuredValues[pos] * -1]];
            break;

        default:
            [valueStrings[pos] setString:[NSString stringWithFormat:[self getValueFormat:pos], measuredValues[pos]]];
    }
    
    _unitStrings[pos] = [self getUnitString:pos];
    _modeStrings[pos] = [self getModeName:pos];
    if (ofls[pos] != 0) [valueStrings[pos] setString:OFL_STRING];
}

- (NSString*)getValueFormat:(DataPos) pos
{
    ModeInfo *modeInfo = [self getModeInfo:[_modes[pos] intValue]];
    if (modeInfo == nil) return @"";
    if (ranges[pos] > modeInfo->maxRange) ranges[pos] = modeInfo->maxRange - 1;
    
    if (pos != SUB_LCD)
        return modeInfo->valueFormats[ranges[pos]];

    switch([_modes[pos] intValue]) {
        case 120:case 121:case 125:case 126:case 135:case 136:
        case 137:case 140:case 141:case 142:case 160:case 170:
        case 171:case 172:case 173:case 190:
            return modeInfo->valueFormats[ranges[pos]];
        default:
            switch (subLCDPointPosTemp) {
                case 0: return @"%.0f";
                case 1:	return @"%.1f";
                case 2:	return @"%.2f";
                case 3:	return @"%.3f";
                case 4:	return @"%.4f";
                default:return @"%.0f";
            }
        }
}

NSString* getACDCString(int value){
    switch(value){
        case 1: return NSLocalizedString(@"protocol_DC",   @"DC");
        case 2: return NSLocalizedString(@"protocol_AC",   @"AC");
        case 3: return NSLocalizedString(@"protocol_ACDC", @"DC+AC");
        default: return @" ";
    }
}

NSString* getRecFuncString(int value){
    switch(value){
        case 1: return NSLocalizedString(@"protocol_MAX",       @"MAX");
        case 2: return NSLocalizedString(@"protocol_MIN",       @"MIN");
        case 3: return NSLocalizedString(@"protocol_AVG",       @"AVG");
        case 4: return NSLocalizedString(@"protocol_MAXMINAVG", @"MAX/MIN/AVG");
        default: return @" ";
    }
}

NSString* getHoldString(int value){
    switch(value){
        case 1: return NSLocalizedString(@"protocol_AHOLD",   @"A-HOLD");
        case 2: return NSLocalizedString(@"protocol_HOLD",    @"HOLD");
        default: return @" ";
    }
}

- (NSString*)getUnitString:(DataPos) pos
{
    ModeInfo *modeInfo = [self getModeInfo:[_modes[pos] intValue]];
    if (modeInfo == nil) return @"";
    if (ranges[pos] >= modeInfo->maxRange) ranges[pos] = modeInfo->maxRange - 1;
    
    return modeInfo->unitStrings[ranges[pos]];
}

- (double)getUnit:(DataPos) pos
{
    ModeInfo *modeInfo = [self getModeInfo:[_modes[pos] intValue]];
    if (modeInfo == nil) return 1.0;
    if (ranges[pos] >= modeInfo->maxRange) ranges[pos] = modeInfo->maxRange - 1;
    
    if (pos != SUB_LCD)
        return modeInfo->units[ranges[pos]];
    else {
        switch(subLCDPointPosTemp){
            case 0: return 1.0;
            case 1: return 0.1;
            case 2: return 0.01;
            case 3: return 0.001;
            case 4: return 0.0001;
            default: return 1.0;
        }
    }
}

- (NSString*) getModeName:(DataPos) pos
{
    ModeInfo *modeInfo = [self getModeInfo:[_modes[pos] intValue]];
    return (modeInfo == nil) ? @"" : modeInfo->name;
}

@end
