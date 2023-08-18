//
//  TiUISliderRelatedView.m
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/2.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import "TiUISliderRelatedView.h"
#import "TiConfig.h"

#import <TiSDK/TiSDKInterface.h>
@import MeMeKit;

@interface TiUISliderRelatedView ()
 
@end

@implementation TiUISliderRelatedView

- (TiUISliderNew *)sliderView {
    if (!_sliderView) {
        _sliderView = [[TiUISliderNew alloc] init];
        WeakSelf
        [_sliderView setValueBlock:^(CGFloat value) {
//            //数值
//            weakSelf.sliderLabel.text = [NSString stringWithFormat:@"%d%%",(int)value];
        }];
    }
    return _sliderView;
}

- (UILabel *)sliderLabel{
    if (!_sliderLabel) {
        _sliderLabel = [[UILabel alloc]init];
        [_sliderLabel setTextAlignment:NSTextAlignmentCenter];
        [_sliderLabel setFont:TI_Font_Default_Size_Medium];
        [_sliderLabel setTextColor:TI_Color_Default_Text_White];
        _sliderLabel.userInteractionEnabled = NO;
        _sliderLabel.text = @"100%";
    }
    return _sliderLabel;
}

- (UILabel *)sliderLabelRight{
    if (!_sliderLabelRight) {
        _sliderLabelRight = [[UILabel alloc]init];
        [_sliderLabelRight setTextAlignment:NSTextAlignmentCenter];
        [_sliderLabelRight setFont:TI_Font_Default_Size_Medium];
        [_sliderLabelRight setTextColor:TI_Color_Default_Text_White];
        _sliderLabelRight.userInteractionEnabled = NO;
        _sliderLabelRight.text = @"100%";
        _sliderLabelRight.hidden = YES;
    }
    return _sliderLabelRight;
}

- (UIButton *)tiContrastBtn{
    if (!_tiContrastBtn) {
        _tiContrastBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_tiContrastBtn setImage:[UIImage imageNamed:@"icon_compare_white" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] forState:UIControlStateNormal];
        [_tiContrastBtn setImage:[UIImage imageNamed:@"icon_compare_white" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] forState:UIControlStateSelected];
        [_tiContrastBtn setSelected:NO];
        _tiContrastBtn.layer.masksToBounds = NO;
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longPress.minimumPressDuration = 0.0; //定义按的时间
        [_tiContrastBtn addGestureRecognizer:longPress];
    }
    return _tiContrastBtn;
}

- (void)longPress:(UILongPressGestureRecognizer*)gestureRecognizer{
     
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        [[TiSDKManager shareManager] setRenderEnable:false];
    }else if([gestureRecognizer state] == UIGestureRecognizerStateEnded){
        [[TiSDKManager shareManager] setRenderEnable:true];
    }else{
        return;
    }
    
}

- (void)setSliderHidden:(BOOL)hidden{
    [self.sliderView setHidden:hidden];
    [self.sliderLabel setHidden:hidden];
    [self.sliderLabelRight setHidden:hidden];
}

- (instancetype)init{
    
    self = [super init];
    if (self) {
        [self addSubview:self.sliderView];
        [self addSubview:self.sliderLabel];
        [self addSubview:self.tiContrastBtn];
        [self addSubview:self.sliderLabelRight];
        
        [self.sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.mas_centerY);
            make.left.equalTo(@72.5);
            make.right.equalTo(@-72.5);
            make.height.offset(TiUISliderHeight-1);
        }];
        [self.sliderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(@29.5);
        }];
        [self.tiContrastBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.right.equalTo(@-28.5);
        }];
        [self.sliderLabelRight mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.right.equalTo(@-29.5);
        }];
        
    }
    return self;
}

@end
