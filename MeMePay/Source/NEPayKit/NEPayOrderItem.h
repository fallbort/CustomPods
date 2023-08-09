//
//  NEPayOrderItem.h
//  NEPaySDK
//
//  Created by FengMengtao on 2018/7/24.
//  Copyright © 2018年 meme. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct;

@interface NEPayOrderItem : NSObject

@property (nullable, nonatomic, copy)      NSString *productId;     // 商品id
@property (nonatomic, assign)    double    price;                   // 商品价格
@property (nullable, nonatomic, copy)      NSString *preorderId;    // 服务端的预订单id

@property (nullable, nonatomic, copy)      NSString *orderId;       // 订单id
@property (nullable, nonatomic, copy)      NSString *currentUserId; // 当前用户id

//@property (nonatomic, assign)    NEPayChannel  channel;   // 支付渠道

// ************************ 主要用户Apple IAP的支付 *******************
@property (nonatomic, assign)    BOOL      isRestoreFromLastFailedOrder; // 用于判断是否为上次失败订单
@property (nullable, nonatomic, strong)    SKProduct *product;                     // iap商品信息  用于直接purchase，如果没有此项，需要先load商品信息，然后才purcahse，所以此字段最好要传
@property (nullable, nonatomic, copy)      NSString *iapRecepit;         // 存储订单recepit
@property (nullable, nonatomic, copy)      NSString *currency;           // 货币类型

@property (nonatomic, assign)      BOOL isSubscribePay;           // 是否是订阅类型

// ************************ 扩展字段 *********************************
@property (nullable, nonatomic, copy)      NSString *extension;     // 验签密钥
@property (nullable, nonatomic, copy)      NSString *extensionString;     // 扩展
@property (nullable, nonatomic, copy)      NSDictionary<NSString*,id> *subscribeExtension;     //订阅业务附带的信息，目前只用户restoreInfo



@end
