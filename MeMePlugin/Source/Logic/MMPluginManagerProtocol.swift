//
//  MMPluginManagerProtocol.swift
//  Party
//
//  Created by fabo on 2022/5/25.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation
import MeMeKit

fileprivate var allPluginManagers: WeakReferenceArray<MMPluginManagerProtocol>?


//管理插件的插件
public protocol MMPluginManagerProtocol : NSObject, MMPluginProtocol {
    var mmPluginOwnerObject:NSObject? { get }
    func stopAll()
}

private var mmPluginOwnerkey = "key"
private var mmPluginMainViewkey = "key"
private var mmAllPluginskey = "key"

extension MMPluginManagerProtocol {
    //当前谁reatain了MMPluginManagerProtocol对象
    public weak var mmPluginOwnerObject: NSObject? {
        get {
            let weakArray = objc_getAssociatedObject(self, &mmPluginOwnerkey) as? WeakReferenceArray<NSObject>
            if let object = weakArray?.allObjects().first as? NSObject {
                return object
            } else {
                return nil
            }
        }
        
        set {
            if newValue?.getAddress() != self.mmPluginOwnerObject?.getAddress() {
                if newValue?.mmPluginManger != self {
                    if newValue?.mmPluginManger?.mmPluginOwnerObject != nil {
                        newValue?.mmPluginManger?.mmPluginOwnerObject = nil
                    }
                }
                
                let weakArray = WeakReferenceArray<NSObject>()
                if let object = newValue {
                    weakArray.addObject(object)
                }
                let oldObject = self.mmPluginOwnerObject
                objc_setAssociatedObject(self, &mmPluginOwnerkey, weakArray, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                if oldObject != newValue && oldObject?.mmPluginManger == self {
                    oldObject?.mmPluginManger = nil
                }
                if newValue?.mmPluginManger != self {
                    newValue?.mmPluginManger = self
                }
            }
        }
    }
    
    //当前plugin使用的主view，用于弹窗等操作
    public weak var mmPluginMainView: UIView? {
        get {
            let weakArray = objc_getAssociatedObject(self, &mmPluginMainViewkey) as? WeakReferenceArray<NSObject>
            if let object = weakArray?.allObjects().first as? UIView {
                return object
            } else {
                return nil
            }
        }
        
        set {
            let weakArray = WeakReferenceArray<NSObject>()
            if let object = newValue {
                weakArray.addObject(object)
            }
            objc_setAssociatedObject(self, &mmPluginMainViewkey, weakArray, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public static var mmPluginManagers:WeakReferenceArray<MMPluginManagerProtocol> {
        if let managers = allPluginManagers {
            return managers
        }else{
            let managers = WeakReferenceArray<MMPluginManagerProtocol>()
            allPluginManagers = managers
            return managers
        }
    }
    
    public var mmPluginManagers:WeakReferenceArray<MMPluginManagerProtocol> {
        return Self.mmPluginManagers
    }
    
    public func stopAll() {}
}


private var livePluginMangerKey = "key"
private var liveWeakPluginMangerKey = "key"

extension NSObject {
    //当前retain的MMPluginManagerProtocol对象，用于维持pluginmanager
    public var mmPluginManger: MMPluginManagerProtocol? {
        get {
            let timer = objc_getAssociatedObject(self, &livePluginMangerKey) as? MMPluginManagerProtocol
            return timer
        }
        
        set {
            if newValue?.getAddress() != self.mmPluginManger?.getAddress() {
                if newValue?.mmPluginOwnerObject != self {
                    if newValue?.mmPluginOwnerObject?.mmPluginManger != nil {
                        newValue?.mmPluginOwnerObject?.mmPluginManger = nil
                    }
                }
                let oldManager = self.mmPluginManger
                objc_setAssociatedObject(self, &livePluginMangerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                if oldManager?.getAddress() != newValue?.getAddress() && oldManager?.mmPluginOwnerObject == self {
                    oldManager?.mmPluginOwnerObject = nil
                }
                if newValue?.mmPluginOwnerObject != self {
                    newValue?.mmPluginOwnerObject = self
                }
                self.mmWeakPluginManger = newValue
            }
            
        }
    }
    //当前weak的MMPluginManagerProtocol对象,用于获取内部的plugin
    public weak var mmWeakPluginManger: MMPluginManagerProtocol? {
        get {
            let weakArray = objc_getAssociatedObject(self, &liveWeakPluginMangerKey) as? WeakReferenceArray<MMPluginManagerProtocol>
            if let object = weakArray?.allObjects().first as? MMPluginManagerProtocol {
                return object
            } else {
                return nil
            }
        }
        
        set {
            let weakArray = WeakReferenceArray<MMPluginManagerProtocol>()
            if let object = newValue {
                weakArray.addObject(object)
            }
            objc_setAssociatedObject(self, &liveWeakPluginMangerKey, weakArray, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

