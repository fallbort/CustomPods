//
//  FBNettyError.swift
//  aaaa
//
//  Created by fabo on 2020/5/28.
//  Copyright © 2020 meme. All rights reserved.
//

import Foundation
import Result

public enum FBNettyError : CustomNSError {
    case network
    case notInit  //房间未初始化
    case cancel  //取消
    case responeError(_ error:NSError)
    case system(_ error:NSError)
    case other(_ error:NSError)
}

public typealias FbNettyCallback = (Result<FbNettyAnswer, FBNettyError>) -> Void

