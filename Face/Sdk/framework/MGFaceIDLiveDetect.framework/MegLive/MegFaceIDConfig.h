//
//  MegFaceIDConfig.h
//  MegLive
//
//  Created by MegviiDev on 2017/8/29.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MegFaceIDConfig_h
#define MegFaceIDConfig_h

typedef enum MegFaceIDImageType {
    MegFaceIDImageTypeBGR,
    MegFaceIDImageTypeGRAY,
    MegFaceIDImageTypeYUVNV21,
    MegFaceIDImageTypeRGB,
    MegFaceIDImageTypeRGBA,
    MegFaceIDImageTypeBGRA,
} MegFaceIDImageType;

typedef enum MegFaceIDDetectType {
    MegFaceIDDetectTypeSlienceLive   = 1,            //  静默活体
    MegFaceIDDetectTypeActionLive    = 2,            //  动作活体
    MegFaceIDDetectTypeFlashLive     = 3,            //  炫彩活体
    MegFaceIDDetectTypeDoubleRecordLive     = 4,            //  双录活体
} MegFaceIDDetectType;

#endif /* MegFaceIDConfig_h */
