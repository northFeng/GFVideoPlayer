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

/**
 *  视频播放完毕
 */
- (void)AVPlayerPlayEnd;

/**
 *  @abstract 缓存数据播放完后———————>网络原因导致缓存加载受阻，等待视图出现，这里可进行网络状态判断，来自己控制播放的提示
 *
 *  @discussion 这个代理触发的比较频繁，处理业务逻辑应该在这里进行延迟判断
                建议先判断网络是否改变，如果为非WiFi网络，则立刻进行停止播放，并进行提示用户当前为非WiFi网络是否继续播放
                如果仍未WiFi网络，则建议5秒后在处理逻辑，如果再次触发这个代理，则清空之前的处理，从头再开始进行判断处理，加载过程停止加载告诉用户
                网络不好
 */
- (void)AVPlayerCacheLoadingBreakForNetWork;


/**
 *  缓存足够播放后开始播放
 *
 *  @discussion 只要视频正在播放这个代理会不断的进行调用
 */
- (void)AVPlayerCacheBufferFullToPlay;

/**
 *  视频加载失败
 */
- (void)AVPlayerLoadFailed;

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
