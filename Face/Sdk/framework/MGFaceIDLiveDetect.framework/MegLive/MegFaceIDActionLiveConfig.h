//
//  MegFaceIDActionLiveConfig.h
//  MegLive
//
//  Created by MegviiDev on 2017/8/17.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MegFaceIDActionLiveConfig_h
#define MegFaceIDActionLiveConfig_h

typedef enum : int {
    FaceIDActionLiveManagerStepLookMirror,
    FaceIDActionLiveManagerStepAction,
    FaceIDActionLiveManagerStepFinish,
    FaceIDActionLiveManagerStepWhiteBalance,
} FaceIDActionLiveManagerStep;

//  动作类型
typedef enum : int {
    FaceIDActionLiveTYPENONE              = 0,       //  初始状态
    FaceIDActionLiveTYPEBLINK,                       //  眨眼
    FaceIDActionLiveTYPEMOUTH,                       //  张嘴
    FaceIDActionLiveTYPEPOS_YAW,                     //  左右转头
    FaceIDActionLiveTYPEPOS_PITCH,                   //  上下点头
    FaceIDActionLiveTYPEPOS_YAW_LEFT,                //  向左转头
    FaceIDActionLiveTYPEPOS_YAW_RIGHT,               //  向右转头
    FaceIDActionLiveTYPEPOS_PITCH_UP,                //  向上抬头
    FaceIDActionLiveTYPEPOS_PITCH_DOWN,              //  向下抬头
    FaceIDActionLiveTYPEDONE,                        //  结束状态
    FaceIDActionLiveTYPEAIMLESS           = -1,      //  持续检测
} MegFaceIDActionLiveActionType;

//  动作检测失败原因
typedef enum : int {
    FaceIDActionLiveFAILEDTYPENONE,
    FaceIDActionLiveFAILEDTYPEACTIONBLEND,
    FaceIDActionLiveFAILEDTYPENOTVIDEO,
    FaceIDActionLiveFAILEDTYPETIMEOUT,
    FaceIDActionLiveFAILEDTYPEFACENONTFOUND,
    FaceIDActionLiveFAILEDTYPEFACELOSTNOTCONTINUOUS,
    FaceIDActionLiveFAILEDTYPETOOMANYFACELOST,
    FaceIDActionLiveFAILEDTYPEFACENOTCONTINUOUS,
    FaceIDActionLiveFAILEDTYPEFACEOCCLUSION,
    FaceIDActionLiveFAILEDTYPEMASK,
    FaceIDActionLiveFAILEDTYPEAIMLESS,
} MegFaceIDActionLiveActionFailedType;

#endif /* MegFaceIDActionLiveConfig_h */
