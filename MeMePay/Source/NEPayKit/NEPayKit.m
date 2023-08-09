//
//  NEPayKit.m
//  NEPaySDK
//
//  Created by FengMengtao on 2018/7/20.
//  Copyright © 2018年 meme. All rights reserved.
//

#import "NEPayKit.h"
#import <YYModel/YYModel.h>

//定义字符串函数
NSString * const NEPayChannelEnumToString(NEPayChannel Key) {    
    switch (Key) {
        case NEPayChannel_AppleIAP:
            return @"appleiap";
        default:
            return @"";
    }
}

@interface NEPayKit()

@property (nonatomic, strong) NEIAP *iapManager;
@property (nonatomic, strong) NSMutableArray<NEPayOrderItem  *> *orders;  //用于记录iap购买的商品订单
@property (nonatomic, strong) NSMutableDictionary *purchasedPlistContent; // 缓存订单内容
@end



@implementation NEPayKit

#pragma mark - class method

+ (instancetype)shared {
    static NEPayKit *shareInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shareInstance = [[NEPayKit alloc] init];
    });
    
    return shareInstance;
}

#pragma mark - instance method

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.iapManager = [NEIAP shared];
    }
    return self;
}

- (id)copy {
    return [NEPayKit shared];
}

- (BOOL)canIAPPurchase {
    return  [SKPaymentQueue canMakePayments];
}

- (void)startPurchaseProduct: (NEPayOrderItem *)item
                  payChannel: (NEPayChannel)channel {
    switch (channel) {
        case NEPayChannel_AppleIAP:
            [self purchaseProductByIAPWithOrder:item];
            break;
        default:
            break;
    }
}

- (void)processOrderWithPaymentResult: (NSURL *)resultUrl
                              options: (NSDictionary<NSString*, id> *)options {
    
}

// private method
- (void)finishPurchase: (NEPayResponse *)response
               channel: (NEPayChannel)channel
        fromUserAction: (BOOL)fromUserAction
            resultInfo: (NEPurchaseResultInfo)resultInfo {
    if (nil != self.delegate && [self.delegate respondsToSelector:@selector(purchasedWithResponse:channel:resultInfo:)]) {
        if (fromUserAction == YES) {
            [self.delegate purchasedWithResponse:response channel:channel resultInfo:resultInfo];
        }
    }
}

#pragma mark - IAP

- (void)setup {
    
    self.orders = [[NSMutableArray alloc] init];
    self.cacheOrderPath = [NEPayKit defaultCacheOrderFileURL];
    self.purchasedPlistContent = [NSMutableDictionary dictionaryWithContentsOfURL:[NEPayKit defaultCacheOrderFileURL]];
    
    __weak typeof(self) weakSelf = self;
    self.iapManager.restoreTransactionBlock = ^(SKPaymentTransaction *transaction) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (nil != strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(purchasedIAPProductRestoreTransaction:)]) {
            [strongSelf.delegate purchasedIAPProductRestoreTransaction:transaction];
        }
    };
    
    self.iapManager.restoreCompletionBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (nil != strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(purchasedIAPProductRestoreComplete)]) {
            [strongSelf.delegate purchasedIAPProductRestoreComplete];
        }
    };
    
    self.iapManager.restoreErrorBlock = ^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (nil != strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(purchasedIAPProductRestoreError)]) {
            [strongSelf.delegate purchasedIAPProductRestoreError];
        }
    };
    
    self.iapManager.verify = ^(SKPaymentTransaction *transaction, FinishPurchasesCompletionBlock finish) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        // 验签这块，需要分两种情况考虑：1.能从当前订单中查到；2.和不能从当前订单列表中查到；
        NSString *productId = transaction.payment.productIdentifier;
        NSString *transactionId = transaction.transactionIdentifier;
        NSString *origin_transactionId = transaction.originalTransaction.transactionIdentifier;
        if (origin_transactionId == nil || origin_transactionId.length == 0) { //有可能是空的
            origin_transactionId = transactionId;
        }
        NSString * appleJsonString = transaction.payment.applicationUsername;
        NSString *orderInfoJsonString = appleJsonString;
        if (origin_transactionId != nil) {
            if (orderInfoJsonString == nil || orderInfoJsonString.length == 0) {
                NEIAPPayInfo* payInfo = [[NEIAP shared].payInfoList valueForKey:origin_transactionId];
                if (payInfo.productId != nil && [productId isEqualToString: payInfo.productId] == YES) {
                    orderInfoJsonString = payInfo.extInfo;
                }
            }
        }
        
        NEPayOrderItem *currentOrderItem;
        
        if (currentOrderItem == nil) {
            // 如果是空，则需要初始化
            currentOrderItem = [strongSelf getOrderFrom:orderInfoJsonString];
        }
        
        currentOrderItem.orderId = transactionId;  // 保存订单id
        currentOrderItem.productId = productId;
        
        // 查询recepit，并保存在orderItem里面
        NSString *receiptData = [strongSelf getReceiptData:transaction];
        currentOrderItem.iapRecepit = receiptData;
        
        // 如果订单是存在的，那么调用回调进行验签；
        if (nil != strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(purchasedIAPProductVerify:transaction:finish:)]) {
            [strongSelf.delegate purchasedIAPProductVerify:currentOrderItem transaction: transaction finish:finish];
        }
        
        if (!currentOrderItem) {
            // 如果找不到此账单，说明是一个坏账。如何处理，交给上层。
            NEPayKitDLog(@"NEPayKit: iap purchased can't find the right order item. The order item is broken.");
        }
    };
    
    self.iapManager.purchaseSuccessBlock =  ^(NSInteger toUserId,NSString * productId,NSString* passthrough,NSString* transactionId) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (nil != strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(purchasedSuccess:productId:passthrough:transactionId:)]) {
            [strongSelf.delegate purchasedSuccess:toUserId productId:productId passthrough:passthrough transactionId:transactionId];
        }
    };
    
    self.iapManager.purchaseStateDidChange = ^(NSString *productId, NSString *orderId,BOOL fromUserAction, NEPurchaseState state,NEPurchaseResultInfo resultInfo) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL success = NO;
        
        NEPayResponse *response = [[NEPayResponse alloc] init];
        response.productId = productId;
        response.orderId = orderId;
        
        switch (state) {
            case NEPurchaseStateFailed:
                response.code = ResponseCode_IAPPurchasedFail;
                break;
            case NEPurchaseStatePurchased:
                response.code = ResponseCode_Success;
                break;
            case NEPurchaseStateVerifyFailed:
                response.code = ResponseCode_VerifyFailedOther;
                break;
            default:
                return;
        }
        
        [strongSelf finishPurchase:response channel:NEPayChannel_AppleIAP fromUserAction:fromUserAction resultInfo:resultInfo];
        
    };
}

- (void)setEnableListener:(BOOL)enableListener {
    self.iapManager.enable = enableListener; // 在我们的代理都设置完好之后，再开启苹果的未完成订单回调功能。
}

- (BOOL)sovleLastFailedTransaction {
    return [self.iapManager sovleLastFailedTransaction];
}

- (void)cleanCache {
    [self.orders removeAllObjects];
    self.purchasedPlistContent = nil;
}

- (void)loadAppleIAPProducts: (NSArray *)productIds requestKey: (NSString *)requestKey {
    
    __weak typeof(self) weakSelf = self;
    NSSet *products = [[NSSet alloc] initWithArray:productIds];
    
    [[NEIAP shared] getProductsForIds:products requestKey:requestKey completion:^(NSArray<SKProduct *> *products, NSString *requestKey) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (nil != strongSelf && nil != strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(appleIAPProductsLoaded:requestKey:error:)]) {
                    [strongSelf.delegate appleIAPProductsLoaded:products requestKey:requestKey error:nil];
                }
            });
        } else {
            if (nil != strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(appleIAPProductsLoaded:requestKey:error:)]) {
                [strongSelf.delegate appleIAPProductsLoaded:products requestKey:requestKey error:nil];
            }
        }
    } error:^(NSError *error, NSString *requestKey) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (nil != strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(appleIAPProductsLoaded:requestKey:error:)]) {
            [strongSelf.delegate appleIAPProductsLoaded:nil requestKey:requestKey error:error];
        }
    }];
}

- (void)purchaseProductByIAPWithOrder: (NEPayOrderItem *)order {
    __weak typeof(self) weakSelf = self;
    
    SKProduct *product = order.product;
    
    // 这里skProduct不参与json string的转化
    order.product = nil;
    NSString *orderJsonString = order.yy_modelToJSONString;
    
    if (product != nil) {
        [[NEIAP shared] purchaseProduct: product
                                extInfo: orderJsonString
                             completion:^(SKPaymentTransaction *transaction,BOOL isRepeat) {
//            __strong typeof(weakSelf) strongSelf = weakSelf;
            
//            NEPayResponse *response = [[NEPayResponse alloc] init];
//            response.code = ResponseCode_Success;
//            response.productId = order.productId;
//            response.orderId = transaction.transactionIdentifier;
//            [strongSelf finishPurchase:response channel:NEPayChannel_AppleIAP];
        } error:^(NSString *productId, SKPaymentTransaction *transaction, NSError *error, NEPurchaseState onState,NEPurchaseResultInfo resultInfo) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NEPayResponse *response = [[NEPayResponse alloc] init];
            response.productId = productId;
            response.orderId = transaction.transactionIdentifier;
            if(error != nil && [error.domain isEqualToString:NEIAPDomainName]) {
                if(error.code == NEPurchaseErrorCantMakePayment) {
                    response.code = ResponseCode_IAPCantMakePurchase;
                } else if (error.code == NEPurchaseErrorNoProductId) {
                    response.code = ResponseCode_GetIAPProductFailed;
                }
                [strongSelf finishPurchase:response channel:NEPayChannel_AppleIAP fromUserAction:YES resultInfo:resultInfo];
            }
        }];
    } else {
        [[NEIAP shared] purchaseProductForId:order.productId
                                     extInfo:orderJsonString
                                  completion:^(SKPaymentTransaction *transaction,BOOL isRepeat) {
//            __strong typeof(weakSelf) strongSelf = weakSelf;
//            
//            NEPayResponse *response = [[NEPayResponse alloc] init];
//            response.code = ResponseCode_Success;
//            response.productId = order.productId;
//            response.orderId = transaction.transactionIdentifier;
//            [strongSelf finishPurchase:response channel:NEPayChannel_AppleIAP];
        } error:^(NSString *productId, SKPaymentTransaction *transaction, NSError *error, NEPurchaseState onState,NEPurchaseResultInfo resultInfo) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NEPayResponse *response = [[NEPayResponse alloc] init];
            response.productId = productId;
            response.orderId = transaction.transactionIdentifier;
            if(error != nil && [error.domain isEqualToString:NEIAPDomainName]) {
                if(error.code == NEPurchaseErrorCantMakePayment) {
                    response.code = ResponseCode_IAPCantMakePurchase;
                } else if (error.code == NEPurchaseErrorNoProductId) {
                    response.code = ResponseCode_GetIAPProductFailed;
                }
                [strongSelf finishPurchase:response channel:NEPayChannel_AppleIAP fromUserAction:YES resultInfo:resultInfo];
            }
        }];
    }
}

#pragma mark - IAP Order related

-(NEPayOrderItem *)getOrderFrom: (NSString *)jsonString {
    if (nil == jsonString) {
        return [[NEPayOrderItem alloc] init];
    }
    
    NEPayOrderItem *item = [[NEPayOrderItem alloc] init];
    [item yy_modelSetWithJSON:jsonString];
    
    return item;
}

/*
 * disc: 获取当前的receipt
 */
- (NSString *)getReceiptData:(SKPaymentTransaction *)transaction {
    NSData *receiptData;
    // 现在服务端不支持 iOS7格式的
    if (self.iapReceiptiOS7HigherFormat && NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    } else {
        receiptData = transaction.transactionReceipt;
    }
    NSString *jsonObjectString = [receiptData base64EncodedStringWithOptions:0];
    
    return jsonObjectString;
}


-(NEPayOrderItem *)getCurrentOrder: (NSString *)productId {
    if (nil == productId || nil == self.orders || self.orders.count <= 0) {
        return nil;
    }
    
    NSArray *resultObjects = [self.orders filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"productId == %@", productId]];
    if (resultObjects != nil && resultObjects.count > 0) {
        return resultObjects.firstObject;
    }
    
    return nil;
}

- (void)setCacheOrderPath:(NSURL *)cacheOrderPath {
    
    BOOL isValidPath = YES;
    
    if (nil != cacheOrderPath) {
        isValidPath = NO;
    } else {
        NSURL *folder = cacheOrderPath.URLByDeletingLastPathComponent;
        if (![[NSFileManager defaultManager] fileExistsAtPath:folder.path]) {
            NSError *error = nil;
            BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:folder.path withIntermediateDirectories:YES attributes:nil error:&error];
            if (!success || nil != error) {
                NEPayKitDLog(@"file create dir failed in setCacheOrderPath. error message:%@", error.localizedDescription);
                isValidPath = false;
            }
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:cacheOrderPath.path]) {
            BOOL success = [[NSFileManager defaultManager] createFileAtPath:cacheOrderPath.path contents:nil attributes:nil];
            if (!success) {
                isValidPath = false;
            }
        }
    }
    
    if (!isValidPath) {
        // 自定义设置缓存订单路径
        _cacheOrderPath = [NEPayKit defaultCacheOrderFileURL];
        self.purchasedPlistContent = [NSMutableDictionary dictionaryWithContentsOfURL:_cacheOrderPath];
    } else {
        // 如果自定义缓存不生效，则设置默认的缓存订单路径
        _cacheOrderPath = cacheOrderPath;
        self.purchasedPlistContent = [NSMutableDictionary dictionaryWithContentsOfURL:[NEPayKit defaultCacheOrderFileURL]];
    }
}

/*
 * 加载最后一个失败订单，并进行重新购买
 */
- (NEPayOrderItem *)findUnfinishedOrder: (NSString *)orderId {
    if (!self.purchasedPlistContent) {
        // 如果purchasedPlistContent为空，说明没有失败订单
        return nil;
    }
    
    NSString *base64EncodeString = [self.purchasedPlistContent objectForKey:orderId];
    NEPayOrderItem *item = [self getFailedOrder:base64EncodeString];
    
    return item;
}

- (NEPayOrderItem *)getFailedOrder:(NSString *)base64EncodeString {
    if (nil == base64EncodeString) {
        return nil;
    }
    NSData *base64DecodeData = [[NSData alloc] initWithBase64EncodedString:base64EncodeString options:(NSDataBase64DecodingOptions)0];
    NSString *string = [[NSString alloc] initWithData:base64DecodeData encoding:NSUTF8StringEncoding];
    if (string) {
        NEPayOrderItem *item = [[NEPayOrderItem alloc] init];
        [item yy_modelSetWithJSON:string];
        return item;
    }

    return nil;
}

/**
 * des: 替换失败订单到内存和硬盘，主要用于被SKPaymentTransactionStateRestored 的订单；
 * \param orderInfo SCProductCacheItem 订单信息
 */
- (void)saveCacheOrderInfo:(NEPayOrderItem *)orderInfo {
    if (orderInfo == nil) {
        return;
    }
    NSString *orderJsonString = orderInfo.yy_modelToJSONString;
    NSData *orderJsonData = [orderJsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64EncodeString = [orderJsonData base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];

    if (self.purchasedPlistContent) {
        self.purchasedPlistContent[orderInfo.orderId] = base64EncodeString;
    } else {
        self.purchasedPlistContent = [NSMutableDictionary dictionaryWithObjectsAndKeys:base64EncodeString, orderInfo.orderId, nil];
    }

    [self updateFailedOrderCacheIntoHardDisk];
}

/*
 * disc: 从本地缓存中删除某个订单
 - parameter transactionId: 订单id
 */
- (void)removeOrderInCache:(NSString *)transactionId {
    if (nil == transactionId) {
        return;
    }
    // 删除当前缓存
    [self.purchasedPlistContent removeObjectForKey:transactionId];
    
    // 更新硬盘
    [self updateFailedOrderCacheIntoHardDisk];
}

/*
 * disc: 更新内存失败订单到硬盘
 */
- (void)updateFailedOrderCacheIntoHardDisk {
    if (nil == self.purchasedPlistContent || nil == self.cacheOrderPath) {
        return;
    }
    
    BOOL success = [self.purchasedPlistContent writeToURL:self.cacheOrderPath atomically:YES];
    if (!success) {
        NEPayKitDLog(@"Saving purchases to %@ failed!", self.cacheOrderPath.path);
    }
}

#pragma mark - product cache order patch

/*
 * disc: 默认的失败订单缓存文件夹地址
 */
+ (NSURL *)defaultCacheOrderFolderURL {
    NSURL *appDocDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *paykitFolder = [appDocDir URLByAppendingPathComponent:@"paykit" isDirectory:YES];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:paykitFolder.path]) {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:paykitFolder.path withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success || nil != error) {
            NEPayKitDLog(@"file create dir failed. error message:%@", error.localizedDescription);
            return nil;
        }
    }
    return paykitFolder;
}

/*
 * disc: 默认的失败订单缓存文件地址
 */
+ (NSURL *)defaultCacheOrderFileURL {
    NSURL *cacheOrderFolder = [NEPayKit defaultCacheOrderFolderURL];
    if (cacheOrderFolder == nil) {
        return nil;
    }
    
    NSString *fileName = @"paykit_purchasedProduct.plist";
    NSURL *cacheOrderFileUrl = [cacheOrderFolder URLByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheOrderFileUrl.path]) {
        BOOL success = [[NSFileManager defaultManager] createFileAtPath:cacheOrderFileUrl.path contents:nil attributes:nil];
        if (!success) {
            NEPayKitDLog(@"file create file failed.");
            return nil;
        }
    }
    
    return cacheOrderFileUrl;
}

@end
