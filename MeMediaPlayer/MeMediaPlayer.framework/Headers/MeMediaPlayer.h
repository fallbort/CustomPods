#ifndef __ME_MEDIA_PLAYER_H__
#define __ME_MEDIA_PLAYER_H__

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "MeMediaPlayerDef.h"
#import "MeMediaPlayerDelegate.h"
#import "MeMediaVodPlayer.h"
#import "MeMediaLivePlayer.h"

//=============================================================================
@interface MeMediaPlayer : NSObject
/**
 @brief  获得播放器版本
 @return 播放器版本
 */
+ (NSString*) getVersion;

/**
 @brief  初始化媒体播放器, app启动时调用
 @param  deviceId 设备ID
 @param  deviceMode 设备型号
 @param  systemVer 操作系统版本
 @param  appVer app版本
 @param  userId 用户ID
 @param  json json格式的播放器配置
 */
+ (void) initMediaPlayer:(NSString*) deviceId
              deviceMode: (NSString*) deviceMode
           systemVersion: (NSString*) systemVer
              appVersion: (NSString*) appVer
                  userId: (int64_t) userId
                  config: (NSString*) json;

/**
 @brief  清理媒体播放器，app退出时调用
 */
+ (void) cleanMediaPlayer;

/**
 @brief  设置网络类型，网络类型变化时调用
 @param  type 网络类型
 */
+ (void) setNetworkType: (MeMediaPlayerNetworkType)type;

/**
 @brief  设置app channel，用以区分不同的包
 @param  channel channel
 */
+ (void) setAppChannel: (int)channel;

/**
 @brief  设置国家代码
 @param  country 国家代码
 */
+ (void) setCountryRegionCode: (NSString*)country;

/**
 @brief  设置app在后台，当app进入后台时调用
 */
+ (void) setAppInBackground;

/**
 @brief  设置app在前台，当app进入前台时调用
 */
+ (void) setAppInForeground;
@end


#endif //__ME_MEDIA_PLAYER_H__
