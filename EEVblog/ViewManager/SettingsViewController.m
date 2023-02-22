//
//  SettingsViewController.m
//  EEVBlog
//
//  Created by sangho on 2016. 10. 3..
//  Copyright (c) 2016년 한국산업기술대학교. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()
{
    NSUInteger samplingInterval;
}

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _buttonClickSound.on = ![[NSUserDefaults standardUserDefaults] boolForKey:K_BUTTON_CLICK_SOUND];
    _buttonClickVibration.on = [[NSUserDefaults standardUserDefaults] boolForKey:K_BUTTON_CLICK_VIBRATION];
    _continuousRecording.on = [[NSUserDefaults standardUserDefaults]boolForKey:K_CONTINUOUS_RECORDING];
    
    _refreshRate.value = (double)[[NSUserDefaults standardUserDefaults] integerForKey:K_REFRESH_RATE];
    if (_refreshRate.value == 0) _refreshRate.value = K_DEFAULT_REFRESH_RATE;
    
    [_refreshRateLabel setText:[NSString stringWithFormat:@"%@ (%i ms)", NSLocalizedString(@"refresh_rate", @"Refresh Rate"), (int)_refreshRate.value]];
    
    _maxSamples.value = (double)[[NSUserDefaults standardUserDefaults]integerForKey:K_MAX_SAMPLES];
    if (_maxSamples.value == 0) _maxSamples.value = K_DEFAULT_MAX_SAMPLES;
    
    [_maxSamplesLabel setText:[NSString stringWithFormat:@"%@ (%i)", NSLocalizedString(@"max_samples", @"Max. Samples"), (int)_maxSamples.value]];
    
    samplingInterval = (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:K_SAMPLING_INTERVAL];
    if (samplingInterval == 0) samplingInterval = K_DEFAULT_SAMPLING_INTERVAL;
    
    _minuteSlider.value = samplingInterval / 60;
    _secondSlider.value = samplingInterval % 60;
    [_samplingIntervalLabel setText:[NSString stringWithFormat:@"%@ (%i %@ %i %@)", NSLocalizedString(@"logging_interval", @"Logging Interval"),
                                     (int)(samplingInterval / 60), NSLocalizedString(@"min", @"min."),
                                     (int)(samplingInterval % 60), NSLocalizedString(@"sec", @"sec.")]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeButtonClickSound:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:![_buttonClickSound isOn] forKey:K_BUTTON_CLICK_SOUND];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)changeButtonClickVibration:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[_buttonClickVibration isOn] forKey:K_BUTTON_CLICK_VIBRATION];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)changeRefreshRate:(UISlider *)sender {
    sender.value = ((int)sender.value / 100) * 100;
    [_refreshRateLabel setText:[NSString stringWithFormat:@"%@ (%i ms)", NSLocalizedString(@"refresh_rate", @"Refresh Rate") ,(int)sender.value]];
    [[NSUserDefaults standardUserDefaults] setInteger:(int)sender.value forKey:K_REFRESH_RATE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)changeContinuousRecording:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[_continuousRecording isOn] forKey:K_CONTINUOUS_RECORDING];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)changeMaxSamples:(UISlider *)sender {
    sender.value = ((int)sender.value / 100) * 100;
    [_maxSamplesLabel setText:[NSString stringWithFormat:@"%@ (%i)", NSLocalizedString(@"max_samples", @"Max. Samples"),(int)sender.value]];
    [[NSUserDefaults standardUserDefaults] setInteger:(int)sender.value forKey:K_MAX_SAMPLES];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)changeSamplingInterval{
    samplingInterval = (int)_minuteSlider.value * 60 + (int)_secondSlider.value;
    
    [_samplingIntervalLabel setText:[NSString stringWithFormat:@"%@ (%i %@ %i %@)", NSLocalizedString(@"logging_interval", @"Logging Interval"),
                                     (int)(samplingInterval / 60), NSLocalizedString(@"min", @"min."),
                                     (int)(samplingInterval % 60), NSLocalizedString(@"sec", @"sec.")]];
    
    [[NSUserDefaults standardUserDefaults] setInteger:(int)samplingInterval forKey:K_SAMPLING_INTERVAL];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)changeMinute:(UISlider *)sender {
    if ((int)sender.value == 0 && (int)_secondSlider.value == 0)
        _secondSlider.value = 1;
    
    [self changeSamplingInterval];
}

- (IBAction)changeSecond:(UISlider *)sender {
    if ((int)sender.value == 0 && samplingInterval <= 1)
        sender.value = 1;
    
    [self changeSamplingInterval];
}

- (IBAction)decreaseMinute:(id)sender {
    if ((int)_minuteSlider.value > 0) _minuteSlider.value -= 1;
    
    if ((int)_minuteSlider.value == 0 && (int)_secondSlider.value == 0)
        _secondSlider.value = 1;
    
    [self changeSamplingInterval];
}

- (IBAction)increaseMinute:(UIButton *)sender {
    if ((int)_minuteSlider.value < 59)
        _minuteSlider.value += 1;
    
    [self changeSamplingInterval];
}

- (IBAction)decreaseSecond:(UIButton *)sender {
    if ((int)_secondSlider.value > 0)
        _secondSlider.value -= 1;
    
    if ((int)_minuteSlider.value == 0 && (int)_secondSlider.value == 0)
        _secondSlider.value = 1;
    
    [self changeSamplingInterval];
}

- (IBAction)increaseSecond:(UIButton *)sender {
    if ((int)_secondSlider.value < 59)
        _secondSlider.value += 1;
    
    [self changeSamplingInterval];
}

@end
