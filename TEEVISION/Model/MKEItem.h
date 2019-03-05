//
//  MKEItem.h
//  OC架构
//
//  Created by 天星 on 2018/2/7.
//  Copyright © 2018年 天星. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MKEItem : NSObject
@property(nonatomic,copy)NSString *name;
@property(nonatomic,assign)float price;
@property(nonatomic,assign)float finalPrice;
@property(nonatomic,copy)NSString *path;
@end
