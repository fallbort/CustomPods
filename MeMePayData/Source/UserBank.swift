//
//  UserBank.swift
//  LiveStream
//
//  Created by 邢海华 on 16/6/22.
//  Copyright © 2016年 sip. All rights reserved.
//

import ObjectMapper

public struct UserBank: Mappable, CustomStringConvertible {
    public var tickets = 0
    public var depositCount = 0
    public var balance:Int? // --只查询有自己才有

	public init() { }

	public init?(map: Map) {
	}

	mutating public func mapping(map: Map) {
		tickets <- map["tickets"]
		balance <- map["diamond"]
        depositCount <- map["depositCount"]
	}

    public var description: String {
		return "UserBank[tickets=\(tickets),balance=\(balance),depositCount=\(depositCount)]"
	}
}
