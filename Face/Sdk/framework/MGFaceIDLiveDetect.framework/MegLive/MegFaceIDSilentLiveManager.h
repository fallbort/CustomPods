//
//  MegFaceIDSilentLiveManager.h
//  MegLive
//
//  Created by MegviiDev on 2017/8/16.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MegFaceIDSilentLiveManager_hpp
#define MegFaceIDSilentLiveManager_hpp

#include <stdio.h>
#include <sys/time.h>
#include "MegFaceIDSilentLiveConfig.h"
#include "MGFaceIDQualityConfig.h"
#include "MegFaceIDConfig.h"
#include "MegFaceIDSelectedImageItem.h"
#include "json.hpp"
#include "MG_Common.h"

namespace MegFaceIDSilentLive {
    class FaceIDSilentLiveManager {
        void* silent_worker;
    public:
        MegFaceIDSilentStep current_step;
        MGFaceIDQualityErrorType quality_error_type;
        MegFaceIDSilentLiveFailedType failedType;
        float progress;
        std::string failedValue;

        ~FaceIDSilentLiveManager();
        FaceIDSilentLiveManager(std::string biz_token, int time_out,long keeping_time);
        bool load_model_data(const void* face_data, const void* face_landmark_data, const void* attr_data, int attr_len);
        void start_silent_live_detect();
        void stop_silent_live_detect();
        void reset_detect();
        void setEnableWhiteBalance(bool isEnable);
        void detect_face(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height);
        std::vector<MG_POINT> getDetectedLandmark();

        std::vector<MegFaceIDSelectedImageItem> get_image_data(bool is_success);
        std::vector<MegFaceIDSelectedImageItem> get_image_dataT(bool is_success);
        megviinlohmann::json get_log();
        MegFaceIDSelectedImageItem get_image_best();
        void setConfig(float face_max_offset_scale, float face_eye_occlusion,
                       float face_mouth_occlusion, float face_yaw, float face_pitch,
                       float face_max_brightness,
                       float face_min_brightness, float face_min_size_ratio, float face_max_size_ratio,
                       float face_motion_blur,
                       float face_gaussian_blur, float face_center_rectX, float face_center_rectY,
                       int need_holding, int min_face, bool check_multiface, float check_multiface_width);
        void set_badimage_failevent(int leak_frame, std::vector<MGFaceIDQualityErrorType> fail_types);
        MegFaceIDSelectedImageItem get_image_bad();
    private:
        struct timeval _start_timestamp;
        bool _is_live;
        bool _is_start_detect;
        int _current_detect_frame;
        int _time_out;
        long _start_keepingtimestamp;
        long _total_keepingtimestamp; //ms
        float timeout_progress;
        void default_setting();
        void detect_face_lookmirror(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height);
        void detect_face_keeping(const void* face_image,MegFaceIDImageType image_type, int image_width, int image_height);
        long getSystemTime();
    };
};

#endif /* MegFaceIDSilentLiveManager_hpp */
