//
//  ViewController.h
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;

- (void)connectStatus:(BOOL)bConnected;

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
