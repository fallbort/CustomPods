//
//  MGFaceIDQualityConfig.h
//  MegLookMirror
//
//  Created by MegviiDev on 2017/8/15.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MGFaceIDQualityConfig_h
#define MGFaceIDQualityConfig_h

struct MGFaceIDQualityThreshold {
    float face_max_offset_scale = 0.2f;
    float face_eye_occlusion = 0.8f;
    float face_mouth_occlusion = 0.8f;
    float face_glasses = 0.5f;
    float face_yaw = 0.25f;
    float face_pitch = 0.25;
    float face_max_brightness = 220;
    float face_min_brightness = 40;
    float face_min_size_ratio = 0.28f;
    float face_max_size_ratio = 0.80f;
    float face_motion_blur = 0.30f;
    float face_gaussian_blur = 0.25f;
    float face_integrity = 0.99f;
    float face_center_rectX = 0.5f;
    float face_center_rectY = 0.5f;
    int need_holding = 2;
};

typedef enum MGFaceIDQualityErrorType {
    MGFaceIDLookMirrorQualityErrorNone = 0,                         //没有错误
    MGFaceIDLookMirrorQualityErrorFaceNotFound,                     //没有人脸
    MGFaceIDLookMirrorQualityErrorFacePosDeviated,                  //pitch角度过大
    MGFaceIDLookMirrorQualityErrorFaceYawDeviated,                  //yaw角度过大
    MGFaceIDLookMirrorQualityErrorFaceNonIntegrity,                 //人脸的有效面积比过小
    MGFaceIDLookMirrorQualityErrorFaceTooDark,                      //人脸亮度过小
    MGFaceIDLookMirrorQualityErrorFaceTooBright,                    //人脸亮度过大
    MGFaceIDLookMirrorQualityErrorFaceTooSmall,                     //人脸宽度过小
    MGFaceIDLookMirrorQualityErrorFaceTooLarge,                     //人脸宽度过大
    MGFaceIDLookMirrorQualityErrorFaceTooBlurry,                    //模糊度过大
    MGFaceIDLookMirrorQualityErrorFaceOutOfRect,                    //人脸偏离圆心
    MGFaceIDLookMirrorQualityErrorOcclusionEye,                     //遮挡眼睛
    MGFaceIDLookMirrorQualityErrorOcclusionMouth,                   //遮挡嘴巴
    MGFaceIDLookMirrorQualityErrorKeeping,                 //需要连续一定帧数合格
    MGFaceIDLookMirrorQualityErrorPhoneNotVertical,                 //设备没有垂直
    MGFaceIDLookMirrorQualityErrorMultiFace,                 //多人脸检测
} MGFaceIDQualityErrorType;

#endif /* MGFaceIDQualityConfig_h */
