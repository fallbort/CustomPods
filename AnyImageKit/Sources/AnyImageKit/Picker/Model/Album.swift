//
//  Album.swift
//  AnyImageKit
//
//  Created by 刘栋 on 2019/9/16.
//  Copyright © 2019-2021 AnyImageProject.org. All rights reserved.
//

import Foundation
import Photos

public class Album: Equatable {
    
    public let fetchResult: PHFetchResult<PHAsset>
    
    public let identifier: String
    public let title: String
    public let isCameraRoll: Bool
    public private(set) var assets: [Asset] = []
    
    public init(fetchResult: PHFetchResult<PHAsset>, identifier: String, title: String?, isCameraRoll: Bool, selectOptions: PickerSelectOption, rules: [AssetDisableCheckRule] = []) {
        self.fetchResult = fetchResult
        self.identifier = identifier
        self.title = title ?? ""
        self.isCameraRoll = isCameraRoll
        fetchAssets(result: fetchResult, selectOptions: selectOptions, rules: rules)
    }
    
    public static func == (lhs: Album, rhs: Album) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension Album {
    
    private func fetchAssets(result: PHFetchResult<PHAsset>, selectOptions: PickerSelectOption, rules: [AssetDisableCheckRule]) {
        var array: [Asset] = []
        let selectPhoto = selectOptions.contains(.photo)
        let selectVideo = selectOptions.contains(.video)
        let selectPhotoGIF = selectOptions.contains(.photoGIF)
        let selectPhotoLive = selectOptions.contains(.photoLive)
        
        for phAsset in result.objects() {
            let asset = Asset(idx: array.count, asset: phAsset, selectOptions: selectOptions)
            var isDisable = false
            for rule in rules {
                if rule.isDisable(for: asset) {
                    isDisable = true
                    break
                }
            }
            if isDisable { continue }
            switch asset.mediaType {
            case .photo:
                if selectPhoto {
                    array.append(asset)
                }
            case .video:
                if selectVideo {
                    array.append(asset)
                }
            case .photoGIF:
                if selectPhotoGIF {
                    array.append(asset)
                }
            case .photoLive:
                if selectPhotoLive {
                    array.append(asset)
                }
            }
        }
        assets = array
    }
}

// MARK: - Capture
extension Album {
    
    public func insertAsset(_ asset: Asset, at: Int, sort: Sort) {
        assets.insert(asset, at: at)
        reloadIndex(sort: sort)
    }
    
    public func addAsset(_ asset: Asset, atLast: Bool) {
        if atLast {
            assets.append(asset)
        } else {
            assets.insert(asset, at: assets.count-1)
        }
    }
    
    private func reloadIndex(sort: Sort) {
        var idx = 0
        for asset in assets {
            if asset.idx < 0 {
                continue
            }
            asset.idx = idx
            idx += 1
        }
    }
}

extension Album {
    
    public var count: Int {
        if hasCamera {
            return assets.count - 1
        } else {
            return assets.count
        }
    }
    
    public var hasCamera: Bool {
        return (assets.first?.isCamera ?? false) || (assets.last?.isCamera ?? false)
    }
    public var hasVideo: Bool {
        if !hasCamera {
            return (assets.first?.isVideo ?? false) || (assets.last?.isVideo ?? false)
        }
        if assets.count >= 2 {
            if assets[1].isVideo {
                return true
            }
            if assets[assets.count - 2].isVideo {
                return true
            }
        }
        return false
    }
    
    public func defalutAsset(orderBy: Sort) -> Asset? {
        if orderBy == .asc {
            for asset in assets.reversed() {
                if !asset.isCamera && !asset.isVideo {
                    return asset
                }
            }
        } else {
            for asset in assets {
                if !asset.isCamera && !asset.isVideo {
                    return asset
                }
            }
        }
        return nil
    }
}

extension Album: CustomStringConvertible {
    
    public var description: String {
        return "Album<\(title)>"
    }
}
