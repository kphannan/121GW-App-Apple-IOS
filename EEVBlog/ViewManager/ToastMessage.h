//
//  ToastMessage.h
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ToastMessage : UIAlertView

- (void)showWithMessage:(NSString *)message withContinuous:(BOOL)bContinous;

@end
