//
//  MKEHomeData.h
//  OC架构
//
//  Created by 天星 on 2018/2/22.
//  Copyright © 2018年 天星. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"
@interface MKEHomeData : BaseModel
@property(nonatomic,strong)NSMutableArray *essencePosts;
@property(nonatomic,strong)NSMutableArray *hotPosts;

-(void)getHomeData;
@end
