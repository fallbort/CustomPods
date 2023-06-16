//
//  MegFaceIDDetectLogManager.h
//  MegLive
//
//  Created by MegviiDev on 2017/9/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MegFaceIDDetectLogManager_h
#define MegFaceIDDetectLogManager_h

#include <stdio.h>
#include <string>
#include <ctime>
#include <cstring>
#include <vector>
#include <chrono>
#include "MegFaceIDConfig.h"
#include "MGFaceIDQualityConfig.h"
#include "MegFaceIDSilentLiveConfig.h"
#include "MegFaceIDFlashLiveConfig.h"
#include "MegFaceIDActionLiveConfig.h"
#include "MegFaceIDFlashLiveConfig.h"
#include "json.hpp"

typedef enum : int {
    LivenessDetailStatusPass,
    LivenessDetailStatusFailed,
    LivenessDetailStatusCancel,
} LivenessDetailStatus;

class MegFaceIDDetectLogManager {
    MegFaceIDDetectType _detect_type;
    std::string _biz_token;
    bool _final_result;
    int _start_timestamp;
    std::chrono::steady_clock::time_point _start_tp;
    std::string _last_action;
    std::vector<megviinlohmann::json> _actions;
    megviinlohmann::json _liveness_detail;
    megviinlohmann::json _feedback_data;
    int _kp_count, _nff_count, _tl_count, _ts_count, _ua_count, _tb_count, _td_count, _tbr_count;
    void add_actions(std::string action_name);
    void add_actions_failed(std::string action_name, std::string failed_reason);
    void add_result(LivenessDetailStatus status, std::string failed_reason);
    
public:
    ~MegFaceIDDetectLogManager(){};
    MegFaceIDDetectLogManager(std::string biz_token, MegFaceIDDetectType detect_type);
    void add_look_mirror_state(MGFaceIDQualityErrorType error_rype);
    //  Silent live detect
    void add_silent_live_detect_step(MegFaceIDSilentStep live_step, MegFaceIDSilentLiveFailedType failed_type);
    //  Flash live detect
    void add_flash_live_detect_step(MegFaceIDFlashStep live_step, MegFaceIDFlashLiveFailedType failed_type);
    //  Action live detect
    void add_action_live_detect_step(FaceIDActionLiveManagerStep live_step, MegFaceIDActionLiveActionType action_type, MegFaceIDActionLiveActionFailedType failed_type);
    void set_flash_feedback(const unsigned char* feedback, int feedback_len);
    megviinlohmann::json serialize() const;
};

#endif /* MegFaceIDDetectLogManager_h */
