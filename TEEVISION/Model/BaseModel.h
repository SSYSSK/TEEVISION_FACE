//
//  BaseModel.h
//  OC架构
//
//  Created by 天星 on 2018/2/22.
//  Copyright © 2018年 天星. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BizRequestCenter.h"
#import "MJExtension.h"
@protocol MKEUIRefreshDelegate<NSObject>
-(void)refreshUI:(id)data;
@end
@interface BaseModel : NSObject
@property(nonatomic,weak)id<MKEUIRefreshDelegate>delegate;
@end
