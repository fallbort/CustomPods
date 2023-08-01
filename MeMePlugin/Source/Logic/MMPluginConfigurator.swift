//
//  MMPluginConfigurator.swift
//  Party
//
//  Created by fabo on 2022/5/26.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation

import Foundation
import MeMeKit
import UIKit

public class MMPluginConfigurator<CommonD:MMCommonDataProtocol,WatchD:MMWatchDataProtocol,BroadD:MMBroadcastDataProtocol,DDriver:MMDataDriverProtocol> {
    
    //MARK:<>外部变量
    
    //MARK:<>外部block
    
    
    //MARK:<>生命周期开始
    public init() {
    
    }
    //MARK:<>功能性方法
    public func configCorePlugin(_ pluginManager:MMPluginManagerProtocol, dataPlugin:MMTotalData<CommonD,WatchD,BroadD,DDriver>) {
        self.dataPlugin = dataPlugin
        let firstPlugins:[MMPluginProtocol] = [pluginManager,dataPlugin]
        
        configPlugin(pluginManager, firstPlugins, isAdd: true)
    }
    
    //isAdd 添加or删除
    public func configPlugin(_ pluginManager:MMPluginManagerProtocol,_ plugins:[MMPluginProtocol],isAdd:Bool) {
        if isAdd {
            var newPlugins:[MMPluginProtocol] = []
            for plugin in plugins {
                if self.pluginArray.contains(where: {NSObject.getAddress($0) == NSObject.getAddress(plugin)}) == false {
                    newPlugins.append(plugin)
                }
            }
            self.realConfigPlugin(pluginManager, newPlugins, needStore: true)
            for onePlugin in self.pluginArray {
                onePlugin.didNewPluginLoaded(plugins)
            }
            
        }else {
            var newPlugins:[MMPluginProtocol] = []
            for plugin in plugins {
                if let index = self.pluginArray.firstIndex(where: {NSObject.getAddress($0) == NSObject.getAddress(plugin)}) {
                    plugin.clean()
                    self.pluginArray.remove(at: index)
                    newPlugins.append(plugin)
                }
            }
            for onePlugin in self.pluginArray {
                onePlugin.didOldPluginRemoved(newPlugins)
            }
        }
    }
    
    fileprivate func realConfigPlugin(_ pluginManager:MMPluginManagerProtocol,_ plugins:[MMPluginProtocol],needStore:Bool) {
        for onePlugin in plugins {
            onePlugin.fetchPlugins = { [weak self] in
                return self?.pluginArray ?? []
            }
            onePlugin.fetchPluginManager = { [weak pluginManager] in
                return pluginManager
            }
            onePlugin.dataDriver = self.dataPlugin?.dataDriver
            onePlugin.totalData = self.dataPlugin
        }
        if needStore {
            self.pluginArray.append(contentsOf: plugins)
        }
        for onePlugin in plugins {
            onePlugin.didPluginConfiged()
        }
        for onePlugin in plugins {
            onePlugin.didAllPluginLoaded(plugins:plugins)
        }
    }
    
    func removeAllPlugins(_ pluginManager:MMPluginManagerProtocol) {
        self.configPlugin(pluginManager, self.pluginArray, isAdd: false)
    }
    //MARK:<>内部View
    
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    fileprivate var pluginArray:[MMPluginProtocol] = [] //各种插件数组,每一个单独的业务考虑是一个插件，比如Pk业务
    fileprivate weak var dataPlugin:MMTotalData<CommonD,WatchD,BroadD,DDriver>?
    
    //MARK:<>内部block
    
}
