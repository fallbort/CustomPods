//
//  MegFaceIDFlashLiveManager.h
//  MegLive
//
//  Created by LiangJuzi on 2019/4/1.
//  Copyright © 2019 megvii. All rights reserved.
//

#ifndef MegFaceIDFlashLiveManager_h
#define MegFaceIDFlashLiveManager_h

#include <stdio.h>
#include <sys/time.h>
#include "MegFaceIDFlashLiveConfig.h"
#include "MGFaceIDQualityConfig.h"
#include "MegFaceIDConfig.h"
#include "MegFaceIDSelectedImageItem.h"
#include "json.hpp"
#include "MG_Common.h"

struct MegviiFlashColorFrameItem {
    long flashColorLength;
    long flashFrameCount;
    long flashLackFrameCount = 0;
    float lightDetectionThreshold;
    float evThresholdHigh;
    float evThresholdLow;
    std::string flashSequence;
    std::string lightDetectionColors;
    int isCheckEv;
    long flashDetectIndex;
};

namespace MegFaceIDFlashLive {
    class FaceIDFlashLiveManager {
        void* flash_worker;
    public:
        MegFaceIDFlashStep _current_step;
        MGFaceIDQualityErrorType _quality_error_type;
        MegFaceIDFlashLiveFailedType _failedType;
        float _progress;
        float _light_pass_ev;
        float _image_pass_light;
        double max_flash_score;
        double min_flash_score;
        std::vector<double> bgr_flash;

        ~FaceIDFlashLiveManager();
        FaceIDFlashLiveManager(std::string biz_token, int time_out, MegviiFlashColorFrameItem flash_item);
        bool load_model_data(const void* face_data, const void* face_landmark_data, const void* attr_data, int attr_len);
        void start_flash_live_detect();
        void stop_flash_live_detect();
        void reset_detect();
        void setEnableWhiteBalance(bool isEnable);
        void detect_face(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height, bool is_flash, float detect_face, bool is_halfway);
        void detect_face(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height, bool is_flash);
        void detect_face(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height, bool is_flash, float ISO, float shutter_time, float aperture, bool is_halfway);
        std::vector<MegFaceIDSelectedImageItem> get_image_data(bool is_success);
        std::vector<MegFaceIDSelectedImageItem> get_image_data_novideo(bool is_success);
        megviinlohmann::json get_log();
        MegFaceIDSelectedImageItem get_image_best();
        void setConfig(float face_max_offset_scale, float face_eye_occlusion,
                       float face_mouth_occlusion, float face_yaw, float face_pitch,
                       float face_max_brightness,
                       float face_min_brightness, float face_min_size_ratio, float face_max_size_ratio,
                       float face_motion_blur,
                       float face_gaussian_blur, float face_center_rectX, float face_center_rectY, int need_holding, int min_face, bool check_multiface, float check_multiface_width);
        void set_badimage_failevent(int leak_frame, std::vector<MGFaceIDQualityErrorType> fail_types);
        MegFaceIDSelectedImageItem get_image_bad();
    private:
//        struct timeval _start_timestamp;
        bool _is_start_detect;
        bool isEnabledWhiteBalance = false;
//        int _current_detect_frame;
//        int _time_out;
        long _get_lightEV_Number;
//        bool _is_lightEV;
        long _start_halfway_frame;
        long _start_animation_frame;
        long _start_flash_frame;
        long _total_flash_frame;
        long _real_current_frame;
        long _real_total_flash_frame; // contains the throw frames
        float _timeout_progress;
        std::vector<double> _flash_value;
        MegviiFlashColorFrameItem _flash_item;
        std::vector<double> _bgr_means;

        long _start_toobright_frame;
        long _start_lookmirror_frame;

        void default_setting();
        void detect_face_lookmirror(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height);
        void detect_face_lightEV(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height, float detect_face);
        void detect_face_halfway(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height, bool is_selected_frame);
        void detect_face_animation(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height);
        void detect_face_flash(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height, bool is_flash);
        void flash_color_mean(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height);
        void detect_face_toobright(const void* face_image, MegFaceIDImageType image_type, int image_width, int image_height);
        std::vector<std::vector<double>> getDetectedLandmark();
        long getSystemTime();
    };
};

#endif /* MegFaceIDFlashLiveManager_h */
