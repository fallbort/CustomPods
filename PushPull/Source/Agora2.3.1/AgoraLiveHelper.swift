//
//  AgoraLiveHelper.swift
//  MeMe
//
//  Created by Mingde on 2018/5/9.
//  Copyright © 2018 sip. All rights reserved.
//

import AgoraRtcKit

class AgoraLiveHelper {
    
    class func outputRoutingTypeFormat(_ routing: AgoraAudioOutputRouting) -> String {
        var routingStr = "默认"
        
        switch routing {
        case .default:
            routingStr = "default.默认"
        case .headset:
            routingStr = "headset.耳机"
        case .earpiece:
            routingStr = "earpiece.听筒"
        case .headsetNoMic:
            routingStr = "headsetNoMic.不带麦的耳机"
        case .speakerphone:
            routingStr = "speakerphone.话筒"
        case .loudspeaker:
            routingStr = "loudspeaker.扬声器"
        case .headsetBluetooth:
            routingStr = "headsetBluetooth.蓝牙"
        case .usb:
            routingStr = "headsetBluetooth.usb"
        case .hdmi:
            routingStr = "headsetBluetooth.hdmi"
        case .displayPort:
            routingStr = "headsetBluetooth.displayPort"
        case .airPlay:
            routingStr = "headsetBluetooth.airPlay"
        @unknown default:
            routingStr = "headsetBluetooth.未知"
        }
        
        return routingStr
    }
    
    class func userOfflineReasonTypeFormat(_ reason: AgoraUserOfflineReason) -> String {
        var reasonStr = "主动离开"
        
        switch reason {
        case .quit:
            reasonStr = "quit.主动离开"
            break;
            
        // 在一定时间内（15秒）没有收到对方的任何数据包，判定为对方掉线。
        case .dropped:
            reasonStr = "dropped.超时掉线"
            break;
            
        case .becomeAudience:
            reasonStr = "becomeAudience.成为观众"
            break;
        }
        
        return reasonStr
    }
    
    class func networkQualityTypeFormat(_ quality: AgoraNetworkQuality) -> String {
        var qualityStr = "网络质量未知"
        
        switch quality {
        case .unknown:
            qualityStr = "unknown.网络质量未知"
        case .excellent:
            qualityStr = "excellent.网络质量极好"
        case .good:
            qualityStr = "good.用户主观感觉和Excellent差不多，但码率可能略低于Excellent"
        case .poor:
            qualityStr = "poor.用户主观感受有瑕疵但不影响沟通"
        case .bad:
            qualityStr = "bad.勉强能沟通但不顺畅"
        case .vBad:
            qualityStr = "vBad.网络质量非常差，基本不能沟通"
        case .down:
            qualityStr = "down.完全无法沟通"
        case .unsupported:
            qualityStr = "down.unsupported"
        case .detecting:
            qualityStr = "down.detecting"
        @unknown default:
            qualityStr = "down.未知"
        }
        return qualityStr
    }
    
    class func channelStatsFormat(_ stats: AgoraChannelStats) -> String {
        /* 1.totalDuration：通话时长，单位为秒，累计值
         * 2.txBytes：发送字节数 (bytes)，累计值
         * 3.rxBytes：接收字节数 (bytes)，累计值
         * 4.txAudioKBitRate：音频发送码率 (kbps)，瞬时值
         * 5.rxAudioKBitRate：音频接收码率 (kbps)，瞬时值
         * 6.users：当前频道内的用户人数
         * 7.cpuTotalUsage：当前系统的 CPU 使用率 (%)
         * 8.cpuAppUsage：当前应用程序的 CPU 使用率 (%)
         */
        let statsStr = "[duration = \(stats.duration) sec,\n txBytes = \(stats.txBytes) bytes,\n rxBytes = \(stats.rxBytes) bytes,\n txAudioKBitrate = \(stats.txAudioKBitrate) bytes,\n rxAudioKBitrate = \(stats.rxAudioKBitrate) bytes,\n userCount = \(stats.userCount) users,\n cpuAppUsage = \(stats.cpuAppUsage)%,\n cpuTotalUsage = \(stats.cpuTotalUsage)%]"
        
        return statsStr
    }
    
}
