//
//  GFCacheProgressSlider.h
//  AudioAndVideo
//
//  Created by XinKun on 2017/12/4.
//  Copyright © 2017年 North_feng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GFCacheProgressSlider : UISlider

+ (instancetype)initWithCahcePreogress:(UIColor *)progressTintColor bottomColor:(UIColor *)bottomColor sliderTintColor:(UIColor *)sliderTintColor;


///设置缓存进度
- (void)setCacheProgressValue:(float)value;

///设置缓存进度条归零
- (void)setCacheProgressReturnToZero;


@end
