//
//  MMPluginManagerProtocol.swift
//  Party
//
//  Created by fabo on 2022/5/25.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation
import MeMeKit


//管理插件的插件
public protocol MMPluginManagerProtocol : NSObject, MMPluginProtocol {
    var mmPluginOwnerObject:NSObject? { get }
}

private var mmPluginOwnerkey = "key"
private var mmPluginMainViewkey = "key"

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
            let weakArray = WeakReferenceArray<NSObject>()
            if let object = newValue {
                weakArray.addObject(object)
            }
            objc_setAssociatedObject(self, &mmPluginOwnerkey, weakArray, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
            newValue?.mmPluginOwnerObject?.mmPluginManger = nil
            newValue?.mmPluginOwnerObject = self
            self.mmWeakPluginManger = newValue
            objc_setAssociatedObject(self, &livePluginMangerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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

