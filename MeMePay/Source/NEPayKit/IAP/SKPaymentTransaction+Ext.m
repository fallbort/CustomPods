//
//  SKPaymentTransaction+Ext.m
//  NEIAPKit
//
//  Created by zhang yinglong on 2017/10/19.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "SKPaymentTransaction+Ext.h"

@implementation SKPaymentTransaction (NEIAPKit)

- (NSString *)receiptString {
    NSString *receiptString = nil;
    NSURL *appStoreReceiptURL = [NSBundle mainBundle].appStoreReceiptURL;
    if ( appStoreReceiptURL ) {
        NSData *receiptData = [NSData dataWithContentsOfURL:appStoreReceiptURL];
        if ( receiptData ) {
            receiptString = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        }
    }
    return receiptString;
}

- (NSData *)receiptData {
    NSData *receiptData = nil;
    NSURL *appStoreReceiptURL = [NSBundle mainBundle].appStoreReceiptURL;
    if ( appStoreReceiptURL ) {
        receiptData = [NSData dataWithContentsOfURL:appStoreReceiptURL];
    }
    return receiptData;
}

@end
