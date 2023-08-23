//
//  PhotoPicker.swift
//  LiveStream
//
//  Created by LuanMa on 16/7/8.
//  Copyright © 2016年 sip. All rights reserved.
//  参考: http://www.techotopia.com/index.php/An_Example_Swift_iOS_8_iPhone_Camera_Application
//

import Photos
import TOCropViewController
import MeMeKit
import RxSwift
import Result
import MeMeComponents
import MBProgressHUD


@objc public class PhotoPicker: NSObject {
    
    @objc public weak var controller: UIViewController?
    
    var customAspectRatio: CGSize?
    var aspectRatioPreset: TOCropViewControllerAspectRatioPreset = .presetSquare

    @objc public var didPickPhoto: ((_ image: UIImage) -> Void)?
    var didCancel: (()->Void)?
	var sourceView: UIView?
    
    var isWaitForBlockCompletion: Bool = false
    var customSetupCropController: ((TOCropViewController)->Void)?
    var handlePhotoBlock: ((_ image: UIImage, _ completionBlock: ((_ handleSuccess: Bool)->Void)?)->Void)? // 返回值是代表处理是否成功，成功退下面板，不成功则保持面板
    
    var phpicker: PHPicker?
    
	static var canAccessPhotoSystem: Bool {
		return PHPhotoLibrary.authorizationStatus() == .authorized || PHPhotoLibrary.authorizationStatus() == .notDetermined
	}
    
    @objc public func showChoiseAlert() {
		let alert = UIAlertController(title: NELocalize.localizedString("Please select",bundlePath: MeMeCustomPodsBundle, comment: ""), message: nil, preferredStyle: .actionSheet)

		let actionAlbum = UIAlertAction(title: NELocalize.localizedString("Photo album",bundlePath: MeMeCustomPodsBundle, comment: ""), style: .default) { [unowned self] action in
			self.takeAlbum()
            
		}
		alert.addAction(actionAlbum)

		let actionCamera = UIAlertAction(title: NELocalize.localizedString("Take photos",bundlePath: MeMeCustomPodsBundle, comment: ""), style: .default) { [unowned self] action in
			self.takeCamera()
		}
		alert.addAction(actionCamera)

        let actionCancel = UIAlertAction(title: NELocalize.localizedString("Cancel",bundlePath: MeMeCustomPodsBundle, comment: ""), style: .cancel) { [unowned self] action in
            self.didCancel?()
        }
		alert.addAction(actionCancel)
		
		if isPad {
			alert.modalPresentationStyle = .popover
			let popPresenter = alert.popoverPresentationController
			popPresenter?.sourceView = sourceView
			popPresenter?.sourceRect = sourceView!.bounds
		}
        
		controller?.present(alert, animated: true, completion: nil)
	}

    func takeCamera() {
		self.imagePicker(.camera)
	}

    func takeAlbum() {
        if phpicker != nil {
            phpicker = nil
        }
        
        phpicker = PHPicker()

        phpicker!.assetsObser
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else { return }
                
                switch result {
                case .success(let aassets):
                    guard let assets = aassets as? [Asset],
                          assets.count > 0  else { return }
                    
                    let image = assets[0].image
                    let cropController = TOCropViewController.init(croppingStyle: .default, image: image)
                    cropController.title = nil
                    cropController.delegate = self
                    cropController.aspectRatioLockEnabled = true
                    cropController.resetAspectRatioEnabled = false
                    cropController.aspectRatioPreset = self.aspectRatioPreset
                    if self.aspectRatioPreset == .presetCustom, let customAspectRatio = self.customAspectRatio {
                        cropController.customAspectRatio = customAspectRatio
                    } else {
                        cropController.aspectRatioPreset = .presetSquare
                    }
                    self.customSetupCropController?(cropController)
                    
                    ScreenUIManager.topViewController()?.present(cropController, animated: true)
                    self.phpicker = nil
                case .failure(_):
                    self.didCancel?()
                    self.phpicker = nil
                }
            })
            .disposed(by: phpicker!.mmDisposeBag)
        
        phpicker!.presentPicker(PHPickerOptions())
	}

    fileprivate func imagePicker(_ sourceType: UIImagePickerController.SourceType) {
		if UIImagePickerController.isSourceTypeAvailable(sourceType) {
			let imagePicker = UIImagePickerController()
            imagePicker.view.backgroundColor = .white
			imagePicker.delegate = self
			imagePicker.sourceType = sourceType
			imagePicker.allowsEditing = false

			if let popPresenter = imagePicker.popoverPresentationController, let sourceView = sourceView {
				popPresenter.sourceView = sourceView
				popPresenter.sourceRect = sourceView.bounds
			}
            
			controller?.present(imagePicker, animated: true, completion: nil)
		}
	}
}

// MARK: - UINavigationControllerDelegate
// MARK: - UIImagePickerControllerDelegate
extension PhotoPicker: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let cropController = TOCropViewController.init(croppingStyle: .default, image: image)
            cropController.title = nil
            cropController.delegate = self
            cropController.aspectRatioLockEnabled = true
            cropController.resetAspectRatioEnabled = false
            cropController.aspectRatioPreset = aspectRatioPreset
            if aspectRatioPreset == .presetCustom, let customAspectRatio = customAspectRatio {
                cropController.customAspectRatio = customAspectRatio
            } else {
                cropController.aspectRatioPreset = .presetSquare
            }
            customSetupCropController?(cropController)
            if picker.sourceType == .camera {
                picker.dismiss(animated: false, completion: { [weak self] in
                    self?.controller?.present(cropController, animated: true, completion: nil)
                })
            } else {
                picker.pushViewController(cropController, animated: true)
//                picker.viewControllers[1].title = nil
//                picker.viewControllers[1].navigationItem.leftBarButtonItem = nil
//                picker.viewControllers[1].navigationItem.backBarButtonItem = nil
            }
        }
	}

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true, completion: nil)
        didCancel?()
	}
}

extension PhotoPicker : TOCropViewControllerDelegate {
    public func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        cropViewController.title = nil
        cropViewController.navigationController?.title = nil
        if let viewController = cropViewController.navigationController?.viewControllers[0] {
            viewController.title = nil
        }
        
        let cropImg: UIImage
        if max(image.size.width, image.size.height) > 1280 {
            let width: CGFloat
            let height: CGFloat
            if image.size.width > image.size.height {
                width = 1280.0
                height = image.size.height * (1280.0 / image.size.width)
            } else {
                width = image.size.width * (1280.0 / image.size.height)
                height = 1280.0
            }
            
            cropImg = image.scale(to: CGSize(width: width, height: height))
        } else {
            cropImg = image
        }
        
        if isWaitForBlockCompletion, let handlePhotoBlock = handlePhotoBlock {
            if !NetworkListener.shared.isNetworkReachability {
                return
            }
            MBProgressHUD.showAdded(to: cropViewController.view, animated: true)
            let completionBlock: ((_ success: Bool)->Void) = { [weak cropViewController] success in
                guard let wcropViewController = cropViewController else {
                    return
                }
                MBProgressHUD.hide(for: wcropViewController.view, animated: true)
                if success {
                    cropViewController?.presentingViewController?.dismiss(animated: true)
                }
            }
            handlePhotoBlock(cropImg, completionBlock)
        } else {
            cropViewController.presentingViewController?.dismiss(animated: false, completion: { [weak self] in
                guard let wself = self else {
                    return
                }
                
                wself.didPickPhoto?(cropImg)
            })
        }
    }
}
