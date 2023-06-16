//
//  MegFaceIDActionLiveActionManager.h
//  MegLive
//
//  Created by MegviiDev on 2017/8/17.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MegFaceIDActionLiveActionManager_hpp
#define MegFaceIDActionLiveActionManager_hpp

#include <stdio.h>
#include <vector>
#include "MegFaceIDActionLiveConfig.h"

namespace MegFaceIDActionLive {
    class FaceIDActionLiveActionManager {
    public:
        ~FaceIDActionLiveActionManager(){};
        FaceIDActionLiveActionManager();
        FaceIDActionLiveActionManager(bool is_random_action, unsigned int action_timeout, unsigned int action_count, std::vector<MegFaceIDActionLiveActionType>action_list);
        unsigned int get_action_timeout();
        unsigned int get_action_count();
        MegFaceIDActionLiveActionType random_action_type();
        void reset_action();
        void setIsRandomAction(bool isRandom);
        void reset_action_queue(std::vector<MegFaceIDActionLiveActionType> action_list);
    private:
        unsigned int _action_count;
        unsigned int _action_timeout;
        bool _is_random_action;
        std::vector<MegFaceIDActionLiveActionType> _real_action_list;
        std::vector<MegFaceIDActionLiveActionType> _specified_action_list;
    };
};

#endif /* MegFaceIDActionLiveActionManager_hpp */
