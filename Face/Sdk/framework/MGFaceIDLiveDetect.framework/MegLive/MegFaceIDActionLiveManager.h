//
//  MegFaceIDActionLiveManager.h
//  MegLive
//
//  Created by MegviiDev on 2017/8/17.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MegFaceIDActionLiveManager_hpp
#define MegFaceIDActionLiveManager_hpp

#include <stdio.h>
#include "MegFaceIDActionLiveConfig.h"
#include "MGFaceIDQualityConfig.h"
#include "MegFaceIDConfig.h"
#include "MegFaceIDActionLiveActionManager.h"
#include "MegFaceIDSelectedImageItem.h"
#include "json.hpp"

namespace MegFaceIDActionLive {
    class FaceIDActionLiveManager {
        void *actionlive_worker;
    public:
        FaceIDActionLiveManagerStep _current_step;
        MGFaceIDQualityErrorType _quality_error_type;
        MegFaceIDActionLiveActionFailedType _failed_type;
        ~FaceIDActionLiveManager();
        FaceIDActionLiveManager(std::string biz_token,
                                FaceIDActionLiveActionManager action_manager);

        bool load_model_data(const void *face_data, const void *face_landmark_data,
                             const void *attr_data, int attr_len);

        void start_action_live_detect();

        void stop_action_live_detect();

        void reset_detect();

        void setEnableWhiteBalance(bool isEnable);

        void reset_action_queue(std::vector<MegFaceIDActionLiveActionType> action_list);

        void action_live_detect_image(const void *face_image, MegFaceIDImageType image_type,
                                      int image_width, int image_height);

        unsigned int get_current_action_index();

        MegFaceIDActionLiveActionType get_selected_action();

        float get_detect_time();

        unsigned int get_action_count();

        unsigned int get_action_timeout();

        MegFaceIDSelectedImageItem get_image_best();

        MegFaceIDSelectedImageItem get_mirror_image_best();

        std::vector<MegFaceIDSelectedImageItem> get_image_data(bool is_success);
        megviinlohmann::json get_log();
        void setConfig(float face_max_offset_scale, float face_eye_occlusion,
                       float face_mouth_occlusion, float face_yaw, float face_pitch,
                       float face_max_brightness,
                       float face_min_brightness, float face_min_size_ratio,
                       float face_max_size_ratio,
                       float face_motion_blur,
                       float face_gaussian_blur, float face_center_rectX, float face_center_rectY,
                       int need_holding, int min_face, bool check_multiface, float check_multiface_width);

        void setActionConfig(bool other_action, bool incontinuous_image, bool no_face_sometimes,
                             bool action_too_fast, bool mask, bool face_lost,
                             bool no_face_found, bool face_occlusion);

    private:
        bool _is_start_detect;
        void default_setting();
        unsigned char* create_bgr_image(const void *face_image, MegFaceIDImageType image_type, int image_width,
                         int image_height);

        void detect_face_lookmirror(const void *face_image, MegFaceIDImageType image_type,
                                    int image_width, int image_height);

        void
        start_face_action(const void *face_image, MegFaceIDImageType image_type, int image_width,
                          int image_height);

        void
        detect_face_action(const void *face_image, MegFaceIDImageType image_type, int image_width,
                           int image_height);
    };
};

#endif /* MegFaceIDActionLiveManager_hpp */
