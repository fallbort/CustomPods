//
//  MMPayConfig.swift
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/9.
//

import Foundation
import MeMeKit
import Result

public enum MMPayRequestType {
    case payList  //档位列表
    case deposit //验签接口
    case preOrder //预购买
    
}

@objc public class MMPayConfig : NSObject {
    
    //MARK: <>外部变量
    
    //MARK: <>外部block
    
    
    //MARK: <>生命周期开始

    //MARK: <>功能性方法
    //通用请求接受返回值
    public static var requestBlock:((_ type:MMPayRequestType,_ params:[String:Any],_ complete:((Result<Any, MemeCommonError>)->())?)->()) = {_,_,_  in return}
    //更新货币
    public static var balanceChangedBlock:((_ balance:Int?)->()) = {_ in return}
    
    //MARK: <>内部View
    
    //MARK: <>内部UI变量
    //MARK: <>内部数据变量
    
    //MARK: <>内部block
    
}
