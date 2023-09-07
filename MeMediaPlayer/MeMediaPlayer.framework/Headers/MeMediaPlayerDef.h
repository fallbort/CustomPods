#ifndef __ME_MEDIA_PLAYER_DEF_H__
#define __ME_MEDIA_PLAYER_DEF_H__

#import <Foundation/Foundation.h>

//=============================================================================
// media player log level
typedef enum MeMediaPlayerLogLevel {
    MeMediaPlayerLogLevelNone               = 0,
    MeMediaPlayerLogLevelDefault            = 1,
    MeMediaPlayerLogLevelVerbose            = 2,
    MeMediaPlayerLogLevelDebug              = 3,
    MeMediaPlayerLogLevelInfo               = 4,
    MeMediaPlayerLogLevelWarn               = 5,
    MeMediaPlayerLogLevelError              = 6,
    MeMediaPlayerLogLevelFatal              = 7,
} MeMediaPlayerLogLevel;

typedef enum MeMediaPlayerNetworkType {
    MeMediaPlayerNetworkNone                = 0,
    MeMediaPlayerNetworkWIFI                = 1,
    MeMediaPlayerNetworkWWAN                = 2,
} MeMediaPlayerNetworkType;
 
// media player state
typedef enum MeMediaPlayerState {
    MeMediaPlayerStateIdle                  = 0,
    MeMediaPlayerStateInitialized           = 1,
    MeMediaPlayerStateAsyncPreparing        = 2,
    MeMediaPlayerStatePrepared              = 3,
    MeMediaPlayerStateStarted               = 4,
    MeMediaPlayerStatePaused                = 5,
    MeMediaPlayerStateCompleted             = 6,
    MeMediaPlayerStateStopped               = 7,
    MeMediaPlayerStateError                 = 8,
    MeMediaPlayerStateEnd                   = 9,
} MeMediaPlayerState;

// media player display scale mode
typedef enum MeMediaPlayerDisplayScaleMode
{
    MeMediaPlayerDisplayScaleModeNone       = 0,        ///< no scale
    MeMediaPlayerDisplayScaleModeAspectFit  = 1,        ///< aspect fit
    MeMediaPlayerDisplayScaleModeAspectFill = 2,        ///< aspect fill
    MeMediaPlayerDisplayScaleModeFill       = 3,        ///< fill
    MeMediaPlayerDisplayScaleModeTop        = 4,        ///< top
    MeMediaPlayerDisplayScaleModeBottom     = 5,        ///< bottom
    MeMediaPlayerDisplayScaleModeScale      = 6,        ///< scale
} MeMediaPlayerDisplayScaleMode;

// media player message type
typedef enum MeMediaPlayerInfoType {
    MeMediaPlayerInfoBufferStart            = 1,
    MeMediaPlayerInfoBufferEnd              = 2,
    MeMediaPlayerInfoSeekCompleted          = 3,
    MeMediaPlayerInfoVideoRenderingStart    = 4,
} MeMediaPlayerInfoType;

// media player error type
typedef enum MeMediaPlayerErrorType {
    // player error
    MeMediaPlayerErrorInvalidData           = 2000,
    MeMediaPlayerErrorOpenFailed            = 2001,
    MeMediaPlayerErrorTimeout               = 2002,
    MeMediaPlayerErrorOutOfMemory           = 2003,
    MeMediaPlayerErrorParseCodecParam       = 2004,
    MeMediaPlayerErrorFindAudioDecoder      = 2005,
    MeMediaPlayerErrorFindVideoDeocder      = 2006,
    MeMediaPlayerErrorOpenAudioDecoder      = 2007,
    MeMediaPlayerErrorOpenVideoDecoder      = 2008,
    MeMediaPlayerErrorPermissionDenied      = 2009,
    MeMediaPlayerErrorInvalidArgument       = 2010,
    // ffmpeg error
    MeMediaPlayerErrorDemuxerNotFound       = 2100,
    MeMediaPlayerErrorDecoderNotFound       = 2101,
    MeMediaPlayerErrorProtocolNotFound      = 2102,
    MeMediaPlayerErrorOptionNotFound        = 2103,
    MeMediaPlayerErrorStreamNotFound        = 2104,
    MeMediaPlayerErrorPrepareAudioOutput    = 2105,
    MeMediaPlayerErrorAudioDecodeFailed     = 2106,
    MeMediaPlayerErrorVideoDecodeFailed     = 2107,
    MeMediaPlayerErrorAudioRenderFailed     = 2108,
    MeMediaPlayerErrorVideoRenderFailed     = 2109,
    MeMediaPlayerErrorEof                   = 2110,
    MeMediaPlayerErrorExit                  = 2111,
    // network error
    MeMediaPlayerErrorNetworkDown           = 2300,
    MeMediaPlayerErrorNetworkUnreachable    = 2301,
    MeMediaPlayerErrorNetworkDroppedOnReset = 2302,
    MeMediaPlayerErrorNetworkResetByPeer    = 2303,
    MeMediaPlayerErrorConnectionRefused     = 2304,
    MeMediaPlayerErrorConnectAborted        = 2305,
    MeMediaPlayerErrorHttpBadRequest        = 2400,
    MeMediaPlayerErrorHttpUnauthorized      = 2401,
    MeMediaPlayerErrorHttpForbidden         = 2403,
    MeMediaPlayerErrorHttpNotFound          = 2404,
    MeMediaPlayerErrorHttpOther4XX          = 2499,
    MeMediaPlayerErrorHttpServerError       = 2500,
    
    MeMediaPlayerErrorUnKnown               = 2999,
    
} MeMediaPlayerErrorType;


#endif //__ME_MEDIA_PLAYER_DEF_H__
