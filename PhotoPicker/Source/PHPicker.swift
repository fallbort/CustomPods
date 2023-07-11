//
//  PHPickerManager.swift
//  Example
//
//  Created by yue on 2020/11/12.
//  Copyright © 2020 AnyImageProject.org. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import MeMeKit

struct PHPickerOptions {
    /// Theme 主题
    /// - Default: Auto
    public var theme: PickerTheme = .init(style: .auto)
    
    /// Select Limit 最多可选择的资源数量
    /// - Default: 9
    public var selectLimit: Int = 1
    
    /// Column Number 每行的列数
    /// - Default: 4
    public var columnNumber: Int = 4
    /// Max Width for export Photo 导出小图的最大宽度
    /// - Default: 800
    public var photoMaxWidth: CGFloat = 800
    
    /// Max Width for export Large Photo(When User pick original image) 导出大图的最大宽度(勾选原图时)
    /// - Default: 1200
    public var largePhotoMaxWidth: CGFloat = 1200
    
    public var selectOptions: PickerSelectOption = [.photo]
}

class PHPicker: NSObject {
    
    var assetsObser = PublishSubject<Result<[Any], MemeCommonError>>()
    fileprivate var controller: ImagePickerController?
    
    func presentPicker(_ options: PHPickerOptions) {
        
        var op = PickerOptionsInfo()
        op.theme = options.theme
        op.selectLimit = options.selectLimit
        op.columnNumber = options.columnNumber
        op.photoMaxWidth = options.photoMaxWidth
        op.largePhotoMaxWidth = options.largePhotoMaxWidth
        op.selectOptions = options.selectOptions

        if controller != nil {
            controller = nil
        }
        
        controller = ImagePickerController(options: op,
                                               delegate: self)
        controller!.trackDelegate = self
        if #available(iOS 13.0, *) {
            controller!.modalPresentationStyle = .fullScreen
        }
        
        ScreenUIManager.topViewController()?.present(controller!, animated: true, completion: nil)
    }
    
}

// MARK: - ImagePickerControllerDelegate
extension PHPicker: ImagePickerControllerDelegate {
    func imagePickerChooseVideo(_ picker: ImagePickerController, asset: Asset) {
        
    }
    
    
    func imagePicker(_ picker: ImagePickerController, didFinishPicking result: PickerResult) {
        picker.dismiss(animated: true) { [weak self] in
            self?.assetsObser.onNext(.success(result.assets))
        }
    }
    
    func imagePickerDidCancel(_ picker: ImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.assetsObser.onNext(.failure(MemeCommonError.cancel))
        }
    }
}

// MARK: - ImageKitDataTrackDelegate
extension PHPicker: ImageKitDataTrackDelegate {
    
    func dataTrack(page: AnyImagePage, state: AnyImagePageState) {
        switch state {
        case .enter:
            print("[Data Track] ENTER Page: \(page.rawValue)")
        case .leave:
            print("[Data Track] LEAVE Page: \(page.rawValue)")
        }
    }
    
    func dataTrack(event: AnyImageEvent, userInfo: [AnyImageEventUserInfoKey: Any]) {
        print("[Data Track] EVENT: \(event.rawValue), userInfo: \(userInfo)")
    }
}
