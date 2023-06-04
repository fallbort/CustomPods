//
//  CacheModule.swift
//  AnyImageKit
//
//  Created by 蒋惠 on 2020/12/1.
//  Copyright © 2020-2021 AnyImageProject.org. All rights reserved.
//

import UIKit

public enum CacheModule {
    
    case picker(CacheModulePicker)
    case editor(CacheModuleEditor)
}

public enum CacheModulePicker: String {
    
    case `default` = "Default"
}

public enum CacheModuleEditor: String {

    case `default` = "Default"
    case bezierPath = "BezierPath"
}

extension CacheModule {
    
    public var title: String {
        switch self {
        case .picker:
            return "Picker"
        case .editor:
            return "Editor"
        }
    }
    
    public var subTitle: String {
        switch self {
        case .picker(let subModule):
            return subModule.rawValue
        case .editor(let subModule):
            return subModule.rawValue
        }
    }
    
    public var path: String {
        let lib = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
        return "\(lib)/AnyImageKitCache/\(title)/\(subTitle)/"
    }
}

extension CacheModuleEditor {
    
    public static var imageModule: [CacheModuleEditor] {
        return [.default, .bezierPath]
    }
}
