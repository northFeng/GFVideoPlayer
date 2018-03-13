//
//  ViewController.m
//  GFVideoPlayer
//
//  Created by XinKun on 2018/3/13.
//  Copyright © 2018年 North_feng. All rights reserved.
//

#import "ViewController.h"

#import "GFAVPlayerViewController.h"//自封装的视频播放控制器

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [UIButton buttonWithType:0];
    
    button.frame = CGRectMake(10, 100, 150, 50);
    
    [button setTitle:@"进入视频播放器" forState:0];
    
    [button setBackgroundColor:[UIColor greenColor]];
    
    [button addTarget:self action:@selector(goIntoVideoPlayerView:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button];
    
}
- (IBAction)goIntoVideoPlayerView:(id)sender {
    
    GFAVPlayerViewController *avplayer = [[GFAVPlayerViewController alloc] init];
    
    [self.navigationController pushViewController:avplayer animated:YES];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
