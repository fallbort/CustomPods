//
//  TiUISubMenuOneViewCell.m
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/4.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import "TiUISubMenuOneViewCell.h"
#import "TiButton.h"
#import "TiCustomButtom.h"
@import MeMeKit;


@interface TiUISubMenuOneViewCell ()

@property(nonatomic ,strong)TiCustomButtom *cellButton;

@end

@implementation TiUISubMenuOneViewCell

- (TiCustomButtom *)cellButton{
    if (!_cellButton) {
        _cellButton = [[TiCustomButtom alloc]initWithScaling:0.43];
        _cellButton.userInteractionEnabled = NO;
        [_cellButton setBorderWidth:56 BorderColor:[UIColor hexStringToColor:@"15ffffff"] forState:UIControlStateNormal];
        [_cellButton setBorderWidth:56 BorderColor:[UIColor hexStringToColor:@"15ffffff"] forState:UIControlStateHighlighted];
    }
    return _cellButton;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.cellButton];
        [self.cellButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(self.mas_left).offset(0);
            make.right.equalTo(self.mas_right).offset(0);
        }];
    }
    return self;
}

- (void)setSubMod:(TIMenuMode *)subMod{
    
    if (subMod) {
        _subMod = subMod;
        if ([subMod.normalThumb  isEqual: @""]) {
            [self.cellButton setTitle:[NSString stringWithFormat:@"%@",@""] withImage:nil withTextColor:UIColor.clearColor forState:UIControlStateNormal];
            [self.cellButton setClassifyText:subMod.name withTextColor:UIColor.whiteColor];
            [self.cellButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self);
                make.left.equalTo(self.mas_left).offset(0);
                make.right.equalTo(self.mas_right).offset(0);
                make.height.mas_equalTo(56);
            }];
        }else{
            UIImage* image = [[UIImage imageNamed:subMod.selectedThumb inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] imageWithRenderingMode:(UIImageRenderingModeAlwaysTemplate)];
            [self.cellButton setTitle:[NSString stringWithFormat:@"%@",subMod.name] withImage:[UIImage imageNamed:subMod.normalwhiteThumb inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] withTextColor:UIColor.whiteColor forState:UIControlStateNormal];
            [self.cellButton setTitle:[NSString stringWithFormat:@"%@",subMod.name]
                    withImage:image
                withTextColor:[UIColor hexStringToColor:@"#FD4186"]
                     forState:UIControlStateSelected];
            [self.cellButton setSelected:subMod.selected];
            [self.cellButton setTextFont:[UIFont fontWithName:@"PingFang SC" size:14]];
            [self.cellButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.bottom.equalTo(self);
                make.left.equalTo(self.mas_left).offset(0);
                make.right.equalTo(self.mas_right).offset(0);
            }];
        }
    }
    
}

- (void)setCellTypeBorderIsShow:(BOOL)show{
   
    if (show) {
        [self.cellButton setBorderWidth:0.0 BorderColor:[UIColor clearColor] forState:UIControlStateNormal];
        [self.cellButton setBorderWidth:1.f BorderColor:TI_Color_Default_Background_Pink forState:UIControlStateSelected];
    }else{
        [self.cellButton setBorderWidth:0.0 BorderColor:[UIColor clearColor] forState:UIControlStateNormal];
        [self.cellButton setBorderWidth:0.f BorderColor:[UIColor clearColor] forState:UIControlStateSelected];
    }
       
}

@end
