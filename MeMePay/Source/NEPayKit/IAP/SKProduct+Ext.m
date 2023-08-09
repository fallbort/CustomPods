//
//  SKProduct+Ext.m
//  NEIAPKit
//
//  Created by zhang yinglong on 2017/10/19.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "SKProduct+Ext.h"

@implementation SKProduct (NEIAPKit)

- (NSString *)localizedPrice {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = self.priceLocale;
    formatter.usesSignificantDigits = YES;
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 2;
    return [formatter stringFromNumber:self.price];
}

@end
