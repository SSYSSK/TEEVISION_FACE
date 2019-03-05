//
//  TabBarMainVC.m
//  OC架构
//
//  Created by 天星 on 2018/2/5.
//  Copyright © 2018年 天星. All rights reserved.
//

#import "TabBarMainVC.h"
#import "public.h"
@interface TabBarMainVC ()

@end

@implementation TabBarMainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableDictionary *selectedAttrs = [NSMutableDictionary dictionary];
    selectedAttrs[NSForegroundColorAttributeName] = RGB(142, 144, 243, 1);
    UITabBarItem *item = [UITabBarItem appearance];
    [item setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];

//    gMainTC = self
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
