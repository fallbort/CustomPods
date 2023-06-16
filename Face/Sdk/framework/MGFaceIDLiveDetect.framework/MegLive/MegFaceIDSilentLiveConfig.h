//
//  MegFaceIDSilentLiveConfig.h
//  MegLive
//
//  Created by MegviiDev on 2017/8/16.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MegFaceIDSilentLiveConfig_h
#define MegFaceIDSilentLiveConfig_h

typedef enum : int {
    MegFaceIDSilentStepLookMirror,
    MegFaceIDSilentStepKeeping,
    MegFaceIDSilentStepFinish,
    MegFaceIDSilentStepWhiteBalance,
} MegFaceIDSilentStep;

typedef enum : int {
    MegFaceIDSilentLiveFailedTypeNone,
    MegFaceIDSilentLiveFailedTypeTimeout,
    MegFaceIDSilentLiveFailedTypeScoreLow,
} MegFaceIDSilentLiveFailedType;

#endif /* MegFaceIDSilentLiveConfig_h */
