//
//  TiUIGreenScreensView.h
//  TiFancy
//
//  Created by N17 on 2021/4/16.
//  Copyright © 2021 Tillusory Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TiConfig.h"
#import "TiButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface TiUIGreenScreensView : UIView

@property(nonatomic,strong) TiButton *resetBtn;//恢复
@property(nonatomic,strong) UIView *dividingLine;//分割线

@property(nonatomic,strong) TiButton *similarityBtn;//相似度
@property(nonatomic,strong) TiButton *smoothBtn;//平滑度
@property(nonatomic,strong) TiButton *hyalineBtn;//透明度

@end

NS_ASSUME_NONNULL_END
