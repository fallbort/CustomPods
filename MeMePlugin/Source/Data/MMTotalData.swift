//
//  MMTotalData.swift
//  LinYu
//
//  Created by xfb on 2023/7/28.
//

import Foundation

import Foundation
import MeMeKit

public class MMTotalData<CommonD:MMCommonDataProtocol,WatchD:MMWatchDataProtocol,BroadD:MMBroadcastDataProtocol,DDriver:MMDataDriverProtocol> :NSObject, MMTotalDataProtocol {
    required public convenience init(dataDriver: DDriver?) {
        self.init()
        self.dataDriver = dataDriver
    }
    
    public lazy var commonData: MMCommonDataProtocol = CommonD()
    
    public var watchData:WatchD?
    public var broadcastData:BroadD?
    
    public func didPluginConfiged() {
        
    }
    
    public func clean() {
        
    }
    
    
    //MARK: <>外部变量
    
    //MARK: <>外部block
    
    
    //MARK: <>生命周期开始
    fileprivate override init() {
        super.init()
    }
    //MARK: <>功能性方法
    
    //MARK: <>内部View
    
    //MARK: <>内部UI变量
    //MARK: <>内部数据变量
    public var dataDriver: DDriver?
    
    //MARK: <>内部block
    
}
