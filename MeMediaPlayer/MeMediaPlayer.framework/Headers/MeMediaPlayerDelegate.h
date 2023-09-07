#ifndef __ME_MEDIA_PLAYER_DELEGATE_H__
#define __ME_MEDIA_PLAYER_DELEGATE_H__

#import "MeMediaPlayerDef.h"

//=============================================================================
// media player delegate
@protocol MeMediaPlayerDelegate <NSObject>
/**
 @消息回调通知，用于分发底层播放器的一些消息给应用层
 @param player 播放器
 @param info 消息定义
 */
- (void)notifyMediaPlayerInfo:(id)player info:(MeMediaPlayerInfoType)info;

/**
 错误回调通知，用于分发底层播放器的一些错误消息给应用层
 @param player 播放器
 @param error 错误码
 */
- (void)notifyMediaPlayerError:(id)player error:(MeMediaPlayerErrorType)error;
@end

//=============================================================================
// media player state delegate
@protocol MeMediaPlayerStateDelegate <NSObject>
/**
 错误回调通知，用于分发底层播放器的一些错误消息给应用层
 @param player 播放器
 @param state 状态码
 */
- (void)notifyMediaPlayerState:(id)player state: (MeMediaPlayerState)state;
@end

//=============================================================================
// media player state delegate
@protocol MeMediaPlayerSeiDelegate <NSObject>
- (void)notifyMediaPlayerSei:(id)player type: (int)type sei: (NSData*)sei;
@end

#endif //__ME_MEDIA_PLAYER_DELEGATE_H__
