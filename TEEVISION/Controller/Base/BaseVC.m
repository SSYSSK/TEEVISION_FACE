//
//  BaseVC.m
//  OC架构
//
//  Created by 天星 on 2018/2/5.
//  Copyright © 2018年 天星. All rights reserved.
//

#import "BaseVC.h"

@interface BaseVC ()


@end

@implementation BaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addLeftButton];
}

- (void)addLeftButton {

    // 隐藏返回按钮文字
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    // 设置返回按钮颜色
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
