//
//  BizRequestCenter.h
//  OC架构
//
//  Created by 天星 on 2018/2/22.
//  Copyright © 2018年 天星. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cbsNetWork.h"
@interface BizRequestCenter : NSObject

+ (instancetype)sharedManager;

/**
 * 1、获取首页数据
 */
-(void)getHomePageWithSuccessBlock:(requestSuccessBlock)success WithFailurBlock:(requestFailureBlock)failure;
@end
