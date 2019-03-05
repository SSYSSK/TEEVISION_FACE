//
//  MKEHomeData.m
//  OC架构
//
//  Created by 天星 on 2018/2/22.
//  Copyright © 2018年 天星. All rights reserved.
//

#import "MKEHomeData.h"

@implementation MKEHomeData

-(void)getHomeData {
    [[BizRequestCenter sharedManager]getHomePageWithSuccessBlock:^(NSDictionary *dic) {
        MKEHomeData *homeData = [MKEHomeData mj_objectWithKeyValues:dic[@"data"]];
        [self.delegate refreshUI:homeData];
    } WithFailurBlock:^(NSError *error) {
        [self.delegate refreshUI:nil];
    }];
}

+ (NSDictionary *)objectClassInArray{
    return @{
             @"essencePosts" : @"MKEPost",
             @"hotPosts" : @"MKEPost"
             };
}
@end
