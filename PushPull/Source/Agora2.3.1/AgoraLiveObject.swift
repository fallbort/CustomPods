//
//  AgoraLiveObject.swift
//  MeMe
//
//  Created by Mingde on 2019/3/14.
//  Copyright © 2019 sip. All rights reserved.
//
import Foundation

class AgoraLiveObject: NSObject {
    
    var liveType: LivePushRoomType = .Voice
    var anchorUid: Int = 0
    var currentUid: Int = 0
    var isAnchor: Bool = false
    var preview: UIView?
    var views: [UIView]?
    var uids: [UInt] = []
    var myPosition = 0
   
    override init() {
        super.init()
    }

}

