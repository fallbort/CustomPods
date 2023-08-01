//
//  MMPluginProtocol.swift
//  Party
//
//  Created by fabo on 2022/5/25.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation
import UIKit
import MeMeKit

public protocol MMPluginStageProtocol {
    func didPluginConfiged() //所有当前批次的插件外部参数配置完成后插件开始载入
    func didAllPluginLoaded(plugins:[MMPluginProtocol]) //所有当前批次的插件载入完成后的通告,可选方法,只会触发一次
    func clean() //外部调用清理数据,用于卸载插件
    
    func didNewPluginLoaded(_ newPlugins:[MMPluginProtocol]) //初始化完成后，有新插件配置完成,每批次增加都会触发
    func didOldPluginRemoved(_ oldPlugins:[MMPluginProtocol]) //初始化完成后，有老插件移除,每批次删除都会触发
}

extension MMPluginStageProtocol {
    public func didAllPluginLoaded(plugins:[MMPluginProtocol]) {}
    public func didNewPluginLoaded(_ newPlugins:[MMPluginProtocol]) {}
    public func didOldPluginRemoved(_ oldPlugins:[MMPluginProtocol]) {}
}

public protocol MMPluginProtocol : AnyObject,MMPluginStageProtocol,DisposeBagProtocol, MMLayoutProtocol {
    func fetchTypeObject<T>(_ type: T.Type) -> T? where T : MMPluginProtocol //获取一个插件
    
    var dataDriver:MMDataDriverProtocol? {get set} //外部配置，数据通道
    var totalData:MMTotalDataProtocol? {get set} //外部配置，总存储数据,所有数据都在这里

    var fetchPluginManager:(()->MMPluginManagerProtocol?)? {get set} //外部配置，获取插件管理器
    var fetchPlugins:(()->[MMPluginProtocol])? {get set} //外部配置，获取当前加载的 所有插件,不包括总 数据插件，一般不使用,请使用fetchTypeObject方法获取其他插件
}

extension MMPluginProtocol {
    public func fetchTypeObject<T>(_ type: T.Type) -> T? {
        if type == MMTotalDataProtocol.self,let data = self.totalData as? T {
            return data
        }else if type == MMPluginManagerProtocol.self,let data = self.fetchPluginManager?() as? T {
            return data
        }
        return self.fetchPlugins?().fetchTypeObject(type)
    }
}

private var live_PluginManager = "live_PluginManager"
private var live_fetchPlugins = "live_fetchPlugins"
private var live_fetchOutVcPlugin = "live_fetchOutVcPlugin"
private var live_inController = "live_inController"
private var live_dataDriver = "live_dataDriver"
private var live_totalData = "live_totalData"


extension MMPluginProtocol {
    
    public var fetchPluginManager: (()->MMPluginManagerProtocol?)? {
        get {
            let object = objc_getAssociatedObject(self, &live_PluginManager) as? (()->MMPluginManagerProtocol?)
            return object
        }
        
        set {
            objc_setAssociatedObject(self, &live_PluginManager, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    public var fetchPlugins: (()->[MMPluginProtocol])? {
        get {
            let object = objc_getAssociatedObject(self, &live_fetchPlugins) as? (()->[MMPluginProtocol])
            return object
        }
        
        set {
            objc_setAssociatedObject(self, &live_fetchPlugins, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    public weak var dataDriver: MMDataDriverProtocol? {
        get {
            let weakArray = objc_getAssociatedObject(self, &live_dataDriver) as? WeakReferenceArray<MMDataDriverProtocol>
            if let object = weakArray?.allObjects().first as? MMDataDriverProtocol {
                return object
            } else {
                return nil
            }
        }
        
        set {
            let weakArray = WeakReferenceArray<MMDataDriverProtocol>()
            if let object = newValue {
                weakArray.addObject(object)
            }
            objc_setAssociatedObject(self, &live_dataDriver, weakArray, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public weak var totalData: MMTotalDataProtocol? {
        get {
            let weakArray = objc_getAssociatedObject(self, &live_totalData) as? WeakReferenceArray<MMTotalDataProtocol>
            if let object = weakArray?.allObjects().first as? MMTotalDataProtocol {
                return object
            } else {
                return nil
            }
        }
        
        set {
            let weakArray = WeakReferenceArray<MMTotalDataProtocol>()
            if let object = newValue {
                weakArray.addObject(object)
            }
            objc_setAssociatedObject(self, &live_totalData, weakArray, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
