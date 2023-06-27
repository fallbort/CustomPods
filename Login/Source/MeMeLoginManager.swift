//
//  MeMeLoginManager.swift
//  MeMeCustomPods
//
//  Created by xfb on 2023/6/27.
//

import Foundation
import MeMeKit

@objc public class MeMeLoginManager : NSObject {
    @objc public static let shared = MeMeLoginManager()
    //MARK: <>外部变量
    
    //MARK: <>外部block
    
    
    //MARK: <>生命周期开始
    override init() {
        super.init()
        
    }
    //MARK: <>功能性方法
    
    //MARK: <>内部View
    
    //MARK: <>内部UI变量
    //MARK: <>内部数据变量
    lazy var loginkeeper = CellStatusKeeper<LoginType,Any>()
    
    //MARK: <>内部block
    
}
