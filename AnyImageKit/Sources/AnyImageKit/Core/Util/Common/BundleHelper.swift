//
//  BundleHelper.swift
//  AnyImageKit
//
//  Created by 蒋惠 on 2019/9/16.
//  Copyright © 2019-2021 AnyImageProject.org. All rights reserved.
//

import UIKit
import MeMeKit

public struct BundleHelper {
    
    public static var appName: String {
        if let info = Bundle.main.localizedInfoDictionary {
            if let appName = info["CFBundleDisplayName"] as? String { return appName }
            if let appName = info["CFBundleName"] as? String { return appName }
            if let appName = info["CFBundleExecutable"] as? String { return appName }
        }
        
        if let info = Bundle.main.infoDictionary {
            if let appName = info["CFBundleDisplayName"] as? String { return appName }
            if let appName = info["CFBundleName"] as? String { return appName }
            if let appName = info["CFBundleExecutable"] as? String { return appName }
        }
        return ""
    }
}

// MARK: - Module
extension BundleHelper {
    
    public enum Module: String, Equatable {
        
        case core = "Core"
        
        case picker = "Picker"
        
        case editor = "Editor"
        
        case capture = "Capture"
    }
    
    public static func bundle(for module: Module) -> Bundle {
        #if ANYIMAGEKIT_ENABLE_SPM
        return Bundle.module
        #else
        switch module {
        case .core:
            return Bundle.anyImageKitCore
        case .picker:
            return Bundle.anyImageKitPicker
        case .editor:
            return Bundle.anyImageKitEditor
        case .capture:
            return Bundle.anyImageKitCapture
        }
        #endif
    }
}

// MARK: - Styled Image
extension BundleHelper {
    
    public static func image(named: String, module: Module) -> UIImage? {
        return UIImage(named: named, in: bundle(for: module), compatibleWith: nil)
    }
    
    public static func image(named: String, style: UserInterfaceStyle, module: Module) -> UIImage? {
        let imageName = styledName(named, style: style)
        return image(named: imageName, module: module)
    }
    
    private static func styledName(_ named: String, style: UserInterfaceStyle) -> String {
        switch style {
        case .auto:
            return named + "Auto"
        case .light:
            return named + "Light"
        case .dark:
            return named + "Dark"
        }
    }
}

// MARK: - Localized String
extension BundleHelper {
    
    public static func localizedString(key: String, module: Module) -> String {
        return localizedString(key: key, value: nil, table: module.rawValue, bundle: bundle(for: module))
    }
    
    private static func localizedString(key: String, value: String?, table: String, bundle current: Bundle) -> String {
        let result = NELocalize.localizedString(key, bundle: current, table: table, comment: "", value: value)
        if result != key {
            return result
        } else { // Just in case
            let coreBundle = bundle(for: .core)
            if current != coreBundle {
                let coreResult = coreBundle.localizedString(forKey: key, value: value, table: Module.core.rawValue)
                if coreResult != key {
                    return coreResult
                }
            }
            return Bundle.main.localizedString(forKey: key, value: value, table: nil)
        }
    }
}
