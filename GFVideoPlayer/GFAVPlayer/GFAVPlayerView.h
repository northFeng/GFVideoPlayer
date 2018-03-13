//
//  GFAVPlayerView.h
//  GFAPP
//  视频播放器
//  Created by XinKun on 2017/12/5.
//  Copyright © 2017年 North_feng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GFAVPlayerViewDelegate <NSObject>

/**
 *  点击返回按钮
 */
- (void)AVPlayerClickBackButtonOnAVPlayerView:(id)sender;

/**
 *  点击全屏按钮
 */
- (void)AVPlayerClickFullScreenButtonOnAVPlayerView:(BOOL)sender;

/**
 *  状态条显示&&隐藏触发
 */
- (void)AVPlayerToolBarViewShowOrHideOnAVPlayerView:(BOOL)sender;

@end

@interface GFAVPlayerView : UIView

///视频地址
@property (nonatomic,strong) NSURL *avUrl;

///视频标题
@property (nonatomic,copy) NSString *avTitle;

///按钮点击代理
@property (nonatomic,weak) id <GFAVPlayerViewDelegate>delegate;

/**
 播放视屏
 */
- (void)playWith:(NSURL *)url withTitle:(NSString *)title;

/**
 开始视屏
 */
- (void)play;


/**
 暂停视屏
 */
- (void)pause;

/**
 控制播放速率
 */
- (void)changPlayerRateFloat:(float)rate;

/**
 控制播放分辨率
 */
- (void)changPlayerBitRateFloat:(float)bitRate;


@end
