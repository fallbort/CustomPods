//
//  NEIAP.h
//  NEIAPKit
//
//  Created by zhang yinglong on 2017/10/19.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "NEIAPBlock.h"

#ifndef IAP
#define IAP [NEIAP shared]
#endif

@interface NEIAPPayInfo : NSObject
@property (nonatomic, assign) NSInteger myUserId;
@property (nonatomic, strong) NSString *productId;
@property (nonatomic, strong) NSString *extInfo;
@property (nonatomic, strong) NSString *transactionIdentifier;

- (NSString*)toString;

@end


static NSString * NEIAPDomainName = @"NEIAPKit";

@interface NEIAP : NSObject

+ (NEIAP *)shared;

// 恢复订单
@property (nonatomic, copy) RestorePurchasesTransactionBlock restoreTransactionBlock;

// 恢复购买成功回调
@property (nonatomic, copy) RestorePurchasesCompletionBlock restoreCompletionBlock;

// 恢复购买失败回调
@property (nonatomic, copy) ErrorBlock restoreErrorBlock;

// 验签回调(不自定义将会默认使用自签)
@property (nonatomic, copy) VerifyCompletionBlock verify;

// 购买状态变更回调
@property (nonatomic, copy) PurchaseStateDidChangeBlock purchaseStateDidChange;
// 购买成功立即回调
@property (nonatomic, copy) PurchaseSuccessBlock purchaseSuccessBlock;

// 是否能进行购买
@property (nonatomic, readonly) BOOL canPurchase;

// 开启支付监听
@property (nonatomic, assign) BOOL enable;

@property (nonatomic, strong) NEIAPPayInfo *curPayInfo;

@property (nonatomic, strong) NSMutableDictionary<NSString*,NEIAPPayInfo*> *payInfoList;

#pragma mark Product Information

/**
 * passes a set of products to the completion block
 * if an error occurs, `err` is called with the error object (which is potentially nil)
 */
- (void)getProductsForIds:(NSSet<NSString *> *)productIds
               requestKey:(NSString *)requestKey
               completion:(ProductsCompletionBlock)completionBlock
                    error:(ProductsErrorBlock)errorBlock;

#pragma mark Purchase

// 解决上一次执行失败的transaction
- (BOOL)sovleLastFailedTransaction;

/// if an error occurs, `err` is called with the error object (which is potentially nil)
- (void)purchaseProduct:(SKProduct *)product
                extInfo:(NSString *)extInfo
             completion:(PurchaseCompletionBlock)completionBlock
                  error:(PurchaseErrorBlock)err;

- (void)purchaseProductForId:(NSString *)productId
                     extInfo:(NSString *)extInfo
                  completion:(PurchaseCompletionBlock)completionBlock
                       error:(PurchaseErrorBlock)err;

#pragma mark restore

- (void)restorePurchases;

- (void)restorePurchasesWithCompletion:(RestorePurchasesCompletionBlock)completionBlock;

- (void)restorePurchasesWithCompletion:(RestorePurchasesCompletionBlock)completionBlock error:(ErrorBlock)err;

- (void)endPayInfo;

@end
