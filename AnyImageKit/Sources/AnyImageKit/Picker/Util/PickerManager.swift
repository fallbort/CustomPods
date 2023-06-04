//
//  PickerManager.swift
//  AnyImageKit
//
//  Created by 刘栋 on 2019/9/16.
//  Copyright © 2019-2021 AnyImageProject.org. All rights reserved.
//

import UIKit
import Photos

public struct FetchRecord {
    
    public let identifier: String
    public var requestIDs: [PHImageRequestID]
}

public final class PickerManager {
    
    public var options: PickerOptionsInfo = .init()
    
    public var photoCount = 0
    
    public var isUpToLimit: Bool {
        return selectedAssets.count == options.selectLimit - photoCount
    }
    
    public var useOriginalImage: Bool = false
    
    /// 已选中的资源
    public var selectedAssets: [Asset] = []
    /// 获取失败的资源
    private var failedAssets: [Asset] = []
    /// 管理 failedAssets 队列的锁
    private let lock: NSLock = .init()
    
    /// Running Fetch Requests
    private var fetchRecords = [FetchRecord]()
    
    /// 缓存
    public let cache = ImageCacheTool(module: .picker(.default), memoryCountLimit: 10, useDiskCache: false)
    
    public init() { }
    
    public let workQueue = DispatchQueue(label: "org.AnyImageProject.AnyImageKit.DispatchQueue.PickerManager")
    public let resizeSemaphore = DispatchSemaphore(value: 3)
}

extension PickerManager {
    
    public func clearAll() {
        useOriginalImage = false
        selectedAssets.removeAll()
        failedAssets.removeAll()
        cache.clearAll()
        cancelAllFetch()
    }
}

// MARK: - Fetch Queue

extension PickerManager {
    
    public func enqueueFetch(for identifier: String, requestID: PHImageRequestID) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            if let index = self.fetchRecords.firstIndex(where: { $0.identifier == identifier }) {
                self.fetchRecords[index].requestIDs.append(requestID)
            } else {
                self.fetchRecords.append(FetchRecord(identifier: identifier, requestIDs: [requestID]))
            }
        }
    }
    
    public func dequeueFetch(for identifier: String, requestID: PHImageRequestID?) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            guard let requestID = requestID else { return }
            if let index = self.fetchRecords.firstIndex(where: { $0.identifier == identifier }) {
                if let idx = self.fetchRecords[index].requestIDs.firstIndex(of: requestID) {
                    self.fetchRecords[index].requestIDs.remove(at: idx)
                }
                if self.fetchRecords[index].requestIDs.isEmpty {
                    self.fetchRecords.remove(at: index)
                }
            }
        }
    }
    
    public func cancelFetch(for identifier: String) {
        if let index = self.fetchRecords.firstIndex(where: { $0.identifier == identifier }) {
            let fetchRecord = self.fetchRecords.remove(at: index)
            fetchRecord.requestIDs.forEach { PHImageManager.default().cancelImageRequest($0) }
        }
    }
    
    public func cancelAllFetch() {
        for fetchRecord in self.fetchRecords {
            fetchRecord.requestIDs.forEach { PHImageManager.default().cancelImageRequest($0) }
        }
        self.fetchRecords.removeAll()
    }
}

// MARK: - Select

extension PickerManager {
    
    @discardableResult
    public func addSelectedAsset(_ asset: Asset?) -> Bool {
        guard let asset = asset else {return true}
        if selectedAssets.contains(asset) { return false }
        if selectedAssets.count == options.selectLimit { return false }
        selectedAssets.append(asset)
        asset.isSelected = true
        asset.selectedNum = selectedAssets.count + photoCount
        syncAsset(asset)
        return true
    }
    
    @discardableResult
    public func addselectedAsset(_ asset: Asset)  -> Bool {
        if selectedAssets.contains(asset) { return false }
        if selectedAssets.count == options.selectLimit { return false }
        selectedAssets.append(asset)
        self.syncAsset(asset)
        return true
    }
    
    @discardableResult
    public func removeSelectedAsset(_ asset: Asset) -> Bool {
        guard let idx = selectedAssets.firstIndex(where: { $0 == asset }) else { return false }
        for item in selectedAssets {
            if item.selectedNum > asset.selectedNum {
                item.selectedNum -= 1
            }
        }
        selectedAssets.remove(at: idx)
        asset.isSelected = false
        asset._images[.initial] = nil
        return true
    }
    public func removeSelectedAssetWithCurrentIndex(_ index: Int) {
       
        for item in selectedAssets {
            if item.selectedNum > index {
                item.selectedNum -= 1
            }
        }
    }
    
    public func removeAllSelectedAsset() {
        selectedAssets.removeAll()
    }
    
    public func syncAsset(_ asset: Asset) {
        switch asset.mediaType {
        case .photo, .photoGIF, .photoLive:
            // 勾选图片就开始加载
            if let image = cache.retrieveImage(forKey: asset.phAsset.localIdentifier) {
                asset._images[.initial] = image
                self.didSyncAsset()
            } else {
                workQueue.async { [weak self] in
                    guard let self = self else { return }
                    let options = _PhotoFetchOptions(sizeMode: .preview(self.options.largePhotoMaxWidth))
                    self.requestPhoto(for: asset.phAsset, options: options) { result in
                        switch result {
                        case .success(let response):
                            if !response.isDegraded {
                                asset._images[.initial] = response.image
                                self.didSyncAsset()
                            }
                        case .failure(let error):
                            self.lock.lock()
                            self.failedAssets.append(asset)
                            self.lock.unlock()
                            _print(error)
                            let message = BundleHelper.localizedString(key: "FETCH_FAILED_PLEASE_RETRY", module: .picker)
                            NotificationCenter.default.post(name: .didSyncAsset, object: message)
                        }
                    }
                }
            }
        case .video:
            workQueue.async { [weak self] in
                guard let self = self else { return }
                let options = _PhotoFetchOptions(sizeMode: .preview(500), needCache: true)
                self.requestPhoto(for: asset.phAsset, options: options, completion: { result in
                    switch result {
                    case .success(let response):
                        asset._images[.initial] = response.image
                    case .failure:
                        break
                    }
                })
                // 同步请求图片
                self.requestVideo(for: asset.phAsset) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(_):
                        asset.videoDidDownload = true
                        self.didSyncAsset()
                    case .failure(let error):
                        self.lock.lock()
                        self.failedAssets.append(asset)
                        self.lock.unlock()
                        _print(error)
                        let message = BundleHelper.localizedString(key: "FETCH_FAILED_PLEASE_RETRY", module: .picker)
                        NotificationCenter.default.post(name: .didSyncAsset, object: message)
                    }
                }
            }
        }
    }
    
    public func resynchronizeAsset() {
        lock.lock()
        let assets = failedAssets
        failedAssets.removeAll()
        lock.unlock()
        assets.forEach { syncAsset($0) }
    }
}

// MARK: - Private function
extension PickerManager {
    
    private func didSyncAsset() {
        let isReady = selectedAssets.filter{ !$0.isReady }.isEmpty
        if isReady {
            NotificationCenter.default.post(name: .didSyncAsset, object: nil)
        }
    }
}
