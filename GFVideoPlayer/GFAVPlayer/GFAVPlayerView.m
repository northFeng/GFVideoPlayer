//
//  GFAVPlayerView.m
//  GFAPP
//
//  Created by XinKun on 2017/12/5.
//  Copyright © 2017年 North_feng. All rights reserved.
//

#import "GFAVPlayerView.h"

#import "Masonry.h"

//引入视频框架
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "GFAVPlayerItem.h"//自定义AVPlayerItem

#import "GFCacheProgressSlider.h"//自定义缓存条

typedef NS_ENUM(NSUInteger, AVDirection) {
    AVDirectionNone = 0,
    AVDirectionHrizontal,    //水平方向滑动
    AVDirectionVertical,     //垂直方向滑动
};

@interface GFAVPlayerView (){
    UIView   *_topView;
    UIView   *_toolView;
    AVPlayer *_player;
    GFCacheProgressSlider *_progressSlider; //控制播放进度
    UILabel  *_currentTime;
    UILabel  *_totalTime;
    UIButton *_playBtn;        //播放按钮
    UIButton *_playBigBtn;//中央播放大按钮
    UIButton *_fullScreenBtn;  //全屏按钮
    UILabel *_titleLabel;//上方标题
    id _playTimeObserver;
    
    BOOL _isPause;//调用暂停功能
    
}

//视屏总时长
@property (nonatomic, assign) CGFloat duration;

//以下是滑动手势相关变量
@property (nonatomic, assign) AVDirection direction;
@property (nonatomic, assign) CGPoint startPoint;//开始滑动点
@property (nonatomic, assign) CGFloat startVB;//亮度&&音量
@property (nonatomic, assign) CGFloat startVideoRate;

@property (nonatomic, strong) MPVolumeView *volumeView;//调节系统音量

@property (nonatomic, strong) UISlider *volumeViewSlider;  //控制音量
@property (nonatomic, strong) UISlider *brightnessSlider;  //控制亮度

///系统等待视图
@property (nonatomic,strong) UIActivityIndicatorView *waitingView;

@end

#define GF_SCREEN_BOUNDS  [UIScreen mainScreen].bounds
#define R_G_B(_r_,_g_,_b_)          \
[UIColor colorWithRed:_r_/255. green:_g_/255. blue:_b_/255. alpha:1.0]
#define R_G_B_A(_r_,_g_,_b_,_a_)    \
[UIColor colorWithRed:_r_/255. green:_g_/255. blue:_b_/255. alpha:_a_]
#define Top_Height 44.
#define Bottom_Height 44.
#define TitleColor [UIColor whiteColor]
#define TitleFont 17
#define TimeColor [UIColor whiteColor]
#define TimeFont 10

NSString *imagePlay = @"ic_video_paly@2x";
NSString *imageBigPlay = @"ic_video_play_big@2x";
NSString *imagePause = @"ic_video_pause@2x";
NSString *imageProgress = @"av_progressTime@2x";
NSString *imageMiniScree = @"ic_video_minimize@2x";
NSString *imageFullScree = @"ic_video_fullscreen@2x";
NSString *imageBack = @"ic_detail_back@2x";

@implementation GFAVPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        //初始化一些数据
        _isPause = NO;
        
        [self createViewsWithFrame:frame];
        
        /* 不使用这种方式进行横竖屏切换
         //监听横竖屏切换
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
         */
        
        //监听程序进入后台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)name:UIApplicationWillResignActiveNotification object:nil];
        
        //监听播放结束
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        //监听音频播放中断
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    return self;
}

#pragma mark - 监听视频进行状态处理
//程序进入后台
- (void)applicationWillResignActive:(NSNotification *)notification {
    [self pause];//暂停播放
}
//视频播放完毕
-(void)moviePlayDidEnd:(NSNotification *)notification
{
    NSLog(@"视频播放完毕！");
    //暂停
    [self pause];
    CMTime dur = _player.currentItem.duration;
    [_player seekToTime:CMTimeMultiplyByFloat64(dur, 0.)];
    
}

//音频播放中断
- (void)movieInterruption:(NSNotification *)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interuptionType = [[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    NSNumber  *seccondReason  = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey] ;
    switch (interuptionType) {
        case AVAudioSessionInterruptionTypeBegan:
        {
            //收到中断，停止音频播放
            [self pause];
            break;
        }
        case AVAudioSessionInterruptionTypeEnded:
            //系统中断结束
            break;
    }
    switch ([seccondReason integerValue]) {
        case AVAudioSessionInterruptionOptionShouldResume:
            //恢复音频播放
            [self play];
            break;
        default:
            break;
    }
}

#pragma mark - 播放和暂停
//播放
- (void)play {
    
    if (_player) {
        _isPause = NO;
        [_player play];
        _playBtn.selected = YES;
        _playBigBtn.hidden = YES;
    }else{
        //证明没有加载，在此进行重新加载
        [self playWith:_avUrl withTitle:_avTitle];
    }
}

//暂停
- (void)pause {
    if (_player) {
        _isPause = YES;
        [_player pause];
        _playBtn.selected = NO;
        _playBigBtn.hidden = NO;
    }
}

#pragma mark - 控制播放速率
- (void)changPlayerRateFloat:(float)rate{
    
    //AVPlayerItem (AVPlayerItemRateAndSteppingSupport)中提供该播放媒体是否播放速率的范围
    _player.rate = rate;
}

#pragma mark - 控制视频的分辨率
//@interface AVPlayerItem (AVPlayerItemVariantControl)
- (void)changPlayerBitRateFloat:(float)bitRate{
    
    /**
     preferredPeakBitRate:比特率
     preferredMaximumResolution：分辨率大小
     */
    _player.currentItem.preferredPeakBitRate = bitRate;
    
    if (@available(iOS 11.0, *)) {
        _player.currentItem.preferredMaximumResolution = CGSizeMake(100, 50);
    } else {
        // Fallback on earlier versions
    }
    
}



#pragma mark - AVPlayer的创建
- (void)playWith:(NSURL *)url withTitle:(NSString *)title{
    //标题
    _titleLabel.text = title;
    _avUrl = url;
    _avTitle = title;
    
    //加载视频资源的类
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    //AVURLAsset 通过tracks关键字会将资源异步加载在程序的一个临时内存缓冲区中
    [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^{
        //能够得到资源被加载的状态
        AVKeyValueStatus status = [asset statusOfValueForKey:@"tracks" error:nil];
        //如果资源加载完成,开始进行播放
        /**
         AVKeyValueStatusUnknown,//未知状态
         AVKeyValueStatusLoading,//正在加载
         AVKeyValueStatusLoaded,//已经加载
         AVKeyValueStatusFailed,//加载失败
         AVKeyValueStatusCancelled//取消
         */
        if (status == AVKeyValueStatusLoaded) {
            //将加载好的资源放入AVPlayerItem 中，item中包含视频资源数据,视频资源时长、当前播放的时间点等信息
            GFAVPlayerItem *item = [GFAVPlayerItem playerItemWithAsset:asset];
            item.observer = self;
            
            //观察播放状态
            [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
            //AVPlayerItem
            //观察缓冲进度
            [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
            //添加
            [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
            [item addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
            [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
            
            if (_player) {
                [_player removeTimeObserver:_playTimeObserver];
                [_player replaceCurrentItemWithPlayerItem:item];
            }else {
                _player = [[AVPlayer alloc] initWithPlayerItem:item];
            }
            
            //监测播放状态  来  处理 视频暂停播放的情况（iOS10）
            [_player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
            
            //需要时时显示播放的进度
            //根据播放的帧数、速率，进行时间的异步(在子线程中完成)获取
            __weak AVPlayer *weakPlayer     = _player;
            __weak UISlider *weakSlider     = _progressSlider;
            __weak UILabel *weakCurrentTime = _currentTime;
            __weak typeof(self) weakSelf    = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                //缓存清零
                [_progressSlider setCacheProgressReturnToZero];
            });
            //开始监听(这里面不断进行回调)---->返回的是这个函数的观察者，播放器销毁的时候要移除这个观察者
            _playTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                //获取当前播放时间
                NSInteger current = CMTimeGetSeconds(weakPlayer.currentItem.currentTime);
                
                float pro = current*1.0/weakSelf.duration;
                if (pro >= 0.0 && pro <= 1.0) {
                    //不断改变播放进度条
                    weakSlider.value     = pro;
                    //不断改变播放时间
                    weakCurrentTime.text = [weakSelf getTime:current];
                }
            }];
        }else if (status == AVKeyValueStatusFailed){
            NSLog(@"加载失败");
        }
        
    }];
    
}


#pragma mark - 相关监听（播放状态——>设置播放图层 && 缓存进度 && 缓存加载状态）
//监听播放开始
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    
    if ([object isKindOfClass:[AVPlayerItem class]]) {
        
        AVPlayerItem *item = (AVPlayerItem *)object;
        
        if ([keyPath isEqualToString:@"status"]) {
            NSLog(@"监测播放状态");
            switch (item.status) {
                case AVPlayerStatusReadyToPlay:{
                    //获取当前播放时间
                    NSInteger current = CMTimeGetSeconds(item.currentTime);
                    //总时间
                    self.duration = CMTimeGetSeconds(item.duration);
                    
                    float pro = current*1.0/self.duration;
                    if (pro >= 0.0 && pro <= 1.0) {
                        _progressSlider.value  = pro;
                        _currentTime.text      = [self getTime:current];
                        _totalTime.text        = [self getTime:self.duration];
                    }
                    //将播放器与播放视图关联
                    [self setPlayer:_player];
                    [self play];
                    
                    //关闭等待视图
                    NSLog(@"缓存已满足，开始播放");
                }
                    break;
                case AVPlayerStatusFailed:{
                    NSLog(@"AVPlayerStatusFailed:加载失败，网络或者服务器出现问题");
                    [self pause];
                }
                    break;
                case AVPlayerStatusUnknown:{
                    NSLog(@"AVPlayerStatusUnknown:未知状态，此时不能播放");
                    [self pause];
                }
                    break;
                    
                default:
                    break;
            }
            
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            //监听播放器的下载进度
            NSTimeInterval timeInterval = [self availableDuration];
            float pro = timeInterval/self.duration;
            if (pro >= 0.0 && pro <= 1.0) {
                //NSLog(@"缓冲进度：%f",pro);
                //设置缓存进度
                [_progressSlider setCacheProgressValue:pro];
            }
        }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            //内部底层会自动播放
            NSLog(@"playbackLikelyToKeepUp缓冲达到可播放程度了");
            
        }else if ([keyPath isEqualToString:@"playbackBufferFull"]){
            //这个不会触发
            NSLog(@"playbackBufferFull缓存满了");
            
        }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            //监听播放器在缓冲数据的状态
            NSLog(@"playbackBufferEmpty缓冲不足");
        }
        
    }else if ([object isKindOfClass:[AVPlayer class]]){
        
        if (@available(iOS 10.0, *)) {
            if ([keyPath isEqualToString:@"timeControlStatus"]) {

                //监测视频播放状态
                /**
                 AVPlayerTimeControlStatusPaused,
                 AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate,
                 AVPlayerTimeControlStatusPlaying
                 */
                switch (_player.timeControlStatus) {
                    case AVPlayerTimeControlStatusPaused:
                        NSLog(@"AVPlayerTimeControlStatusPaused:播放暂停");
                        //停止菊花
                        [self.waitingView stopAnimating];
                        break;
                    case AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate:
                        NSLog(@"AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate:播放正在缓存");
                        //开始菊花(这里可以判断网络的状态，并进行触发自动停止播放&&提示用户网络状态不好)
                        [self.waitingView startAnimating];
                        //AVPlayerWaitingToMinimizeStallsReason没有缓存
                        NSLog(@"------>缓存原因：%@",_player.reasonForWaitingToPlay);
                        break;
                    case AVPlayerTimeControlStatusPlaying:
                        NSLog(@"AVPlayerTimeControlStatusPlaying:播放开始");
                        //停止菊花
                        [self.waitingView stopAnimating];
                        break;
                    default:
                        break;
                }
            }
        } else {
            // Fallback on earlier versions
            //iOS10以下
            
        }
        
    }
}

//每个视图都对应一个层，改变视图的形状、动画效果\与播放器的关联等，都可以在层上操作
- (void)setPlayer:(AVPlayer *)myPlayer
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
    [playerLayer setPlayer:myPlayer];
}

//在调用视图的layer时，会自动触发layerClass方法，重写它，保证返回的类型是AVPlayerLayer
+ (Class)layerClass
{
    return [AVPlayerLayer class];
}


#pragma mark - 计算缓冲时间
//计算缓冲时间
- (CGFloat)availableDuration {
    //时间范围集合，玩家可以随时获得媒体数据
    NSArray *loadedTimeRanges = [_player.currentItem loadedTimeRanges];
    CMTimeRange range = [loadedTimeRanges.firstObject CMTimeRangeValue];
    CGFloat start = CMTimeGetSeconds(range.start);
    CGFloat duration = CMTimeGetSeconds(range.duration);
    return (start + duration);
}

#pragma mark - 创建视图
//创建相关UI
-(void)createViewsWithFrame:(CGRect)frame
{
    self.backgroundColor=[UIColor blackColor];
    
    //添加点击手势
    UITapGestureRecognizer *tapGROne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGROne:)];
    tapGROne.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGROne];
    //添加双击手势
    UITapGestureRecognizer *tapGRTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGRTwo:)];
    tapGRTwo.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapGRTwo];
    //点击手势遇到双击手势失效
    [tapGROne requireGestureRecognizerToFail:tapGRTwo];
    
    //获取系统的音量view
    self.volumeView.frame = CGRectMake(frame.size.width-30, (frame.size.height-100)/2.0, 20, 100);
    self.volumeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    self.volumeView.hidden = YES;
    [self addSubview:self.volumeView];
    
    //控制亮度
    self.brightnessSlider.frame = CGRectMake(20, (frame.size.height-100)/2.0, 20, 100);
    self.brightnessSlider.minimumValue = 0.0;
    self.brightnessSlider.maximumValue = 1.0;
    self.brightnessSlider.hidden = YES;
    [self.brightnessSlider addTarget:self action:@selector(brightnessChanged:) forControlEvents:UIControlEventValueChanged];
    self.brightnessSlider.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:self.brightnessSlider];
    
    //顶部view
    _topView = [[UIView alloc]init];//WithFrame:CGRectMake(0, 0, frame.size.width, 44)];
    _topView.backgroundColor = R_G_B_A(34, 34, 34, 0.9);
    [self addSubview:_topView];
    [_topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.and.right.equalTo(self);
        make.height.mas_equalTo(Top_Height);
    }];
    
    //返回按钮
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.backgroundColor = [UIColor clearColor];
    [backBtn setImage:[UIImage imageNamed:imageBack] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.and.bottom.equalTo(_topView);
        make.width.mas_equalTo(40);
    }];
    
    //标题
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.font = [UIFont systemFontOfSize:TitleFont];
    _titleLabel.textColor = TitleColor;
    _titleLabel.numberOfLines = 1;
    [_topView addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(backBtn.mas_right).offset(10);
        make.top.and.bottom.equalTo(_topView);
        make.right.equalTo(_topView).offset(-15);
    }];
    
    
    //底部view
    _toolView = [[UIView alloc] init];//WithFrame:CGRectMake(0, frame.size.height-40, frame.size.width, 40)];
    _toolView.backgroundColor = R_G_B_A(34, 34, 34, 0.9);
    [self addSubview:_toolView];
    [_toolView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.and.bottom.equalTo(self);
        make.height.mas_equalTo(Bottom_Height);
    }];
    
    //播放暂停按钮
    _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //[_playBtn setFrame:CGRectMake(5,10,20,20)];
    _playBtn.backgroundColor = [UIColor clearColor];
    _playBtn.selected = NO;//默认为播放状态
    [_playBtn setImage:[UIImage imageNamed:imagePause] forState:UIControlStateNormal];
    [_playBtn setImage:[UIImage imageNamed:imagePlay] forState:UIControlStateSelected];
    [_playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    //[_playBtn setContentEdgeInsets:UIEdgeInsetsMake(14, 19, 14, 19)];
    [_toolView addSubview:_playBtn];
    [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.and.bottom.equalTo(_toolView);
        make.width.mas_equalTo(50);
    }];
    
    //播放暂停大按钮
    _playBigBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //[_playBtn setFrame:CGRectMake(5,10,20,20)];
    _playBigBtn.backgroundColor = [UIColor clearColor];
    //先隐藏
    _playBigBtn.hidden = NO;
    [_playBigBtn setImage:[UIImage imageNamed:imageBigPlay] forState:UIControlStateNormal];
    [_playBigBtn addTarget:self action:@selector(playBigBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    //[_playBtn setContentEdgeInsets:UIEdgeInsetsMake(14, 19, 14, 19)];
    [self addSubview:_playBigBtn];
    [_playBigBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.and.height.mas_equalTo(100);
    }];
    
    
    
    //当前时间
    _currentTime = [[UILabel alloc] init];//WithFrame:CGRectMake(CGRectGetMaxX(_playBtn.frame), 10, 40, 20)];
    _currentTime.text = @"00:00";
    _currentTime.numberOfLines = 1;
    _currentTime.textColor = TimeColor;
    _currentTime.font = [UIFont systemFontOfSize:TimeFont];
    _currentTime.textAlignment = NSTextAlignmentRight;
    [_toolView addSubview:_currentTime];
    [_currentTime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_playBtn.mas_right).offset(15);
        make.top.bottom.equalTo(_toolView);
        make.width.mas_equalTo(35);
    }];
    
    //全屏按钮
    _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _fullScreenBtn.backgroundColor = [UIColor clearColor];
    [_fullScreenBtn setImage:[UIImage imageNamed:imageFullScree] forState:UIControlStateNormal];
    [_fullScreenBtn setImage:[UIImage imageNamed:imageMiniScree] forState:UIControlStateSelected];
    _fullScreenBtn.selected = NO;
    //[_fullScreenBtn setContentEdgeInsets:UIEdgeInsetsMake(14, 19, 14, 19)];
    [_fullScreenBtn addTarget:self action:@selector(fullScreen:) forControlEvents:UIControlEventTouchUpInside];
    [_toolView addSubview:_fullScreenBtn];
    [_fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.and.bottom.equalTo(_toolView);
        make.width.mas_equalTo(50);
    }];
    
    //总时间
    _totalTime = [[UILabel alloc] init];//WithFrame:CGRectMake(CGRectGetMaxX(_progressSlider.frame), 10, 40, 20)];
    _totalTime.text = @"00:00";
    _totalTime.textColor = [UIColor whiteColor];
    _totalTime.font = [UIFont systemFontOfSize:8];
    _totalTime.textAlignment = NSTextAlignmentLeft;
    [_toolView addSubview:_totalTime];
    [_totalTime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_fullScreenBtn.mas_left).offset(-15);
        make.top.and.bottom.equalTo(_toolView);
        make.width.mas_equalTo(35);
    }];
    
    //播放进度条
    _progressSlider = [GFCacheProgressSlider initWithCahcePreogress:[UIColor grayColor] bottomColor:[UIColor whiteColor] sliderTintColor:[UIColor blueColor]];
    //_progressSlider.frame = CGRectMake(CGRectGetMaxX(_currentTime.frame),12.5,frame.size.width-CGRectGetMaxX(_currentTime.frame)-40,15);
    _progressSlider.minimumValue = 0.0;
    _progressSlider.maximumValue = 1.0;
    //进度条的监控
    [_progressSlider addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [_progressSlider addTarget:self action:@selector(touchChange:) forControlEvents:UIControlEventValueChanged];
    [_progressSlider addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    [_progressSlider setThumbImage:[UIImage imageNamed:imageProgress] forState:UIControlStateNormal];
    [_toolView addSubview:_progressSlider];
    [_progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_currentTime.mas_right).offset(10);
        make.centerY.equalTo(_toolView);
        make.height.mas_equalTo(20);
        make.right.equalTo(_totalTime.mas_left).offset(-10);
    }];
    
    
    //创建等待视图
    //等待视图
    self.waitingView = [[UIActivityIndicatorView alloc] init];
    self.waitingView.hidesWhenStopped = YES;
    self.waitingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.waitingView.color = [UIColor whiteColor];
    [self addSubview:self.waitingView];
    [self bringSubviewToFront:self.waitingView];
    [self.waitingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.and.height.mas_equalTo(50);
    }];
    
}

//播放器的单击事件<控制底部和顶部view的显示与隐藏>
- (void)tapGROne:(UITapGestureRecognizer *)tapGR{
    BOOL showOrHide = !_topView.isHidden;
    [self.delegate AVPlayerToolBarViewShowOrHideOnAVPlayerView:showOrHide];
    [UIView animateWithDuration:.5 animations:^{
        _topView.hidden = !_topView.isHidden;
        _toolView.hidden = !_toolView.isHidden;
    }];
}

//双击手势
- (void)tapGRTwo:(UITapGestureRecognizer *)tapGR{
    
    _playBtn.selected ? [self pause] : [self play];
}


//音量调节
- (MPVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView  = [[MPVolumeView alloc] init];
        _volumeView.transform = CGAffineTransformMakeRotation(M_PI*(-0.5));
        [_volumeView setShowsVolumeSlider:YES];
        [_volumeView setShowsRouteButton:NO];
        for (UIView *view in [_volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                self.volumeViewSlider = (UISlider*)view;
                //[self.volumeViewSlider setThumbImage:[UIImage getRoundImageWithColor:[UIColor whiteColor] size:CGSizeMake(10, 10)] forState:UIControlStateNormal];
                break;
            }
        }
    }
    return _volumeView;
}

//亮度调节
- (UISlider *)brightnessSlider {
    if (_brightnessSlider == nil) {
        _brightnessSlider  = [[UISlider alloc] init];
        _brightnessSlider.transform = CGAffineTransformMakeRotation(M_PI*(-0.5));
        
    }
    return _brightnessSlider;
}

//亮度调节相关
- (void)brightnessChanged:(UISlider *)slider {
    //屏幕亮度
    [[UIScreen mainScreen] setBrightness:slider.value];
}


#pragma mark - 顶部view相关事件
//返回按钮的点击事件
- (void)goBack:(UIButton *)btn
{
    //点击返回按钮
    [self.delegate AVPlayerClickBackButtonOnAVPlayerView:nil];
    
}


 //全屏按钮的点击事件
 - (void)fullScreen:(UIButton *)btn{
     
     //控制父视图让屏幕旋转
     _fullScreenBtn.selected = !_fullScreenBtn.selected;
     //并且进行重新布局
     //self.frame = GF_SCREEN_BOUNDS;
     BOOL isFullScreen = _fullScreenBtn.selected;
     [self.delegate AVPlayerClickFullScreenButtonOnAVPlayerView:isFullScreen];
}


#pragma mark - 底部view相关事件
//播放按钮的点击事件
-(void)playBtnClick:(UIButton *)btn{
    //暂停&&播放
    btn.selected ? [self pause] : [self play];
}

- (void)playBigBtnClick:(UIButton *)btn{
    //播放
    [self play];
}

//进度条滑动开始
-(void)touchDown:(UISlider *)sl
{
    [self pause];
}

//进度条滑动
-(void)touchChange:(UISlider *)sl
{
    //通过进度条控制播放进度
    if (_player) {
        CMTime dur = _player.currentItem.duration;
        float current = _progressSlider.value;
        _currentTime.text = [self getTime:(NSInteger)(current*self.duration)];
        //跳转到指定的时间
        [_player seekToTime:CMTimeMultiplyByFloat64(dur, current)];
    }
}

//进度条滑动结束
-(void)touchUp:(UISlider *)sl
{
    [self play];
}

#pragma mark - 滑动手势处理,亮度/音量/进度
/**
 开始触摸
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    self.direction = AVDirectionNone;
    
    //记录首次触摸坐标
    self.startPoint = point;
    //检测用户是触摸屏幕的左边还是右边，以此判断用户是要调节音量还是亮度，左边是亮度，右边是音量
    if (self.startPoint.x <= self.bounds.size.width/2.0) {
        //亮度
        self.startVB = [UIScreen mainScreen].brightness;
    } else {
        //音量
        self.startVB = self.volumeViewSlider.value;
    }
    CMTime ctime = _player.currentTime;
    self.startVideoRate = ctime.value /ctime.timescale/self.duration;
}

/**
 移动手指
 */
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    CGPoint panPoint = CGPointMake(point.x - self.startPoint.x, point.y - self.startPoint.y);
    if (self.direction == AVDirectionNone) {
        //分析出用户滑动的方向
        if (fabs(panPoint.x) >= 30) {
            //水平方向
            [self pause];
            self.direction = AVDirectionHrizontal;
        }
        else if (fabs(panPoint.y) >= 30) {
            //垂直方向
            self.direction = AVDirectionVertical;
        }
        else {
            return;
        }
    }
    
    if (self.direction == AVDirectionHrizontal) {
        //垂直方形
        CGFloat rate = self.startVideoRate+(panPoint.x*180/(self.bounds.size.width*self.duration));
        NSLog(@"%f",self.duration);
        if (rate > 1) {
            rate = 1;
        }
        else if (rate < 0) {
            rate = 0;
        }
        _progressSlider.value = rate;
        CMTime dur = _player.currentItem.duration;
        _currentTime.text = [self getTime:(NSInteger)(rate*self.duration)];
        [_player seekToTime:CMTimeMultiplyByFloat64(dur, rate)];
        
    }else if (self.direction == AVDirectionVertical) {
        //垂直方向
        CGFloat value = self.startVB-(panPoint.y/self.bounds.size.height);
        if (value > 1) {
            value = 1;
        }
        else if (value < 0) {
            value = 0;
        }
        if (self.startPoint.x <= self.frame.size.width/2.0) {//亮度
            self.brightnessSlider.hidden = NO;
            self.brightnessSlider.value = value;
            [[UIScreen mainScreen] setBrightness:value];
        }else {//音量
            self.volumeView.hidden = NO;
            [self.volumeViewSlider setValue:value];
        }
    }
}

/**
 结束触摸
 */
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.direction == AVDirectionHrizontal) {
        [self play];
    }
    else if (self.direction == AVDirectionVertical) {
        self.volumeView.hidden = YES;
        self.brightnessSlider.hidden = YES;
    }
}

/**
 取消触摸
 */
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    if (self.direction == AVDirectionHrizontal) {
        [self play];
    }
    else if (self.direction == AVDirectionVertical) {
        self.volumeView.hidden = YES;
        self.brightnessSlider.hidden = YES;
    }
}



#pragma mark - 换算时长
//将秒数换算成具体时长
- (NSString *)getTime:(NSInteger)second
{
    NSString *time;
    if (second < 60) {
        time = [NSString stringWithFormat:@"00:%02ld",(long)second];
    }
    else {
        if (second < 3600) {
            time = [NSString stringWithFormat:@"%02ld:%02ld",second/60,second%60];
        }
        else {
            time = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",second/3600,(second-second/3600*3600)/60,second%60];
        }
    }
    return time;
}

#pragma mark - 播放器销毁  记得移除相关Item
- (void)dealloc
{
    NSLog(@"playerView释放了,无内存泄漏");
    //移除注册的观察者
    [_player removeTimeObserver:_playTimeObserver];
    [_player.currentItem removeObserver:self forKeyPath:@"status"];
    [_player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    //playbackBufferEmpty  playbackLikelyToKeepUp
    [_player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_player.currentItem removeObserver:self forKeyPath:@"playbackBufferFull"];
    [_player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    //播放状态
    [_player removeObserver:self forKeyPath:@"timeControlStatus"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
