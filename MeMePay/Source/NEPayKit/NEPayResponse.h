//
//  NEPayResponse.h
//  NEPayKit
//
//  Created by FengMengtao on 2018/7/31.
//  Copyright © 2018年 meme. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NEPayResponseCode) {
    ResponseCode_Success = 0,
    ResponseCode_RequestParamsError = 1,
    ResponseCode_GetIAPProductFailed = 2,
    ResponseCode_IAPCantMakePurchase = 3,
    ResponseCode_Canceled = 4,
    ResponseCode_Repeat = 5,
    ResponseCode_IAPPurchasedFail = 6,
    ResponseCode_VerifyFailedOther = 7,
    ResponseCode_Unknown = 8
};

@interface NEPayResponse : NSObject

@property (nonatomic, assign) NEPayResponseCode  code;    // 返回错误码；为0是成功，非0失败；

@property (nonatomic, assign) NSInteger   errorCode;      // sdk返回的错误码
@property (nonatomic, copy)   NSString   *errorMessage;   // sdk返回错误信息描述；

// ************************ 需要用到的数据 *************************
@property (nonatomic, copy)   NSString   *productId;      // 商品id
@property (nonatomic, copy)   NSString   *orderId;        // 商户订单id
@property (nonatomic, copy)   NSString   *paySDKOrderId;  // 三方订单id
@property (nonatomic, assign) double      totalAmount;    // 该笔订单的资金总金额
@property (nonatomic, copy)   NSString   *currency;       // 付款货币类型
@property (nonatomic, copy)   NSString   *sellerId;       // 收款账号对应的唯一用户号
@property (nonatomic, assign) NSString   *timeStamp;      // 交易发生时间字符串格式

@end
