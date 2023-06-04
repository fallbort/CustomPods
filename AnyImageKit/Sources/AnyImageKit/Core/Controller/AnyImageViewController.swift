//
//  AnyImageViewController.swift
//  AnyImageKit
//
//  Created by 刘栋 on 2020/1/7.
//  Copyright © 2020-2021 AnyImageProject.org. All rights reserved.
//

import UIKit

open class AnyImageViewController: UIViewController {
    
    private var page: AnyImagePage = .undefined
    private var isStatusBarHidden: Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    weak var trackObserver: DataTrackObserver?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setTrackPage()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
   
    open override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        setTrackObserverOrDelegate(viewControllerToPresent)
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    open override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    
    open override var shouldAutorotate: Bool {
        return false
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    open func setStatusBar(hidden: Bool) {
        isStatusBarHidden = hidden
    }
}

// MARK: - Function
extension AnyImageViewController {
    
    public func showAlert(message: String) {
        let alert = UIAlertController(title: BundleHelper.localizedString(key: "ALERT", module: .core), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: BundleHelper.localizedString(key: "OK", module: .core), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Data Track
extension AnyImageViewController {
    
    private func setTrackPage() {
        switch self {
        #if ANYIMAGEKIT_ENABLE_PICKER
        case _ as AlbumPickerViewController:
            page = .albumPicker
        case _ as AssetPickerViewController:
            page = .assetPicker
        case _ as PhotoPreviewController:
            page = .photoPreview
        #endif
        
        #if ANYIMAGEKIT_ENABLE_EDITOR
        case _ as PhotoEditorController:
            page = .photoEditor
        case _ as VideoEditorController:
            page = .videoEditor
        case _ as InputTextViewController:
            page = .textInput
        #endif
            
        #if ANYIMAGEKIT_ENABLE_CAPTURE
        case _ as CaptureViewController:
            page = .capture
        case _ as PadCaptureViewController:
            page = .capture
        #endif
            
        default:
            page = .undefined
        }
    }
    
    private func setTrackObserverOrDelegate(_ target: UIViewController) {
        if let controller = target as? AnyImageViewController {
            controller.trackObserver = trackObserver
        } else if let controller = target as? AnyImageNavigationController {
            if let navigationController = navigationController as? AnyImageNavigationController {
                controller.trackDelegate = navigationController.trackDelegate
            } else if let navigationController = presentingViewController as? AnyImageNavigationController {
                controller.trackDelegate = navigationController.trackDelegate
            }
        }
    }
}

// MARK: - Permission
extension AnyImageViewController {
    
    public func check(permission: Permission, authorized: @escaping () -> Void, limited: @escaping () -> Void, denied: @escaping (Permission) -> Void) {
        switch permission.status {
        case .notDetermined:
            permission.request { result in
                switch result {
                case .authorized:
                    authorized()
                case .denied:
                    denied(permission)
                default:
                    limited()
                }
            }
        case .authorized:
            authorized()
        case .limited:
            limited()
        case .denied:
            denied(permission)
        }
    }
    
    public func check(permissions: [Permission], authorized: @escaping () -> Void, denied: @escaping (Permission) -> Void) {
        if !permissions.isEmpty {
            var _permissions = permissions
            let permission = _permissions.removeFirst()
            check(permission: permission, authorized: { [weak self] in
                guard let self = self else { return }
                self.check(permissions: _permissions, authorized: authorized, denied: denied)
            }, limited: { [weak self] in
                guard let self = self else { return }
                self.check(permissions: _permissions, authorized: authorized, denied: denied)
            }, denied: { _ in 
                denied(permission)
            })
        } else {
            authorized()
        }
    }
}

// MARK: - Permission UI
extension AnyImageViewController {
    
    public func check(permission: Permission, authorized: @escaping () -> Void, canceled: @escaping (Permission) -> Void) {
        check(permission: permission, authorized: authorized, limited: authorized, denied: { [weak self] _ in
            guard let self = self else { return }
            let title = permission.localizedAlertTitle
            let message = String(format: permission.localizedAlertMessage, BundleHelper.appName)
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let settings = BundleHelper.localizedString(key: "SETTINGS", module: .core)
            alert.addAction(UIAlertAction(title: settings, style: .default, handler: { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url, options: [:]) { _ in
                    canceled(permission)
                }
            }))
            let cancel = BundleHelper.localizedString(key: "CANCEL", module: .core)
            alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: { _ in
                canceled(permission)
            }))
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    public func check(permissions: [Permission], authorized: @escaping () -> Void, canceled: @escaping (Permission) -> Void) {
        if !permissions.isEmpty {
            var _permissions = permissions
            let permission = _permissions.removeFirst()
            check(permission: permission, authorized: { [weak self] in
                guard let self = self else { return }
                self.check(permissions: _permissions, authorized: authorized, canceled: canceled)
            }, canceled: canceled)
        } else {
            authorized()
        }
    }
}

// MARK: - HUD
extension AnyImageViewController {
    
    public func showWaitHUD(_ message: String = "") {
        _showWaitHUD(self, message)
    }

    public func showMessageHUD(_ message: String) {
        _showMessageHUD(self, message)
    }

    public func hideHUD(animated: Bool = true) {
        _hideHUD(self, animated: animated)
    }
}
