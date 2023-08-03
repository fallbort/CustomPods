//
//  MMPluginManager.swift
//  Party
//
//  Created by fabo on 2022/5/25.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation
import MeMeKit
import UIKit
import RxSwift


//理论上总体逻辑都可以在插件管理器中处理插件的加载与卸载来实现，为了简化插件管理器的代码复杂性，逻辑尽量在插件内部实现
open class MMPluginManager<CommonD:MMCommonDataProtocol,WatchD:MMWatchDataProtocol,BroadD:MMBroadcastDataProtocol,DDriver:MMDataDriverProtocol> :NSObject, MMPluginManagerProtocol {
    
    //MARK:<>外部变量
    
    //MARK:<>外部block
    
    
    //MARK:<>生命周期开始
    public init(dataDriver:DDriver? = nil) {
        self.dataPlugin = MMTotalData<CommonD,WatchD,BroadD,DDriver>(dataDriver: dataDriver)
        super.init()
        self.mmPluginManagers.addObject(self)
    }
    
    open func didPluginConfiged() {
        
    }
    //plugmanger，data，这几个只会相互加载完成后调用此方法
    open func didAllPluginLoaded(plugins:[MMPluginProtocol]) {
        self.configurator.configPlugin(self, getInitPlugins(), isAdd: true)
        
    }
    
    open func didNewPluginLoaded(_ newPlugins:[MMPluginProtocol]) {
        
    }
    
    open func clean() {
        
    }
    //MARK:<>功能性方法
    open func startup() {  //启动整个插件
        self.configurator.configCorePlugin(self, dataPlugin: self.dataPlugin)
    }
    //页面首先载入的插件，业务逻辑入口插件在这里
    open func getInitPlugins() -> [MMPluginProtocol] {
        var plugins:[MMPluginProtocol] = []
        return plugins
    }
    
    open func stopAll() {
        self.configurator.removeAllPlugins(self)
    }
    
    //MARK:<>内部View
    
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    public var configurator:MMPluginConfigurator<CommonD,WatchD,BroadD,DDriver> = MMPluginConfigurator<CommonD,WatchD,BroadD,DDriver>()
    public let dataPlugin:MMTotalData<CommonD,WatchD,BroadD,DDriver>
    
    public var disposeBag = DisposeBag()
    //MARK:<>内部block
    
}
