//
//  NEPayTypeDef.h
//  NEPayKit
//
//  Created by FengMengtao on 2018/7/31.
//  Copyright © 2018年 meme. All rights reserved.
//

#ifndef NEPayTypeDef_h
#define NEPayTypeDef_h

typedef NS_ENUM(NSInteger, NEPayChannel) {
    NEPayChannel_AppleIAP = 0,
};


static NSString * const NEPayChannelKeyString[] = {
    [NEPayChannel_AppleIAP] = @"appleiap",
};

#ifndef NEPayKitDLog
#ifdef DEBUG
#define NEPayKitDLog(...) NSLog(__VA_ARGS__)
#else
#define NEPayKitDLog(...) /* */
#endif // DEBUG
#endif // DLog

#import "NEPayOrderItem.h"
#import "NEPayResponse.h"

#endif /* NEPayTypeDef_h */
