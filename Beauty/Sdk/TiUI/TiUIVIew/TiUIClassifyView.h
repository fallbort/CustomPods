//
//  TiUIClassifyView.h
//  TiFancy
//
//  Created by iMacA1002 on 2020/4/26.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TiUIClassifyView : UIView
- (void)showView;
- (void)hiddenView;

@property (copy, nonatomic)void(^executeShowOrHiddenBlock)(BOOL);
@property (copy, nonatomic)void(^clickOnTheClassificationBlock)(NSArray * classifyArr);

@property(nonatomic,strong) NSMutableArray *iconArr;
@property(nonatomic,strong) UIColor *titleColor;
@property(nonatomic,strong) UICollectionView *classifyMenuView;

//萌颜Block
@property (copy, nonatomic)void(^CutefaceBlock)(NSString * name);

- (void)Judge_First:(NSString *)key;

@property(nonatomic,strong) NSArray *modArr;

@end

NS_ASSUME_NONNULL_END
