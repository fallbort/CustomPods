//
//  SKProductsRequest+Ext.m
//  NEIAPKit
//
//  Created by zhang yinglong on 2017/10/19.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "SKProductsRequest+Ext.h"
#import <objc/runtime.h>

static int _ProductsCompletionKey;
static int _ErrorCompletionKey;

@implementation SKProductsRequest (NEIAPKit)

- (void)setProductsCompletion:(ProductsCompletionBlock)productsCompletion {
    objc_setAssociatedObject(self, &_ProductsCompletionKey, productsCompletion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ProductsCompletionBlock)productsCompletion {
    return objc_getAssociatedObject(self, &_ProductsCompletionKey);
}

- (void)setErrBlock:(ProductsErrorBlock)errBlock {
    objc_setAssociatedObject(self, &_ErrorCompletionKey, errBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ProductsErrorBlock)errBlock {
    return objc_getAssociatedObject(self, &_ErrorCompletionKey);
}

@end
