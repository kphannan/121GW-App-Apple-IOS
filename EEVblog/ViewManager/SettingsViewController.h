//
//  SettingsViewController.h
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *buttonClickSound;
@property (weak, nonatomic) IBOutlet UISwitch *buttonClickVibration;
@property (weak, nonatomic) IBOutlet UISlider *refreshRate;
@property (weak, nonatomic) IBOutlet UILabel *refreshRateLabel;
@property (weak, nonatomic) IBOutlet UISwitch *continuousRecording;
@property (weak, nonatomic) IBOutlet UILabel *maxSamplesLabel;
@property (weak, nonatomic) IBOutlet UISlider *maxSamples;
@property (weak, nonatomic) IBOutlet UILabel *samplingIntervalLabel;
@property (weak, nonatomic) IBOutlet UISlider *minuteSlider;
@property (weak, nonatomic) IBOutlet UISlider *secondSlider;

- (IBAction)changeButtonClickSound:(UISwitch *)sender;
- (IBAction)changeButtonClickVibration:(UISwitch *)sender;
- (IBAction)changeRefreshRate:(UISlider *)sender;
- (IBAction)changeContinuousRecording:(id)sender;
- (IBAction)changeMaxSamples:(UISlider *)sender;
- (IBAction)changeMinute:(UISlider *)sender;
- (IBAction)changeSecond:(UISlider *)sender;
- (IBAction)decreaseMinute:(UIButton *)sender;
- (IBAction)increaseMinute:(UIButton *)sender;
- (IBAction)decreaseSecond:(UIButton *)sender;
- (IBAction)increaseSecond:(UIButton *)sender;

@end

#define K_BUTTON_CLICK_SOUND     @"buttonClickSound"
#define K_BUTTON_CLICK_VIBRATION @"buttonClickVibration"
#define K_REFRESH_RATE           @"refreshRate"
#define K_CONTINUOUS_RECORDING   @"continuousRecording"
#define K_MAX_SAMPLES            @"maxSamples"
#define K_SAMPLING_INTERVAL      @"samplingInterval"

#define K_DEFAULT_MAX_SAMPLES       100
#define K_DEFAULT_REFRESH_RATE      100
#define K_DEFAULT_SAMPLING_INTERVAL 1
