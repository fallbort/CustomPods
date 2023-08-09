//
//  NEIAPBlock.h
//  NEIAPKit
//
//  Created by zhang yinglong on 2017/10/19.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#ifndef NEIAPBlock_h
#define NEIAPBlock_h

#import <StoreKit/StoreKit.h>

typedef NS_ENUM(NSInteger, NEPurchaseState) {
    NEPurchaseStateIdle,        // 初始化状态
    NEPurchaseStateProducting,  // 获取商品信息中
    NEPurchaseStatePurchasing,  // 购买中
    NEPurchaseStateVerifing,    // 支付中
//    NEPurchaseStateCancel,      // 取消购买 // 根本没法知道，到底是不是取消的，只能知道是失败的订单
    NEPurchaseStatePurchased,   // 购买成功
    NEPurchaseStateVerifyFailed,// 验签失败
    NEPurchaseStateFailed,       // 购买失败
    NEPurchaseStateRestoredPurchased   // 恢复订单处理成功
};

typedef NS_ENUM(NSInteger, NEPurchaseResultInfo) {
    NEPurchaseResultNone,            //无信息
    NEPurchaseResultIsRepeat,        // 是重复订单
    NEPurchaseResultRestore,         //恢复订单处理
};

typedef NS_ENUM(NSInteger, NEPurchaseError) {
    NEPurchaseErrorCantMakePayment = 0,        // 初始化状态
    NEPurchaseErrorNoProductId = 1,
};

typedef void(^PurchaseCompletionBlock)(SKPaymentTransaction *transaction,BOOL isRepeat);
typedef void(^ProductsCompletionBlock)(NSArray <SKProduct*> *products, NSString *requestKey);
typedef void(^PurchaseStateDidChangeBlock)(NSString *productId, NSString *orderId,BOOL fromUserAction, NEPurchaseState state,NEPurchaseResultInfo resultInfo);
typedef void(^PurchaseSuccessBlock)(NSInteger toUserId,NSString *productId, NSString *passthrough, NSString* transactionId);
typedef void(^ProductsErrorBlock)(NSError *error, NSString *requestKey);
typedef void(^ErrorBlock)(NSError *error);
typedef void(^PurchaseErrorBlock)(NSString *productId, SKPaymentTransaction *transaction, NSError *error, NEPurchaseState onState,NEPurchaseResultInfo resultInfo);
typedef void(^RestorePurchasesCompletionBlock)(void);
typedef void(^FinishPurchasesCompletionBlock)(BOOL,BOOL);
typedef void(^FinishRestoreTransactionCompletionBlock)(BOOL);
typedef void(^VerifyCompletionBlock)(SKPaymentTransaction *transaction, FinishPurchasesCompletionBlock finish);
typedef void(^RestorePurchasesTransactionBlock)(SKPaymentTransaction *transaction);

#endif /* NEIAPBlock_h */
