//
//  MeMeBeautyManager.swift
//  Pods
//
//  Created by xfb on 2023/6/19.
//

import Foundation
import TiSDKInternal


@objc public class MeMeBeautyManager : NSObject {
    @objc public static let shared = MeMeBeautyManager()
    //MARK: <>外部变量
    
    //MARK: <>外部block
    
    
    //MARK: <>生命周期开始
    fileprivate override init() {
        super.init()
    }
    //MARK: <>功能性方法
    @objc public func startup(appKey:String) {
        TiInitManagerOC.shareinstance().appKey = appKey
        TiInitManagerOC.shareinstance().initSDK()
    }
    //MARK: <>内部View
    
    //MARK: <>内部UI变量
    //MARK: <>内部数据变量
    
    //MARK: <>内部block
    
}
