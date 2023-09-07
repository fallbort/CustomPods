#ifndef __ME_MEDIA_VOD_PLAYER_H__
#define __ME_MEDIA_VOD_PLAYER_H__

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>

//=============================================================================
@interface MeMediaVodPlayer : NSObject
- (instancetype)initWithUrl:(NSString *)url
             ignoreCategory:(BOOL)ignoreCategory;
- (instancetype)initWithFile:(NSString *)file
              ignoreCategory: (BOOL)ignoreCategory;

/**
 @brief  播放预处理
 @return 成功-YES 失败-NO
 */
- (BOOL)prepare;

/**
 @brief  开始播放
 @return 成功-YES 失败-NO
 */
- (BOOL)play;
- (BOOL)playByPosition: (NSTimeInterval)position;

/**
 @brief  暂停播放
 @return 成功-YES 失败-NO
 */
- (BOOL)pause;

/**
 @brief  恢复播放
 @return 成功-YES 失败-NO
 */
- (BOOL)resume;

/**
 @brief  seek到指定播放位置
 @param  postion 要seek到的播放位置，单位:秒
 @return 成功-YES 失败-NO
 */
- (BOOL)seek:(NSTimeInterval)postion;

/**
 @brief  停止播放
 @return 成功-YES 失败-NO
 */
- (BOOL)stop;

/**
 @brief  关闭播放器
 @return 成功-YES 失败-NO
 */
- (BOOL)shutdown;

/**
 @brief  是否在播放中
 @return 成功-YES 失败-NO
 */
- (BOOL)isPlaying;

/**
 @brief  设置是否循环播放
 @param  loop YES-循环播放 NO-非循环播放
 @return 成功-YES 失败-NO
 */
- (BOOL)setLooping: (BOOL)loop;

/**
 @brief  获得当前播放位置
 @return 当前播放位置，单位:秒
 */
- (NSTimeInterval)getCurrentPostion;

/**
 @brief  获得文件播放时长
 @return 文件播放时长，单位:秒
 */
- (NSTimeInterval)getDuration;

/**
 @brief  设置音量
 @param  volume 音量，范围[0-1.0]
 */
- (void)setVolume:(float)volume;

/**
 @brief  获得当前音量
 @return 获得当前音量，范围[0-1.0]
 */
- (float)getVolume;

/**
 @brief  设置播放速度
 @param  speed 播放速度，范围[0.5-2.0]
 */
- (void)setPlaySpeed:(float)speed;

/**
 @brief  获得当前播放速度
 @return 当前播放速度，范围[0.5-2.0]
 */
- (float)getPlaySpeed;

/**
 @brief  获得当前下载速度
 @return 当前下载速度，单位(Byte)
 */
- (int64_t)getDownloadSpeed;

/**
 @brief  获得当前播放器状态
 @return 当前播放器状态
 */
- (MeMediaPlayerState)getPlayerState;

/**
 @brief  设置播放器代理
 @param  delegate 播放器代理，用于回调播放器信息和错误等
 */
- (void)setMediaPlayerDelegate:(id<MeMediaPlayerDelegate>)delegate;

/**
 @brief  设置播放器状态代理
 @param  delegate 播放器状态代理，用于回调播放器状态
 */
- (void)setMediaPlayerStateDelegate:(id<MeMediaPlayerStateDelegate>)delegate;

/**
 @brief  设置播放器View
 @param  display 播放器视频展示的view
 */
- (void)setDisplayView:(UIView *)display;

/**
 @brief  设置播放器显示缩放模式
 @param  mode 显示缩放模式
 */
- (void)setDisplayScalingMode:(MeMediaPlayerDisplayScaleMode)mode;
- (void)setScaleWithWidthScale:(CGFloat)widthScale heightScale:(CGFloat)heightScale;

/**
 @brief  设置进入后台时是否暂停播放
 @param  pause YES-暂停播放 NO-不暂停播放
 */
- (void)setPauseInBackground:(BOOL)pause;
@end

#endif //__ME_MEDIA_VOD_PLAYER_H__
