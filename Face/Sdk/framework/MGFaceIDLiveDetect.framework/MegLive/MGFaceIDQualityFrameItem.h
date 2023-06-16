//
//  MGFaceIDQualityFrameItem.h
//  MegLookMirror
//
//  Created by MegviiDev on 2017/8/15.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MGFaceIDQualityFrameItem_hpp
#define MGFaceIDQualityFrameItem_hpp

#include <stdio.h>
#include <cstddef>
#include <cstdint>
#include "liveness.h"
#include "MGFaceIDQualityFrameRectItem.h"

class FaceIDQualityFrameItem {
public:
    ///  综合图片质量
    float face_quality;
    ///  是否包含人脸
    bool has_face;
    ///  人脸有效面积比
    float integrity;
    ///  图片亮度
    float brightness;
    ///  人脸位置
    MGFaceIDQualityFrameRect face_rect;
    ///  眼镜判定
    float is_glasses;
    ///  遮挡判断
    float occlusion_eye_left;
    float occlusion_eye_right;
    float occlusion_mouth;
    ///  睁闭程度
    float hw_ratio_eye_left;
    float hw_ratio_eye_right;
    float hw_ratio_mouth;
    ///  左右旋转角度
    float face_yaw;
    ///  上下旋转角度
    float face_pitch;
    ///  运动模糊程度
    float blurness_motion;
    ///  高斯模糊程度
    float blurness_gaussian;
    ~FaceIDQualityFrameItem(){};
    FaceIDQualityFrameItem();
    FaceIDQualityFrameItem(bool is_face, liveness::FaceAttr face_attr, liveness::Image gray_iamge);
};

#endif /* MGFaceIDQualityFrameItem_hpp */
