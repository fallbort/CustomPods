//
//  NEIAP.m
//  NEIAPKit
//
//  Created by zhang yinglong on 2017/10/19.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "NEIAP.h"
#include <netdb.h>
#import "SKPaymentQueue+Ext.h"
#import "SKProductsRequest+Ext.h"
#import "SKProduct+Ext.h"
#import "SKPaymentTransaction+Ext.h"
@import YYModel;
@import MeMeKit;
#import "NEPayOrderItem.h"


@implementation NEIAPPayInfo
@synthesize productId,extInfo,transactionIdentifier,myUserId;

- (NSString*)toString {
    NSDictionary* dict = [self toDict];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:0];
    NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return dataStr;
}

+ (nullable instancetype)fromString:(NSString*)value {
    if (value == nil) {
        return nil;
    }
    if (value != nil && value.length > 0) {
        NSData *jsonData = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                            options:NSJSONReadingMutableContainers
                                                              error:&err];
        if(err) {
            return nil;
        }
        return [NEIAPPayInfo fromDict:dict];
    }else{
        return nil;
    }
}

-(NSDictionary*)toDict {
    NSMutableDictionary<NSString*,id>* object = [[NSMutableDictionary alloc] init];
    [object setValue:productId forKey:@"productId"];
    [object setValue:extInfo forKey:@"extInfo"];
    [object setValue:transactionIdentifier forKey:@"transactionIdentifier"];
    [object setValue:[NSNumber numberWithInt:myUserId] forKey:@"myUserId"];
    return object;
}

+(nullable instancetype)fromDict:(NSDictionary*) dict {
    if (dict != nil && [dict valueForKey:@"productId"] != nil) {
        NEIAPPayInfo* info = [[NEIAPPayInfo alloc] init];
        info.productId = [dict valueForKey:@"productId"];
        info.extInfo = [dict valueForKey:@"extInfo"];
        info.transactionIdentifier = [dict valueForKey:@"transactionIdentifier"];
        info.myUserId = [(NSNumber*)[dict valueForKey:@"myUserId"] intValue];
        return info;
    }
    
    return nil;
}

@end

@interface NEIAP () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

// 缓存已购买成功商品id
@property (nonatomic, strong) NSMutableArray *purchasedItems;
@property (nonatomic, strong) SKPaymentTransaction *currentTransaction;
@property (nonatomic, strong) NSMutableDictionary *iapCacheRequests;

@property (nonatomic, strong) NSMutableArray<NSString*> *needRemovePayKeys;
@property (nonatomic, assign) BOOL payInfoLoaded;
@property (nonatomic, assign) BOOL payInfoChanged;

@property (atomic, strong) NSLock *dataLock;

@end

NSURL *purchasesURL() {
    NSURL *appDocDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [appDocDir URLByAppendingPathComponent:@".purchases.plist"];
}

// simple reachability. Could also use one of the various Reachability Cocoapods, but why bother when it's so simple?
BOOL checkAppStoreAvailable() {
    const char *hostname = "appstore.com";
    struct hostent *hostinfo = gethostbyname(hostname);
    if (hostinfo == NULL) {
#ifdef DEBUG
        NSLog(@"-> no connection to App Store!\n");
#endif
        struct hostent *hostinfo2 = gethostbyname2(hostname, AF_INET6);
        if (hostinfo2 == NULL) {
            return NO;
        }
    }
    return YES;
}

@implementation NEIAP

+ (NEIAP *)shared {
    static NEIAP *sharedInstance;
    if(sharedInstance == nil) sharedInstance = [NEIAP new];
    return sharedInstance;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if ( self ) {
        self.purchasedItems = [NSMutableArray arrayWithContentsOfURL:purchasesURL()];
        if(self.purchasedItems == nil) {
            self.purchasedItems = [NSMutableArray array];
        }
        self.iapCacheRequests = [[NSMutableDictionary alloc] init];
        self.needRemovePayKeys = [[NSMutableArray alloc] init];
        [self loadPayInfoWithForce:NO];
        self.dataLock = [[NSLock alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        
    }
    return self;
}

- (void)appDidEnterBackground:(NSNotification *)note {
    [self savePayInfo];
}

- (void)willTerminate:(NSNotification *)note {
    [self endPayInfo];
}

- (void)loadPayInfoWithForce:(BOOL)force {
    if (self.payInfoLoaded == NO) {
        if (force == YES) {
            self.payInfoList = [self realLoadPayInfo];
            self.payInfoLoaded = YES;
        }else{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSMutableDictionary<NSString*,NEIAPPayInfo*>* infoList = [self realLoadPayInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.payInfoLoaded == NO) {
                        self.payInfoList = infoList;
                        self.payInfoLoaded = YES;
                    }
                });
            });
        }
    }
}

-(NSMutableDictionary<NSString*,NEIAPPayInfo*>*)realLoadPayInfo {
    NSString* storageUrl = [self storageUrl];
    NSDictionary* sourceDict = [NSDictionary dictionaryWithContentsOfFile:storageUrl];
    NSMutableDictionary<NSString*,NEIAPPayInfo*>* dict = [[NSMutableDictionary alloc] init];
    if (sourceDict != nil) {
        for (NSString* key in sourceDict) {
            NSDictionary* infoDict = sourceDict[key];
            NEIAPPayInfo* info = [NEIAPPayInfo fromDict:infoDict];
            if (info != nil) {
                dict[key] = info;
            }
        }
    }
    return dict;
}

-(void)setNeedStore:(BOOL)flush {
    if (flush == YES) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self savePayInfo];
//        });
        [self savePayInfo];
    }else{
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(savePayInfo) withObject:nil afterDelay:3.0];
    }
    
}

- (void)savePayInfo {
    if (self.payInfoList != nil && self.payInfoChanged == YES) {
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
        for (NSString* key in self.payInfoList) {
            NEIAPPayInfo* info = self.payInfoList[key];
            NSDictionary* infoDict = [info toDict];
            dict[key] = infoDict;
        }
        NSString* storageUrl = [self storageUrl];
        [dict writeToFile:storageUrl atomically:YES];
        self.payInfoChanged = NO;
    }
}

- (void)endPayInfo {
    for (NSString* key in self.needRemovePayKeys) {
        if (self.payInfoList != nil) {
            [self.payInfoList removeObjectForKey:key];
            self.payInfoChanged = YES;
        }
    }
    [self savePayInfo];
}

-(NSString*) storageUrl {
    NSURL* libraryUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL* payInfoUrl = [libraryUrl URLByAppendingPathComponent:@"payInfo"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:payInfoUrl.path] == NO) {
        @try {
            [[NSFileManager defaultManager] createDirectoryAtPath:payInfoUrl.path withIntermediateDirectories:false attributes:nil error:NULL];
        } @catch (NSException *exception) {
            
        } @finally {
           
        }
        
    }
    NSURL* payInfoFile = [payInfoUrl URLByAppendingPathComponent:@"payInfoFile"];
    return payInfoFile.path;
}

- (BOOL)canPurchase {
    return [SKPaymentQueue canMakePayments];
}

- (void)setEnable:(BOOL)enable {
    if (_enable == enable) {
        return;  // 如果值一样，则不执行任何逻辑，直接return；
    }
    _enable = enable;
    if ( _enable ) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [self traceObjcIAPPaymentStatusWithStep:201
                                      productId:@""
                                     serverJson:@""
                                  transactionId:@""
                                       errorStr:@"addTransactionObserver"
                                      errorCode:-1];
    } else {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
        [self traceObjcIAPPaymentStatusWithStep:201
                                      productId:@""
                                     serverJson:@""
                                  transactionId:@""
                                       errorStr:@"removeTransactionObserver"
                                      errorCode:-1];
    }
}

- (void)savePurchasedItems {
    BOOL success = [self.purchasedItems writeToURL:purchasesURL() atomically:YES];
    if (!success) {
        NSLog(@"Saving purchases to %@ failed!", purchasesURL());
        [self traceObjcIAPPaymentStatusWithStep:202
                                      productId:@""
                                     serverJson:@""
                                  transactionId:@""
                                       errorStr:@"savePurchasedItemsFailed"
                                      errorCode:-1];
    } else {
        [self traceObjcIAPPaymentStatusWithStep:202
                                      productId:@""
                                     serverJson:@""
                                  transactionId:@""
                                       errorStr:@"savePurchasedItemsSucceed"
                                      errorCode:-1];
    }
}

#pragma mark - Product Information

- (void)getProductsForIds:(NSSet<NSString *> *)productIds
               requestKey:(NSString *)requestKey
               completion:(ProductsCompletionBlock)completionBlock
                    error:(ProductsErrorBlock)error
{
    if ( error == nil ) {
        error = ^(NSError *error, NSString *requestKey){};
    }
    
    SKProductsRequest *req = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
    req.productsCompletion = completionBlock;
    req.errBlock = error;
    req.delegate = self;
    
    // 将本次请求保存起来
    if (requestKey != nil) {
        [self.dataLock lock];
        [self.iapCacheRequests setObject:req forKey:requestKey];
        [self.dataLock unlock];
    }
    
    [req start];
    
//    if (self.purchaseStateDidChange) {
//        self.purchaseStateDidChange(NEPurchaseStateProducting);
//    }
}

#pragma mark -- SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if (request.productsCompletion) {
        NSString *resultKey = nil;
        [self.dataLock lock];
        NSArray *resultKeys = [self.iapCacheRequests allKeysForObject:request];
        if (resultKeys.count > 0) {
            resultKey = resultKeys.firstObject;
            [self.iapCacheRequests removeObjectForKey:resultKey];
        }
        [self.dataLock unlock];
        request.productsCompletion(response.products, resultKey);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if ([request isKindOfClass:SKProductsRequest.class]) {
        SKProductsRequest *req = (SKProductsRequest *)request;
        if (req.errBlock) {
            NSString *resultKey = nil;
            [self.dataLock lock];
            NSArray *resultKeys = [self.iapCacheRequests allKeysForObject:request];
            if (resultKeys.count > 0) {
                resultKey = resultKeys.firstObject;
                [self.iapCacheRequests removeObjectForKey:resultKey];
            }
            [self.dataLock unlock];
            req.errBlock(error, resultKey);
            
        }
    }
}

#pragma mark - Purchase

- (void)restorePurchases {
    [self restorePurchasesWithCompletion:nil];
}

- (void)restorePurchasesWithCompletion:(RestorePurchasesCompletionBlock)completionBlock {
    [self restorePurchasesWithCompletion:completionBlock error:nil];
}

- (void)restorePurchasesWithCompletion:(RestorePurchasesCompletionBlock)completionBlock
                                 error:(ErrorBlock)err {
    self.restoreCompletionBlock = completionBlock;
    self.restoreErrorBlock = err;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (BOOL)sovleLastFailedTransaction {
    if (self.currentTransaction) {
        // 恢复上次未完成订单
        [self paymentQueue:[SKPaymentQueue defaultQueue] updatedTransactions:@[self.currentTransaction]];
        
        NSString *serverJson = @"";
        NSString *productId = @"";
        if (self.currentTransaction.payment.productIdentifier != nil) {
            productId = self.currentTransaction.payment.productIdentifier;
        }
        NSString *transactionId = self.currentTransaction.transactionIdentifier;
        NSString *origin_transactionId = self.currentTransaction.originalTransaction.transactionIdentifier;
        if (origin_transactionId == nil || origin_transactionId.length == 0) { //有可能是空的
            origin_transactionId = transactionId;
        }
        NSString * appleJsonString = self.currentTransaction.payment.applicationUsername;
        NSString *orderInfoJsonString = appleJsonString;
        if (origin_transactionId != nil) {
            if (orderInfoJsonString == nil || orderInfoJsonString.length == 0) {
                NEIAPPayInfo* payInfo = [[NEIAP shared].payInfoList valueForKey:origin_transactionId];
                if (payInfo.productId != nil && [productId isEqualToString: payInfo.productId] == YES) {
                    orderInfoJsonString = payInfo.extInfo;
                }
            }
        }
        serverJson = orderInfoJsonString;
        
        [self traceObjcIAPPaymentStatusWithStep:27
                                      productId:productId
                                     serverJson:serverJson
                                  transactionId:self.currentTransaction.transactionIdentifier
                                       errorStr:@"sovleLastFailedTransaction"
                                      errorCode:-1];
        return true;
    }
    return false;
}

- (void)purchaseProduct:(SKProduct *)product
                extInfo:(NSString *)extInfo
             completion:(PurchaseCompletionBlock)completionBlock
                  error:(PurchaseErrorBlock)err
{
    if([self canPurchase]) {
        SKPaymentQueue *queue = [SKPaymentQueue defaultQueue];
        queue.purchaseCompletion = completionBlock;
        queue.errBlock = err;
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        payment.applicationUsername = extInfo;
        self.curPayInfo = [[NEIAPPayInfo alloc] init];
        self.curPayInfo.productId = product.productIdentifier;
        self.curPayInfo.extInfo = extInfo;
//        self.curPayInfo.myUserId = [NEUtilSwift getMyId];
        NSInteger userId = MeMeKitConfig.userIdBlock();
        self.curPayInfo.myUserId = userId;
        [queue addPayment:payment];
        
        if (self.purchaseStateDidChange) {
            self.purchaseStateDidChange(product.productIdentifier, nil,YES, NEPurchaseStatePurchasing,NEPurchaseResultNone);
        }
    } else {
        err(product.productIdentifier,
            nil,
            [NSError errorWithDomain:NEIAPDomainName
                                code:NEPurchaseErrorCantMakePayment
                            userInfo:@{NSLocalizedDescriptionKey: @"Can't make payments"}],
            NEPurchaseStatePurchasing,NEPurchaseResultNone);
    }
}

- (void)purchaseProductForId:(NSString *)productId
                     extInfo:(NSString *)extInfo
                  completion:(PurchaseCompletionBlock)completionBlock
                       error:(PurchaseErrorBlock)err
{
    if([self canPurchase]) {
        [self getProductsForIds:[NSSet setWithObject:productId]
                     requestKey: productId
                     completion:^(NSArray *products, NSString *requestKey)
        {
            if([products count] == 0) {
                err(productId,
                    nil,
                    [NSError errorWithDomain:NEIAPDomainName code:NEPurchaseErrorNoProductId
                                    userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Didn't find products with ID %@", productId]}],
                    NEPurchaseStatePurchasing,NEPurchaseResultNone);
            } else {
                [self purchaseProduct:products.firstObject
                              extInfo:extInfo
                           completion:completionBlock
                                error:err];
            }
        } error:^(NSError *error, NSString *requestKey) {
            err(productId, nil, [NSError errorWithDomain:NEIAPDomainName code:NEPurchaseErrorNoProductId
                                                userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Didn't find products with ID %@", productId]}], NEPurchaseStateProducting,NEPurchaseResultNone);
        }];
    } else {
        err(productId,
            nil,
            [NSError errorWithDomain:NEIAPDomainName
                                code:NEPurchaseErrorCantMakePayment
                            userInfo:@{NSLocalizedDescriptionKey: @"Can't make payments"}], NEPurchaseStateProducting,NEPurchaseResultNone);
    }
}

#pragma mark -- SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    BOOL hasEmptyTransactionId = NO;
    for (SKPaymentTransaction *transaction in queue.transactions) {
        if (transaction.transactionIdentifier == nil || transaction.transactionIdentifier.length == 0) {
            hasEmptyTransactionId = YES;
            break;
        }
    }
    for (SKPaymentTransaction *transaction in queue.transactions) {
        [self loadPayInfoWithForce:YES];
        NSString *productId = @"";
        
        if (transaction.payment.productIdentifier != nil) {
            productId = transaction.payment.productIdentifier;
        }
        
        NSString *transactionId = transaction.transactionIdentifier;
        NSString *origin_transactionId = transaction.originalTransaction.transactionIdentifier;
        if (origin_transactionId == nil || origin_transactionId.length == 0) { //有可能是空的
            origin_transactionId = transactionId;
        }
        if (self.curPayInfo.productId != nil && [self.curPayInfo.productId isEqualToString:transaction.payment.productIdentifier] && origin_transactionId != nil && origin_transactionId.length > 0 && [self.payInfoList valueForKey:origin_transactionId] == nil && hasEmptyTransactionId == NO) {
            self.curPayInfo.transactionIdentifier = transactionId;
            if ([origin_transactionId integerValue] == 0 && transaction.transactionState != SKPaymentTransactionStatePurchased) {
                NSString* json = [[NSNumber numberWithInt:transaction.transactionState] stringValue];
                [self traceObjcIAPPaymentStatusWithStep:2800
                                              productId:productId
                                             serverJson:json
                                          transactionId:transaction.transactionIdentifier
                                               errorStr:transaction.originalTransaction.transactionIdentifier
                                              errorCode:-1];
            }
            [self.payInfoList setValue:self.curPayInfo forKey:origin_transactionId];
            self.payInfoChanged = YES;
            [self setNeedStore:YES];
            self.curPayInfo = [[NEIAPPayInfo alloc] init];
            self.curPayInfo.transactionIdentifier = transactionId;
            [self traceObjcIAPPaymentStatusWithStep:2801
                                          productId:transaction.payment.productIdentifier
                                         serverJson:origin_transactionId
                                      transactionId:transaction.transactionIdentifier
                                           errorStr:origin_transactionId
                                          errorCode:-1];
        }
        BOOL fromUserAction = NO;
        if ((self.curPayInfo.transactionIdentifier != nil && [self.curPayInfo.transactionIdentifier isEqualToString:transactionId] == YES) || (transactionId == nil)) {

            [self traceObjcIAPPaymentStatusWithStep:2802
                                          productId:transaction.payment.productIdentifier
                                         serverJson:@"fromUserAction"
                                      transactionId:transaction.transactionIdentifier
                                           errorStr:@""
                                          errorCode:-1];
            fromUserAction = YES;
        }
        NSString *errorStr = @"";
        
        NSString * appleJsonString = transaction.payment.applicationUsername;

        [self traceObjcIAPPaymentStatusWithStep:2803
                                      productId:productId
                                     serverJson:appleJsonString
                                  transactionId:transaction.transactionIdentifier
                                       errorStr:origin_transactionId
                                      errorCode:-1];
        NSString *serverJson = @"";
        NSString *orderInfoJsonString = appleJsonString;
        if (origin_transactionId != nil) {
            if (orderInfoJsonString == nil || orderInfoJsonString.length == 0) {
                NEIAPPayInfo* payInfo = [[NEIAP shared].payInfoList valueForKey:origin_transactionId];
                if (payInfo.productId != nil && [productId isEqualToString: payInfo.productId] == YES) {
                    orderInfoJsonString = payInfo.extInfo;

                    [self traceObjcIAPPaymentStatusWithStep:2804
                                                  productId:productId
                                                 serverJson:appleJsonString
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:origin_transactionId
                                                  errorCode:-1];
                }else{

                    [self traceObjcIAPPaymentStatusWithStep:2805
                                                  productId:productId
                                                 serverJson:orderInfoJsonString
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:origin_transactionId
                                                  errorCode:-1];
                }
            }
        }
        serverJson = orderInfoJsonString;
        if (transaction.error) {
            errorStr = @"";
        }
        
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                self.currentTransaction = transaction;
                if (self.purchaseSuccessBlock != nil && transactionId != nil && serverJson != nil) {
                    NEPayOrderItem *order = [[NEPayOrderItem alloc] init];
                    [order yy_modelSetWithJSON:serverJson];
                    if (order.isSubscribePay == YES) {
                        NSDictionary* extParamater = nil;
                        if (order.extensionString == nil) {
                            if (order.extension != nil && order.extension.length > 0) {
                                NSData *data = [order.extension dataUsingEncoding:NSUTF8StringEncoding];
                                NSDictionary* extDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                extParamater = extDict;
                            }
                        }
                        NSString* passthroughStr = (order.extensionString == nil) ? extParamater[@"passthrough"] : order.extensionString;
                        if (passthroughStr == nil) {
                            passthroughStr = @"";
                        }
                        
                        NSInteger userId = order.currentUserId != nil ? [order.currentUserId integerValue] : 0;
                        self.purchaseSuccessBlock(userId,productId, passthroughStr, transactionId);
                    }
                }
                [self.purchasedItems addObject:transaction.payment.productIdentifier];
                [self savePurchasedItems];
                
                // 所有成功订单都会走此处。用来判断是否有未进入验签逻辑的成功返回订单;
                [self traceObjcIAPPaymentStatusWithStep:28
                                              productId:transaction.payment.productIdentifier
                                             serverJson:serverJson
                                          transactionId:transaction.transactionIdentifier
                                               errorStr:serverJson
                                              errorCode:-1];

              
                __weak typeof(self) weakSelf = self;
                FinishPurchasesCompletionBlock block = ^(BOOL success,BOOL isRepeat) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    NEPurchaseResultInfo info = isRepeat == YES ? NEPurchaseResultIsRepeat : NEPurchaseResultNone;
                    if (strongSelf.purchaseStateDidChange) {
                        strongSelf.purchaseStateDidChange(transaction.payment.productIdentifier, transaction.transactionIdentifier,fromUserAction, success ? NEPurchaseStatePurchased : NEPurchaseStateVerifyFailed,info);
                    }
                    
                    if (success) {
                        [strongSelf.purchasedItems removeObject:transaction.payment.productIdentifier];
                        [strongSelf savePurchasedItems];
                        
                        [queue finishTransaction:transaction];
                        if (origin_transactionId != nil) {
                            [strongSelf.payInfoList removeObjectForKey:origin_transactionId];
                            strongSelf.payInfoChanged = YES;
                            [self setNeedStore:NO];
                        }

                        [self traceObjcIAPPaymentStatusWithStep:24
                                                      productId:transaction.payment.productIdentifier
                                                     serverJson:serverJson
                                                  transactionId:transaction.transactionIdentifier
                                                       errorStr:@"success"
                                                      errorCode:-1];
                        
                        strongSelf.currentTransaction = nil;

                        if (fromUserAction == YES) {
                            strongSelf.curPayInfo = nil;
                        }
                        
                        if (queue.purchaseCompletion && fromUserAction == YES) {
                            queue.purchaseCompletion(transaction,isRepeat);
                        }
                    } else {
                        if (fromUserAction == YES) {
                            strongSelf.curPayInfo = nil;
                        }
                        if (queue.errBlock && fromUserAction == YES) {
                            queue.errBlock(transaction.payment.productIdentifier, transaction, transaction.error, NEPurchaseStateVerifyFailed,info);

                            [self traceObjcIAPPaymentStatusWithStep:24
                                                          productId:transaction.payment.productIdentifier
                                                         serverJson:serverJson
                                                      transactionId:transaction.transactionIdentifier
                                                           errorStr:errorStr
                                                          errorCode:-1];
                        }
                    }
                };
                
                if (self.purchaseStateDidChange) {
                    self.purchaseStateDidChange(transaction.payment.productIdentifier, transaction.transactionIdentifier,fromUserAction, NEPurchaseStateVerifing,NEPurchaseResultNone);
                }
                
                // 自定义验签
                if ( self.verify ) {
                    [self traceObjcIAPPaymentStatusWithStep:24
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:@"verify"
                                                  errorCode:-1];
                    self.verify(transaction, block);
                }
                break;
            }
            case SKPaymentTransactionStateRestored: {
                if (self.restoreTransactionBlock) {
                    self.restoreTransactionBlock(transaction);
                }
                break;
            }
                
            case SKPaymentTransactionStateFailed: {
                [queue finishTransaction:transaction];
                if (transaction.transactionIdentifier != nil) {
                    [self.needRemovePayKeys addObject:transaction.transactionIdentifier];
                }

                // 当前苹果账户无法购买商品(如有疑问，可以询问苹果客服)
                if (transaction.error.code == SKErrorClientInvalid) {
                    [self traceObjcIAPPaymentStatusWithStep:25
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:@"ClientInvalid"
                                                  errorCode:-1];
                }
                // 订单已取消，finish
                else if (transaction.error.code == SKErrorPaymentCancelled) {
                    [self traceObjcIAPPaymentStatusWithStep:25
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:@"PaymentCancelled"
                                                  errorCode:-1];
                }
                // 订单无效(如有疑问，可以询问苹果客服)
                else if (transaction.error.code == SKErrorPaymentInvalid) {
                    [self traceObjcIAPPaymentStatusWithStep:25
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:@"PaymentInvalid"
                                                  errorCode:-1];
                }
                // 当前苹果设备无法购买商品(如有疑问，可以询问苹果客服)
                else if (transaction.error.code == SKErrorPaymentNotAllowed) {
                    [self traceObjcIAPPaymentStatusWithStep:25
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:@"PaymentNotAllowed"
                                                  errorCode:-1];
                }
                // 当前商品不可用
                else if (transaction.error.code == SKErrorStoreProductNotAvailable) {
                    [self traceObjcIAPPaymentStatusWithStep:25
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:@"StoreProductNotAvailable"
                                                  errorCode:-1];
                }
                // User has not allowed access to cloud service information
                else if (transaction.error.code == SKErrorCloudServicePermissionDenied) {
                    [self traceObjcIAPPaymentStatusWithStep:25
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:@"CloudServicePermissionDenied"
                                                  errorCode:-1];
                }
                // Device could not connect to the nework
                else if (transaction.error.code == SKErrorCloudServiceNetworkConnectionFailed) {
                    [self traceObjcIAPPaymentStatusWithStep:25
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:@"CloudServiceNetworkConnectionFailed"
                                                  errorCode:-1];
                }
                // User has revoked permission to use this cloud service
                else if (transaction.error.code == SKErrorCloudServiceRevoked) {
                    [self traceObjcIAPPaymentStatusWithStep:25
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:@"CloudServiceRevoked"
                                                  errorCode:-1];
                }
                // Unknown
                else {
                    [self traceObjcIAPPaymentStatusWithStep:25
                                                  productId:transaction.payment.productIdentifier
                                                 serverJson:serverJson
                                              transactionId:transaction.transactionIdentifier
                                                   errorStr:transaction.error.description
                                                  errorCode:transaction.error.code];
                }
                
                self.currentTransaction = nil;
                if (self.purchaseStateDidChange) {
                    self.purchaseStateDidChange(transaction.payment.productIdentifier, transaction.transactionIdentifier,fromUserAction, NEPurchaseStateFailed,NEPurchaseResultNone);
                }
                if (fromUserAction == YES) {
                    self.curPayInfo = nil;
                }
                if (queue.errBlock && fromUserAction == YES) {
                    queue.errBlock(transaction.payment.productIdentifier, transaction, transaction.error, NEPurchaseStateFailed,NEPurchaseResultNone);
                }
                break;
            }
            case SKPaymentTransactionStatePurchasing: {
                [self traceObjcIAPPaymentStatusWithStep:26
                                              productId:transaction.payment.productIdentifier
                                             serverJson:serverJson
                                          transactionId:transaction.transactionIdentifier
                                               errorStr:@"StatePurchasing"
                                              errorCode:-1];
                break;
            }
            default:
            {
                break;
            }
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    if(self.restoreErrorBlock) {
        self.restoreErrorBlock(error);
    }
    self.restoreCompletionBlock = nil;
    self.restoreErrorBlock = nil;
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    if (self.restoreCompletionBlock) {
        self.restoreCompletionBlock();
    }
    self.restoreCompletionBlock = nil;
    self.restoreErrorBlock = nil;
}


- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
}



- (void)traceObjcIAPPaymentStatusWithStep:(NSInteger)step
                                productId:(NSString *)productId
                               serverJson:(NSString *)serverJson
                            transactionId:(NSString *)transactionId
                                 errorStr:(NSString *)errorStr
                                errorCode:(NSInteger)errorCode {
    NSDictionary *detail = @{
         @"productId": (productId ? productId : @"unknown"),
         @"amount": @(-1),
         @"currency_now": @"unknown",
         @"isRestoreFromFailedOrder": @"unknown",
         @"currency_global": @"unknown",
         @"transactionId": (transactionId ? transactionId : @"unknown"),
         @"server_json": (serverJson ? serverJson : @"unknown"),
         @"extension": (errorStr ? errorStr : @"unknown"),
         @"preorderId": @"unknown",
         @"errorCode": @(errorCode),
         @"receiptIsNil": @(YES)
    };
    NSString *stepStatus = [NSString stringWithFormat:@"step_%@", @(step)];
    NSString * log = [NSString stringWithFormat:@"payStep:%@",stepStatus];
    NSLog(log);
}

@end
