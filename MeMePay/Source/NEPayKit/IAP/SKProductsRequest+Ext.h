//
//  SKProductsRequest+Ext.h
//  NEIAPKit
//
//  Created by zhang yinglong on 2017/10/19.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "NEIAPBlock.h"

@interface SKProductsRequest (NEIAPKit)

@property (nonatomic, copy) ProductsCompletionBlock productsCompletion;

@property (nonatomic, copy) ProductsErrorBlock errBlock;

@end
