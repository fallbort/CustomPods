//
//  TiUISliderNew.h
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/2.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
 
typedef NS_ENUM(NSInteger, TiUISliderType) {
    TI_UI_SLIDER_TYPE_ONE,
    TI_UI_SLIDER_TYPE_TWO
};

@interface TiUISliderNew : UISlider

@property(nonatomic,copy)void(^refreshValueBlock)(CGFloat value);
@property(nonatomic,copy)void(^valueBlock)(CGFloat value);

//滑动的标记View
@property(nonatomic,strong)UIImageView *tagView;
@property(nonatomic,strong)UILabel *tagLabel;
//覆盖trackmax的线
@property(nonatomic,strong)UIView *trackColorView;
//用于标记分割的线
@property(nonatomic,strong)UIView *tagLine;

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size;

- (void)setSliderType:(TiUISliderType)sliderType WithValue:(float)value;

@end
