//
//  MMLayoutProtocol.swift
//  Party
//
//  Created by fabo on 2022/5/28.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation
import RxSwift

//布局默认协议
public protocol MMLayoutProtocol {
    var mmLayoutSettedObser:BehaviorSubject<Bool?> {get} //布局是否已完成
}

private var live_layoutSetted = "live_layoutSetted"

extension MMLayoutProtocol {
    public var mmLayoutSettedObser: BehaviorSubject<Bool?> {
        get {
            if let object = objc_getAssociatedObject(self, &live_layoutSetted) as? BehaviorSubject<Bool?> {
                return object
            }else {
                let obser:BehaviorSubject<Bool?> = BehaviorSubject<Bool?>(value:nil)
                objc_setAssociatedObject(self, &live_layoutSetted, obser, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return obser
            }
        }
    }
}
