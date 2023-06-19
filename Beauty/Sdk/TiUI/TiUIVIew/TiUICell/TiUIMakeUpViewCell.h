//
//  TiUIMakeUpViewCell.h
//  TiFancy
//
//  Created by MBP DA1003 on 2020/8/3.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TiConfig.h"
#import "TiButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface TiUIMakeUpViewCell : UICollectionViewCell

@property(nonatomic,strong)TIMenuMode *subMod;
@property(nonatomic ,strong)TiButton *cellButton;

-(void)setCellTypeBorderIsShow:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
