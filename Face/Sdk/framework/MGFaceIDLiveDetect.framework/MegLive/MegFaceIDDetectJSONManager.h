//
//  MegFaceIDDetectJSONManager.h
//  MegLive
//
//  Created by MegviiDev on 2017/9/5.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MegFaceIDDetectJSONManager_h
#define MegFaceIDDetectJSONManager_h
#include <stdio.h>
#include <string>
#include <vector>
#include "MegFaceIDSelectedImageItem.h"
#include "MGFaceIDQualityFrameRectItem.h"
#include "json.hpp"

class MegFaceIDDetectJSONManager {
public:
    ~MegFaceIDDetectJSONManager(){};
    MegFaceIDDetectJSONManager(){};
    std::string getMegLiveDelta(std::string userinfo, std::vector<MegFaceIDSelectedImageItem> imageData, megviinlohmann::json cLogInfo, std::string sdkLogInfo, const char* videoData, long videoLength, const char* whiteBalanceVideo, long wbVideoLength, std::string fingerData);
    std::string getMegLiveDelta(std::string userinfo, std::vector<MegFaceIDSelectedImageItem> imageData, megviinlohmann::json cLogInfo, std::string sdkLogInfo, const char* videoData, long videoLength, std::string fingerData);
    std::string getMegLiveDelta(std::string userinfo, std::vector<MegFaceIDSelectedImageItem> imageData, megviinlohmann::json cLogInfo, std::string sdkLogInfo, std::string fingerData);
};

#endif /* MegFaceIDDetectJSONManager_h */
