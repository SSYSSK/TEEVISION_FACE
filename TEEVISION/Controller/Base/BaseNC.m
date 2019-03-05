//
//  BaseNC.m
//  OC架构
//
//  Created by 天星 on 2018/2/5.
//  Copyright © 2018年 天星. All rights reserved.
//

#import "BaseNC.h"
#import "public.h"
@interface BaseNC ()

@end

@implementation BaseNC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationBar setBackgroundImage:[self getNavigationBarBgImag] forBarMetrics:UIBarMetricsDefault];
    
    // 设置title颜色
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],NSFontAttributeName:[UIFont boldSystemFontOfSize:18]}];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)getNavigationBarBgImag {
    if (IS_IPHONE_X) {
        return [UIImage imageNamed:@"icon_navigationBarBg"];
    }else {
        return [UIImage imageNamed:@"icon_navigationBarBg"];
    }
}

@end
