//
//  GFAVPlayerItem.m
//  GFAPP
//
//  Created by XinKun on 2017/12/5.
//  Copyright © 2017年 North_feng. All rights reserved.
//

#import "GFAVPlayerItem.h"

@implementation GFAVPlayerItem

//实现kvo自动释放
- (void)dealloc {
    if (self.observer) {
        [self removeObserver:self.observer forKeyPath:@"status"];
        [self removeObserver:self.observer forKeyPath:@"loadedTimeRanges"];
    }
}

@end
