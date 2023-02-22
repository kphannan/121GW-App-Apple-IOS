//
//  AppDelegate.h
//  EEVBlog
//
//  Created by sangho on 2016. 9. 26..
//  Copyright © 2016년 finest. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataProtocol.h"
#import "DataProvider.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DataProtocol *protocol;
@property (strong, nonatomic) DataProvider *dataProvider;

@end

