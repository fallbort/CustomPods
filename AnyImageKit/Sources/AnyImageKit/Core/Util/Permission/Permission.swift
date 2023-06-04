//
//  Permission.swift
//  AnyImageKit
//
//  Created by 刘栋 on 2020/1/7.
//  Copyright © 2020-2021 AnyImageProject.org. All rights reserved.
//

import Foundation

public typealias PermissionCompletion = (Permission.Status) -> Void

public enum Permission: Equatable {
    
    case photos
    case camera
    case microphone
    
    public var status: Status {
        switch self {
        case .photos:
            return _checkPhotos()
        case .camera:
            return _checkCamera()
        case .microphone:
            return _checkMicrophone()
        }
    }
    
    public func request(completion: @escaping PermissionCompletion) {
        switch self {
        case .photos:
            _requestPhotos(completion: completion)
        case .camera:
            _requestCamera(completion: completion)
        case .microphone:
            _requestMicrophone(completion: completion)
        }
    }
}

extension Permission {
    
    public var localizedTitle: String {
        switch self {
        case .photos:
            return BundleHelper.localizedString(key: "PHOTOS", module: .core)
        case .camera:
            return BundleHelper.localizedString(key: "CAMERA", module: .core)
        case .microphone:
            return BundleHelper.localizedString(key: "MICROPHONE", module: .core)
        }
    }
    
    public var localizedAlertTitle: String {
        return String(format: BundleHelper.localizedString(key: "PERMISSION_IS_DISABLED", module: .core), localizedTitle)
    }
    
    public var localizedAlertMessage: String {
        switch self {
        case .photos:
            return BundleHelper.localizedString(key: "NO_PHOTOS_PERMISSION_TIPS", module: .core)
        case .camera:
            return BundleHelper.localizedString(key: "NO_CAMERA_PERMISSION_TIPS", module: .core)
        case .microphone:
            return BundleHelper.localizedString(key: "NO_MICROPHONE_PERMISSION_TIPS", module: .core)
        }
    }
}

extension Permission {
    
    public enum Status: Equatable {
        
        case notDetermined
        case denied
        case authorized
        case limited // Photos only
    }
}
