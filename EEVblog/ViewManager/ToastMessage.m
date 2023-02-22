//
//  ToastMessage.m
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import "ToastMessage.h"

#define TOAST_MESSAGE_INTERVAL_SECOND   1

@implementation ToastMessage

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)setFrame:(CGRect)rect {
    // Called multiple times, 4 of those times count, so to reduce height by 40
    rect.size.height = 70;
    self.center = self.superview.center;
    [super setFrame:rect];
}

- (void)showWithMessage:(NSString *)message withContinuous:(BOOL)bContinuous
{
    [self setMessage:message];
    if (bContinuous == NO)
        [self performSelector:@selector(dismissAfterDelay) withObject:nil afterDelay:TOAST_MESSAGE_INTERVAL_SECOND];
    [self show];
}

- (void)dismissAfterDelay
{
    [self dismissWithClickedButtonIndex:0 animated:YES];
}


@end
