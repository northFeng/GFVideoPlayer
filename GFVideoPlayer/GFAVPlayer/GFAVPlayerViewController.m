//
//  GFAVPlayerViewController.m
//  GFAPP
//
//  Created by XinKun on 2017/12/6.
//  Copyright © 2017年 North_feng. All rights reserved.
//

#import "GFAVPlayerViewController.h"

#import "GFAVPlayerView.h"

#define APP_SCREEN_WIDTH  ([UIScreen mainScreen].bounds.size.width)
#define APP_SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

@interface GFAVPlayerViewController ()<GFAVPlayerViewDelegate>

@end

@implementation GFAVPlayerViewController
{
    GFAVPlayerView *_avPlayer;
    BOOL _statusIsHide;
    float _rate;
    float _bitRate;
}

- (void)playerFaster{
    
    _rate += 0.5;
    
    [_avPlayer changPlayerRateFloat:_rate];
    
}

- (void)playerSlow{
    
    _rate -= 0.5;
    
    if (_rate < 0) {
        _rate = 0.0;
    }
    
    [_avPlayer changPlayerRateFloat:_rate];
    
}

- (void)playerBitHight{
    
    _bitRate += 5;
    
    [_avPlayer changPlayerBitRateFloat:_bitRate];
    
}

- (void)playerBitLow{
    
    _bitRate -= 5;
    
    if (_bitRate < 15) {
        _bitRate = 15;
    }
    
    [_avPlayer changPlayerBitRateFloat:_bitRate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    _statusIsHide = NO;//初始化数据
    _rate = 1.0;
    _bitRate = 25;
    
    UIButton *buttonOne = [UIButton buttonWithType:0];
    buttonOne.frame = CGRectMake(10, 400, 100, 50);
    [buttonOne setTitle:@"进度变快" forState:0];
    [buttonOne setBackgroundColor:[UIColor greenColor]];
    [buttonOne addTarget:self action:@selector(playerFaster) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonOne];
    
    UIButton *buttonTwo = [UIButton buttonWithType:0];
    buttonTwo.frame = CGRectMake(10, 500, 100, 50);
    [buttonTwo setTitle:@"进度变慢" forState:0];
    [buttonTwo setBackgroundColor:[UIColor greenColor]];
    [buttonTwo addTarget:self action:@selector(playerSlow) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonTwo];
    
    UIButton *buttonThr = [UIButton buttonWithType:0];
    buttonThr.frame = CGRectMake(150, 400, 100, 50);
    [buttonThr setTitle:@"分辨率升高" forState:0];
    [buttonThr setBackgroundColor:[UIColor greenColor]];
    [buttonThr addTarget:self action:@selector(playerBitHight) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonThr];
    
    UIButton *buttonFor = [UIButton buttonWithType:0];
    buttonFor.frame = CGRectMake(150, 500, 100, 50);
    [buttonFor setTitle:@"分辨率降低" forState:0];
    [buttonFor setBackgroundColor:[UIColor greenColor]];
    [buttonFor addTarget:self action:@selector(playerBitLow) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonFor];
    
    
    //播放网络视频
    //http://120.25.226.186:32812/resources/videos/minion_01.mp4
    //http://ips.ifeng.com/video.ifeng.com/video04/2011/03/24/480x360_offline20110324.mp4
    NSString *filePath = @"http://120.25.226.186:32812/resources/videos/minion_01.mp4";
    
    NSURL *fileURL = [NSURL URLWithString:filePath];
    if (fileURL == nil) {
        fileURL = [NSURL URLWithString:[filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    //CGRectMake(0, 100, APP_SCREEN_WIDTH, 300)
    
    _avPlayer = [[GFAVPlayerView alloc] initWithFrame:CGRectMake(0, 64, APP_SCREEN_WIDTH, 300)];
    [_avPlayer playWith:fileURL withTitle:@"凤凰网视频"];
    _avPlayer.delegate = self;
    [self.view addSubview:_avPlayer];
    
}


//点击返回按钮
- (void)AVPlayerClickBackButtonOnAVPlayerView:(id)sender{
    
    NSLog(@"点击了返回");
    
}

//点击全屏按钮
- (void)AVPlayerClickFullScreenButtonOnAVPlayerView:(BOOL)sender{
    NSLog(@"全屏按钮");
    if (sender) {
        [UIView animateWithDuration:0.3 animations:^{
            //设置屏幕向右翻转
            NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
            _avPlayer.frame = CGRectMake(0, 64, APP_SCREEN_WIDTH, APP_SCREEN_HEIGHT - 64);
        }];
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            //屏幕恢复原样
            NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
            [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
            _avPlayer.frame = CGRectMake(0, 64, APP_SCREEN_WIDTH, 300);
        }];
    }
}


//工具条显示&&隐藏
- (void)AVPlayerToolBarViewShowOrHideOnAVPlayerView:(BOOL)sender{
    
    if (sender) {
        //隐藏
        NSLog(@"工具条隐藏");
        [self setStatusBarIsHide:sender];
    }else{
        //显示
        NSLog(@"工具条显示");
        [self setStatusBarIsHide:sender];
    }
    
}

///设置状态栏是否隐藏
- (void)setStatusBarIsHide:(BOOL)isHide{
    _statusIsHide = isHide;
    //更新状态栏
    [self setNeedsStatusBarAppearanceUpdate];
}

//是否隐藏
- (BOOL)prefersStatusBarHidden{
    return _statusIsHide;
}



- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    //    static BOOL a = YES;
    //    if (a) {
    //        [self setScreenInterfaceOrientationRight];
    //        a = NO;
    //    }else{
    //        [self setScreenInterfaceOrientationDefault];
    //        a = YES;
    //    }
    
}


//开启自动旋转屏幕
- (BOOL)shouldAutorotate{
    
    return YES;
}
//设置旋转屏幕为左横和右横
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


///左侧第一个按钮
- (void)leftFirstButtonClick:(UIButton *)button{
    
    //默认这个为返回按钮
    
    //[self dismissViewControllerAnimated:YES completion:nil];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
