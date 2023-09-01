//
//  TiUIMakeUpViewCell.m
//  TiFancy
//
//  Created by MBP DA1003 on 2020/8/3.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import "TiUIMakeUpViewCell.h"
#import "TiUITool.h"
@import MeMeKit;

@interface TiUIMakeUpViewCell ()

@end

@implementation TiUIMakeUpViewCell

- (TiButton *)cellButton{
    if (!_cellButton) {
        _cellButton = [[TiButton alloc]initWithScaling:1.0];
        _cellButton.userInteractionEnabled = NO;
        [_cellButton setDownloadViewFrame:downloadViewFrame_equalToImage];
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
            make.left.equalTo(self.mas_left).offset(6);
            make.right.equalTo(self.mas_right).offset(-6);
        }];

    }
    return self;
}

- (void)setSubMod:(TIMenuMode *)subMod
{
    if (subMod) {
    _subMod = subMod;
    
        if (subMod.menuTag) {
            WeakSelf;
            NSString *iconUrl = nil;
            NSString *folder = @"makeup_icon";
           
            iconUrl = iconUrl?iconUrl:@"";
            [TiUITool getImageFromeURL:[NSString stringWithFormat:@"%@%@", iconUrl, subMod.thumb] WithFolder:folder downloadComplete:^(UIImage *image) {
                
                [weakSelf.cellButton setTitle:subMod.dir withImage:image withTextColor:UIColor.whiteColor forState:UIControlStateNormal];
                [weakSelf.cellButton setTitle:subMod.dir withImage:image withTextColor:TI_Color_Default_Background_Pink
                    forState:UIControlStateSelected];
            }];
            //设置字体大小
            [weakSelf.cellButton setTextFont:[UIFont fontWithName:@"PingFang-SC-Regular" size:10]];
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
            [self.cellButton setTitle:subMod.dir
                            withImage:[UIImage imageNamed:subMod.normalThumb inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil]
                        withTextColor:TI_Color_Default_Text_Black
                             forState:UIControlStateNormal];
            [self.cellButton setTitle:subMod.dir
                            withImage:[UIImage imageNamed:subMod.selectedThumb inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil]
                        withTextColor:TI_Color_Default_Background_Pink
                             forState:UIControlStateSelected];
            [self endAnimation];
            [self.cellButton setDownloaded:YES];
        }
        
        [self.cellButton setSelected:subMod.selected];
    }
    
}

- (void)startAnimation{
    [self.cellButton startAnimation];
}

- (void)endAnimation{
    [self.cellButton endAnimation];
}

- (void)setCellTypeBorderIsShow:(BOOL)show{
    [self.cellButton setBorderWidth:0.0 BorderColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self.cellButton setBorderWidth:1.f BorderColor:TI_Color_Default_Background_Pink forState:UIControlStateSelected];
}

@end
