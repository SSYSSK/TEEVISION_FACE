//
//  MKEPost.h
//  OC架构
//
//  Created by 天星 on 2018/2/22.
//  Copyright © 2018年 天星. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MKEPost : NSObject

@property(nonatomic,assign)long createTime;
@property(nonatomic,assign)int postsId;
@property(nonatomic,copy)NSString *postsTitle;
@property(nonatomic,copy)NSString *postsContent;

@end
