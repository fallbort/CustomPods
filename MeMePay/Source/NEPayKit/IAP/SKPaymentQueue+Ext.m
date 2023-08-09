//
//  SKPaymentQueue+Ext.m
//  NEIAPKit
//
//  Created by zhang yinglong on 2017/10/19.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "SKPaymentQueue+Ext.h"
#import <objc/runtime.h>

static int _PurchaseCompletionKey;
static int _ErrorCompletionKey;

@implementation SKPaymentQueue  (NEIAPKit)

- (void)setPurchaseCompletion:(PurchaseCompletionBlock)purchaseCompletion {
    objc_setAssociatedObject(self, &_PurchaseCompletionKey, purchaseCompletion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (PurchaseCompletionBlock)purchaseCompletion {
    return objc_getAssociatedObject(self, &_PurchaseCompletionKey);
}

- (void)setErrBlock:(PurchaseErrorBlock)errBlock {
    objc_setAssociatedObject(self, &_ErrorCompletionKey, errBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (PurchaseErrorBlock)errBlock {
    return objc_getAssociatedObject(self, &_ErrorCompletionKey);
}

@end
