//
//  TiUISubMenuThreeViewCell.m
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/6.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import "TiUISubMenuThreeViewCell.h"
#import "TiUITool.h"

@interface TiUISubMenuThreeViewCell ()

@property(nonatomic ,strong)TiButton *cellButton;

@end

@implementation TiUISubMenuThreeViewCell


- (TiButton *)cellButton{
    if (!_cellButton) {
        _cellButton = [[TiButton alloc] initWithScaling:1.0];
        _cellButton.userInteractionEnabled = NO;
    }
    return _cellButton;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.cellButton];
        [self.cellButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.left.right.equalTo(self);
        }];
        
    }
    return self;
}

//判断是否可编辑
- (BOOL)isEdit{
    if (self.cellButton.isEnabled) {
        return YES;
    }else{
        return NO;
    }
}

//编辑绿幕
- (void)setSubMod:(TIMenuMode *)subMod WithTag:(NSInteger)tag isEnabled:(BOOL)isEnabled{
    
    if (subMod.menuTag == 99 && tag == 9) {
        [self.cellButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).with.insets(UIEdgeInsetsMake(17, 17, 17, 17));
        }];
        [self.cellButton setImage:[UIImage imageNamed:@"icon_lvmu_bianji.png"] forState:UIControlStateNormal];
        [self.cellButton setImage:[UIImage imageNamed:@"icon_lvmu_bianji_disabled.png"] forState:UIControlStateDisabled];
        [self endAnimation];
        [self.cellButton setDownloaded:YES];
        [self.cellButton setEnabled:isEnabled];
    }
    
}

- (void)setSubMod:(TIMenuMode *)subMod WithTag:(NSInteger)tag
{
    if (subMod) {
    _subMod = subMod;
        if (subMod.menuTag == 99 && tag == 9) {
            //默认绿幕编辑功能不可选
            [self setSubMod:subMod WithTag:tag isEnabled:NO];
        }else{
            if (subMod.menuTag) {
                [self.cellButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.top.bottom.left.right.equalTo(self);
                }];
                [self.cellButton setBorderWidth:0.0 BorderColor:[UIColor clearColor] forState:UIControlStateNormal];
                [self.cellButton setBorderWidth:1.0 BorderColor:TI_Color_Default_Background_Pink forState:UIControlStateSelected];
                WeakSelf;
                NSString *iconUrl = @"";
                NSString *folder = @"";
                switch (tag) {
                    case 2:
                        iconUrl = [TiSDK getStickerIconURL];
                        folder = @"sticker_icon";
                        break;
                    case 3:
                        iconUrl = [TiSDK getGiftIconURL];
                        folder = @"gift_icon";
                        break;
                    case 7:
                        iconUrl = [TiSDK getWatermarkIconURL];
                        folder = @"watermark_icon";
                        break;
                    case 8:
                        iconUrl = [TiSDK getMaskIconURL];
                        folder = @"mask_icon";
                        break;
                    case 9:
                        iconUrl = [TiSDK getGreenScreenIconURL];
                        folder = @"greenscreen_icon";
                        break;
                    case 11:
                        iconUrl = [TiSDK getInteractionIconURL];
                        folder = @"interaction_icon";
                        break;
                    case 14:
                        iconUrl = [TiSDK getPortraitIconURL];
                        folder = @"portrait_icon";
                        break;
                    case 16:
                        iconUrl = [TiSDK getGestureIconURL];
                        folder = @"gesture_icon";
                        break;
                    default:
                        break;
                }
                
                iconUrl = iconUrl?iconUrl:@"";
                [TiUITool getImageFromeURL:[NSString stringWithFormat:@"%@%@", iconUrl, subMod.thumb] WithFolder:folder downloadComplete:^(UIImage *image) {
                    [weakSelf.cellButton setTitle:nil withImage:image withTextColor:nil forState:UIControlStateNormal];
                    [weakSelf.cellButton setTitle:nil withImage:image withTextColor:nil forState:UIControlStateSelected];
                }];
                
                switch (subMod.downloaded) {
                    case TI_DOWNLOAD_STATE_CCOMPLET://下载完成
                        [self endAnimation];
                        [self.cellButton setDownloaded:YES];
                        
                            break;
                        case TI_DOWNLOAD_STATE_NOTBEGUN://未下载
                        
                        [self endAnimation];
                        [self.cellButton setDownloaded:NO];
                        
                            break;
                        case TI_DOWNLOAD_STATE_BEBEING://下载中。。。
                        
                        [self startAnimation];
                        [self.cellButton setDownloaded:YES];
                            break;
                    default:
                        break;
                }
                
            }else{
                [self.cellButton mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.edges.equalTo(self).with.insets(UIEdgeInsetsMake(17, 17, 17, 17));
                }];
                [self.cellButton setBorderWidth:0.0 BorderColor:[UIColor clearColor] forState:UIControlStateNormal];
                [self.cellButton setBorderWidth:0.0 BorderColor:TI_Color_Default_Background_Pink forState:UIControlStateSelected];
                [self.cellButton setTitle:nil
                                withImage:[UIImage imageNamed:subMod.normalThumb]
                            withTextColor:nil
                                 forState:UIControlStateNormal];
                [self.cellButton setTitle:nil
                                withImage:[UIImage imageNamed:subMod.thumb]
                            withTextColor:nil
                                 forState:UIControlStateSelected];
                [self endAnimation];
                [self.cellButton setDownloaded:YES];
            }
            [self.cellButton setSelected:subMod.selected];
        }
        
    }
    
}

- (void)startAnimation{
    [self.cellButton startAnimation];
}

- (void)endAnimation{
    [self.cellButton endAnimation]; 
}

@end
