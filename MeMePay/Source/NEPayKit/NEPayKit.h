//
//  NEPayKit.h
//  NEPayKit
//
//  Created by FengMengtao on 2018/7/31.
//  Copyright © 2018年 meme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NEPayTypeDef.h"
#import <StoreKit/StoreKit.h>
#import "NEIAP.h"

extern NSString * const NEPayChannelEnumToString(NEPayChannel Key);

@protocol NEPayDelegate <NSObject>

#pragma mark - IAP delegate


/**
 des: 从苹果查询商品完成回调
 - parameter products: 返回的商品信息 参数可为空
 - parameter error: 这过程发生的错误信息
 */
- (void)appleIAPProductsLoaded: (nullable NSArray<SKProduct *> *)products
                    requestKey: (nullable NSString *)requestKey
                         error: (nullable NSError *)error;
@optional
- (void)startReSolveLastUnfinishedOrder: (NEPayOrderItem *_Nonnull)item;

- (void)purchasedSuccess: ( NSInteger )toUserId
               productId:( NSString * _Nonnull )productId
             passthrough:( NSString * _Nonnull )passthrough
           transactionId:( NSString * _Nonnull )transactionId;
/**
 des: 从苹果支付完成，并需要自定义验签的，需要处理此回调
 - parameter transaction: 交易信息
 - parameter finish: 是否需要finish调当前苹果的transaction，自定义验签完成之后调用
 */
- (void)purchasedIAPProductVerify: (nullable NEPayOrderItem *)order
                      transaction: (nullable SKPaymentTransaction *)transaction
                           finish: (nullable FinishPurchasesCompletionBlock) finish;

- (void)purchasedIAPProductRestoreTransaction: (nullable SKPaymentTransaction *)Transaction;
- (void)purchasedIAPProductRestoreComplete;
- (void)purchasedIAPProductRestoreError;

#pragma mark - common

/**
 des: 支付完成回调；（成功；或失败；）
 - parameter response: 支付完成的回调
 - parameter channel: 支付渠道
 */
- (void)purchasedWithResponse: (nullable NEPayResponse *)response
                      channel: (NEPayChannel)channel
                   resultInfo:(NEPurchaseResultInfo)resultInfo;

@end




@interface NEPayKit : NSObject

@property (nullable, nonatomic, weak)     id <NEPayDelegate> delegate;

// 是否是获取 iOS7以上版本的 recepit的格式
@property (nonatomic, assign)   BOOL              iapReceiptiOS7HigherFormat;

// 用于自定义未完成订单的存储路径; 如果区分用户的话，需要传递不同的路径; 如果外部设置为nil或者不是有效的文件路径，那么则使用默认值
@property (nullable, nonatomic, copy)     NSURL            * cacheOrderPath;

@property (nonatomic, assign)   BOOL               enableListener;

#pragma mark - class method

+ (instancetype _Nonnull )shared;


#pragma mark - common method

- (void)setup;

- (BOOL)sovleLastFailedTransaction;

- (void)startPurchaseProduct: (NEPayOrderItem *_Nonnull)item
                  payChannel: (NEPayChannel)channel;

- (void)processOrderWithPaymentResult: (NSURL *_Nonnull)resultUrl
                              options: (NSDictionary<NSString*, id> *_Nullable)options;

- (void)cleanCache;


#pragma mark - AppleIAP method

- (void)loadAppleIAPProducts: (NSArray *_Nonnull)productIds
                  requestKey: (NSString *_Nullable)requestKey;

@end
