//
//  MMTotalDataProtocol.swift
//  Party
//
//  Created by fabo on 2022/5/25.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation

//总数据
public protocol MMTotalDataProtocol : MMPluginProtocol {
    var watchData:MMWatchDataProtocol? {get}//只存在于观众端数据
    var broadcastData:MMBroadcastDataProtocol? {get}//只存在于主播端数据
    var commonData:MMCommonDataProtocol {get} //所有端公用
    var businessData:MMBusinessDataProtocol? {get} //普通业务数据
    var startExtraData:MMStartExtraDataProtocol? {get} //额外启动参数
}

extension MMTotalDataProtocol {
    public var watchData:MMWatchDataProtocol? {return nil}
    public var broadcastData:MMBroadcastDataProtocol? {return nil}
    public var businessData:MMBusinessDataProtocol? {return nil}
    public var startExtraData:MMStartExtraDataProtocol? {return nil}
    
}
