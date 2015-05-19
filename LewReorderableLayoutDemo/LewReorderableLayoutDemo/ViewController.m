//
//  ViewController.m
//  LewReorderableLayoutDemo
//
//  Created by pljhonglu on 15/5/19.
//  Copyright (c) 2015年 pljhonglu. All rights reserved.
//

#import "ViewController.h"
#import "VerticalViewController.h"
#import "HorizontalViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showVerticalViewControllerAction:(id)sender{
    VerticalViewController *vc = [[VerticalViewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)showHorizontalViewControllerAction:(id)sender{
    HorizontalViewController *vc = [[HorizontalViewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}
@end
