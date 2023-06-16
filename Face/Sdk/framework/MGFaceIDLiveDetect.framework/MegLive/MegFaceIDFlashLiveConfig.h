//
//  MegFaceIDFlashLiveConfig.h
//  MegLive
//
//  Created by MegviiDev on 2017/8/18.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MegFaceIDFlashLiveConfig_h
#define MegFaceIDFlashLiveConfig_h

typedef enum : int {
    MegFaceIDFlashStepLookMirror,
    MegFaceIDFlashStepLightEV,
    MegFaceIDFlashStepHalfwaying,
    MegFaceIDFlashStepTooBright,
    MegFaceIDFlashStepAnimation,
    MegFaceIDFlashStepFlashing,
    MegFaceIDFlashStepFinish,
    MegFaceIDFlashStepWhiteBalance,
} MegFaceIDFlashStep;

typedef enum : int {
    MegFaceIDFlashLiveFailedTypeNone,
    MegFaceIDFlashLiveFailedTypeTimeout,
    MegFaceIDFlashLiveFailedTypeScoreLow,
} MegFaceIDFlashLiveFailedType;

#endif /* MegFaceIDFlashLiveConfig_h */
