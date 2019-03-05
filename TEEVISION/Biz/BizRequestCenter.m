//
//  BizRequestCenter.m
//  OC架构
//
//  Created by 天星 on 2018/2/22.
//  Copyright © 2018年 天星. All rights reserved.
//

#import "BizRequestCenter.h"

@implementation BizRequestCenter

+ (instancetype)sharedManager {
    static BizRequestCenter *bizRequestCenter = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        bizRequestCenter = [[BizRequestCenter alloc]init];
    });
    return bizRequestCenter;
}

/**
 * 1、获取首页数据
 */
-(void)getHomePageWithSuccessBlock:(requestSuccessBlock)success WithFailurBlock:(requestFailureBlock)failure {
    [[cbsNetWork sharedManager] requestWithMethod:GET WithPath:@"home/getHomePage" WithParams:nil WithSuccessBlock:^(NSDictionary *dic) {
        success(dic);
    } WithFailurBlock:^(NSError *error) {
        failure(error);
    }];
}
@end
