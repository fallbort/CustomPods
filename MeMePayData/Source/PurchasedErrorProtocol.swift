//
//  PurchasedErrorProtocol.swift
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/9.
//

import Foundation

public protocol PurchasedErrorProtocol: CustomNSError, CustomStringConvertible {
    var code:Int {get set}
    var message:String {get set}
}

extension PurchasedErrorProtocol {
    public static var errorDomain: String { return "meme.purchased" }
    
    /// The error code within the given domain.
    public var errorCode: Int { return code }
    
    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] { return [NSLocalizedDescriptionKey: message] }
}

extension PurchasedErrorProtocol {
    public var description: String {
        return "PurchasedError[code=\(code),message=\(message)]"
    }
}

