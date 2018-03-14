//
//  GFCacheProgressSlider.m
//  AudioAndVideo
//
//  Created by XinKun on 2017/12/4.
//  Copyright © 2017年 North_feng. All rights reserved.
//

#import "GFCacheProgressSlider.h"
#import "Masonry.h"

@implementation GFCacheProgressSlider
{

    UIProgressView *_progressView;
    
}


+ (instancetype)initWithCahcePreogress:(UIColor *)cacheColor bottomColor:(UIColor *)bottomColor sliderTintColor:(UIColor *)sliderColor{
    
    GFCacheProgressSlider *slider = [[GFCacheProgressSlider alloc] init];
    slider.maximumTrackTintColor = [UIColor clearColor];
    slider.minimumTrackTintColor = sliderColor;
    [slider createCacheProgress:cacheColor bottomColor:bottomColor];
    return slider;
}


///创建缓存条
- (void)createCacheProgress:(UIColor *)progressColor bottomColor:(UIColor *)bottomColor{
    
    _progressView = [[UIProgressView alloc] init];//WithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    _progressView.progressViewStyle = UIProgressViewStyleDefault;
    _progressView.progressTintColor = progressColor;
    _progressView.trackTintColor = bottomColor;
    _progressView.progress = 0.0;
    [self addSubview:_progressView];
    [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(2);
        make.right.equalTo(self).offset(-2);
        make.centerY.equalTo(self).offset(1.);
        make.height.mas_equalTo(1.5);
    }];
    
}

///设置缓存进度
- (void)setCacheProgressValue:(float)value{
    
    _progressView.progress = value;
    if (value >= _progressView.progress) {
        return ;
    }
}

///设置缓存进度条归零
- (void)setCacheProgressReturnToZero{
    _progressView.progress = 0.;
}







@end
