//
//  PublicUtil.m
//  OC架构
//
//  Created by 天星 on 2018/2/23.
//  Copyright © 2018年 天星. All rights reserved.
//

#import "PublicUtil.h"
#import "TabBarMainVC.h"
#import "TEEHomeViewController.h"
@implementation PublicUtil
+(void)presentLoginVC {
    BaseNC *baseLoginNC = (BaseNC *)loadVC(@"LoginBaseNC", @"Login");
    if ([UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController == nil) {
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:baseLoginNC animated:YES completion:^{
            
        }];
    }
}
@end
