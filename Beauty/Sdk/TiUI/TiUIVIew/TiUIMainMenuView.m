//
//  TiUIMainMenuView.m
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/2.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import "TiUIMainMenuView.h"
#import "TiSetSDKParameters.h"
#import "TiDownloadZipManager.h"

#import "TiUIMenuViewCell.h"

#import "TiUIMenuOneViewCell.h"
#import "TiUIMenuTwoViewCell.h"
#import "TiUIMenuThreeViewCell.h"

#import "TiUIMakeUpView.h"
@import MeMeKit;

bool is_reset = false;
bool is_resetBeauty = false;
NSString *resetObject = @"";
int is_greenEdit = 1;

@interface TiUIMainMenuView ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property(nonatomic,strong) NSIndexPath *selectedIndexPath;
@property(nonatomic,assign) NSInteger mainindex;
@property(nonatomic,assign) NSInteger subindex;
@property(nonatomic,strong) NSIndexPath *lx_indexPath;
@property(nonatomic,strong) NSIndexPath *lv_indexPath;
@property(nonatomic,strong) NSIndexPath *tz_indexPath;
@property(nonatomic,strong) NSIndexPath *mz_indexPath;

//绿幕抠图编辑页面title。。
@property(nonatomic,strong)UIView *editView;
@property(nonatomic,strong)UILabel *editLabel;

@property(nonatomic,strong)UIButton *resetAllBtn;

@end

static NSString *const TiUIMenuViewCollectionViewCellId = @"TiUIMainMenuViewCollectionViewCellId";
static NSString *const TiUISubMenuViewCollectionViewCellId = @"TiUIMainSubMenuViewCollectionViewCellId";

@implementation TiUIMainMenuView

- (TiUISliderRelatedView *)sliderRelatedView{
    if (!_sliderRelatedView) {
        _sliderRelatedView = [[TiUISliderRelatedView alloc]init];
        //默认美白滑动条
        [_sliderRelatedView.sliderView setSliderType:TI_UI_SLIDER_TYPE_ONE WithValue:[TiSetSDKParameters getFloatValueForKey:TI_UIDCK_SKIN_WHITENING_SLIDER]];
        _sliderRelatedView.sliderLabel.text = [NSString stringWithFormat:@"%d%%",(int)(_sliderRelatedView.sliderView.minimumValue)];
        _sliderRelatedView.sliderLabelRight.text = [NSString stringWithFormat:@"%d%%",(int)(_sliderRelatedView.sliderView.maximumValue)];
        
        WeakSelf;//滑动滑动条调用成回调
        [_sliderRelatedView.sliderView setRefreshValueBlock:^(CGFloat value) {
            typeof(weakSelf) strongSelf = weakSelf;
            TiUIDataCategoryKey valueForKey;
            
            if (weakSelf.mainindex == 10) {//一键美颜
                
                if (value == 100 && strongSelf.subindex == 0) {
                    [strongSelf setResetStatus:@"关闭"];
                }else{
                    [strongSelf setResetStatus:@"美颜"];
                }
                valueForKey = TI_UIDCK_ONEKEY_SLIDER;
                
            }else if (weakSelf.mainindex == 0){//美颜
                
                [strongSelf setResetStatus:@"美颜"];
                TIMenuMode *mod = [TiMenuPlistManager shareManager].beautyModeArr[weakSelf.subindex];
                valueForKey  = (weakSelf.mainindex+1)*100 + mod.menuTag;
                
            }else if (weakSelf.mainindex == 13){//脸型
                
                [strongSelf setResetStatus:@"美颜"];
                valueForKey = TI_UIDCK_FACESHAPE_SLIDER;
                
            }else if (weakSelf.mainindex == 1){//美型
                
                [strongSelf setResetStatus:@"美颜"];
                valueForKey  = (weakSelf.mainindex+1)*100 + weakSelf.subindex;
                
            }else if (weakSelf.mainindex==4) {//滤镜
                
                valueForKey = (weakSelf.mainindex-1)*100 + weakSelf.subindex;
                
            }else if (weakSelf.mainindex == 9){//绿幕
                
                valueForKey = 700 + is_greenEdit;
                //发送通知——开启绿幕编辑恢复功能
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NotificationName_TiUIGreenScreensView_isResetEdit" object:@(true)];
                
            }else if(weakSelf.mainindex ==12){//美妆
                
                [strongSelf setResetStatus:@"美妆"];
                int thousand =  (int)self.subindex/1000 *1000;//千
                 valueForKey = thousand;
                
            }else if (weakSelf.mainindex==15) {//美发
                
                valueForKey = TI_UIDCK_HAIRDRESS_SLIDER;
                
            }else{
                
                valueForKey  = (weakSelf.mainindex+1)*100 + weakSelf.subindex;
                
            }
            
            //储存滑条参数
            [TiSetSDKParameters setFloatValue:value forKey:valueForKey];
            //设置美颜参数
            [TiSetSDKParameters setBeautySlider:value forKey:valueForKey withIndex:weakSelf.subindex];
            
        }];
        
    }
    return _sliderRelatedView;
}

- (void)setResetStatus:(NSString *)setResetObject{
    
    if ([setResetObject  isEqual: @"美颜"]) {
        
        //开启美颜重置功能
        [self.resetBtn setEnabled:true];
        //设置重置按钮状态——美颜
        [[NSUserDefaults standardUserDefaults] setObject:@"optional" forKey:@"beautystate"];
        
    }else if ([setResetObject  isEqual: @"美妆"]){
        
        //开启美妆重置功能
        [self.resetBtn setEnabled:true];
        makeup_is_reset = false;
        //设置重置按钮状态——美妆
        [[NSUserDefaults standardUserDefaults] setObject:@"optional" forKey:@"makeupstate"];
        
    }else if ([setResetObject  isEqual: @"关闭"]){
        
        //关闭美颜重置功能
        [self.resetBtn setEnabled:false];
        //设置重置按钮状态——关闭
        [[NSUserDefaults standardUserDefaults] setObject:@"not_optional" forKey:@"beautystate"];
        
    }
    
}

- (UIView *)backgroundView
{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc]init];
    }
    return _backgroundView;
}

- (TiUIClassifyView *)classifyView{
    if (!_classifyView) {
        _classifyView = [[TiUIClassifyView alloc]init];
        _isClassifyShow = YES;
        WeakSelf;
        [_classifyView setExecuteShowOrHiddenBlock:^(BOOL show) {
             weakSelf.sliderRelatedView.hidden = show;
             weakSelf.isClassifyShow = show;
        }];
        [_classifyView setClickOnTheClassificationBlock:^(NSArray * _Nonnull classifyIndexArr) {
            
            weakSelf.classifyArr = classifyIndexArr;
            [weakSelf.menuView reloadData];
            [weakSelf.subMenuView reloadData];
            for (int i = 0; i<weakSelf.classifyArr.count; i++){
                NSNumber *menuTag = weakSelf.classifyArr[i];
                TIMenuMode *mode =  [[TiMenuPlistManager shareManager] mainModeArr][[menuTag intValue]];
                if (mode.selected)
                {
                    NSIndexPath * menuIndex = [NSIndexPath indexPathForRow:i inSection:0];
                    weakSelf.selectedIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    [weakSelf.menuView scrollToItemAtIndexPath:menuIndex atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
                 }
            }
            
            if (classifyIndexArr == [self.classifyView.modArr[0] objectForKey:@"TIMenuClassify"]){}
            
        }];
        [_classifyView setCutefaceBlock:^(NSString * name) {
            if ([name  isEqual: @"萌颜"]) {
                [weakSelf.backBtn setHidden:true];
                [weakSelf.backView setHidden:false];
                [weakSelf.back2Btn setHidden:false];
                [weakSelf.lineView setHidden:false];
            }else{
                [weakSelf.backBtn setHidden:false];
                [weakSelf.backView setHidden:false];
                [weakSelf.back2Btn setHidden:true];
                [weakSelf.lineView setHidden:true];
            }
        }];
    }
    return _classifyView;
}

- (UIButton *)backBtn{
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] init];
        [_backBtn setBackgroundImage:[UIImage imageNamed:@"icon_back.png" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(BackPrevious:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (UIButton *)back2Btn{
    if (!_back2Btn) {
        _back2Btn = [[UIButton alloc] init];
        [_back2Btn setImage:[UIImage imageNamed:@"icon_back.png" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] forState:UIControlStateNormal];
        [_back2Btn addTarget:self action:@selector(BackPrevious:) forControlEvents:UIControlEventTouchUpInside];
        [_back2Btn setHidden:true];
    }
    return _back2Btn;
}

- (UIView *)backView{
    if (!_backView) {
        _backView = [[UIView alloc] init];
        _backView.backgroundColor = TI_RGB_Alpha(45.0, 45.0, 45.0, 0.6);
        [_backView setHidden:true];
    }
    return _backView;
}

- (UIView *)lineView{
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = TI_RGB_Alpha(238.0, 238.0, 238.0, 0.6);
        [_lineView setHidden:true];
    }
    return _lineView;
}

-(UIButton *)resetAllBtn {
    if(!_resetAllBtn) {
        _resetAllBtn = [[UIButton alloc] init];
        [_resetAllBtn setTitle:[NELocalize localizedString:@"重置"] forState:UIControlStateNormal];
        _resetAllBtn.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        [_resetAllBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        UIImage* image = [UIImage imageNamed:@"icon_chongzhi_def.png" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil];
        image = [image mmImageByResizeToSize:CGSizeMake(14, 14)];
        [_resetAllBtn setImage:image forState:UIControlStateNormal];
        UIImage* imageD = [UIImage imageNamed:@"icon_chongzhi_disabled.png" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil];
        imageD = [imageD mmImageByResizeToSize:CGSizeMake(14, 14)];
        [_resetAllBtn setImage:imageD forState:UIControlStateDisabled];
        __weak __typeof(self)weakSelf = self;
        [_resetAllBtn handleControlEvent:UIControlEventTouchUpInside closure:^{
            if(weakSelf==nil){return;}
            if (weakSelf.resetAllClickedBlock != nil) {
                weakSelf.resetAllClickedBlock();
            }
        }];
    }
    return _resetAllBtn;
}

- (UIButton *)resetBtn{
    if (!_resetBtn) {
        
        _resetBtn = [[UIButton alloc] init];
        [_resetBtn setTitle:@"重置" forState:UIControlStateNormal];
        [_resetBtn setTitleColor:TI_RGB_Alpha(254.0, 254.0, 254.0, 1.0) forState:UIControlStateNormal];
        [_resetBtn setTitleColor:TI_RGB_Alpha(254.0, 254.0, 254.0, 0.4) forState:UIControlStateDisabled];
        [_resetBtn.titleLabel setFont:[UIFont fontWithName:@"PingFang-SC-Regular" size:10]];
        [_resetBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, -8)];
        [_resetBtn setImage:[UIImage imageNamed:@"icon_chongzhi_def.png" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] forState:UIControlStateNormal];
        [_resetBtn setImage:[UIImage imageNamed:@"icon_chongzhi_disabled.png" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] forState:UIControlStateDisabled];
        [_resetBtn addTarget:self action:@selector(ResetClick:) forControlEvents:UIControlEventTouchUpInside];
        //判断重置按钮状态
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *beautystate = [defaults objectForKey:@"beautystate"];
        NSString *makeupstate = [defaults objectForKey:@"makeupstate"];
        if ([resetObject  isEqual: @"美颜"]) {
            if ([beautystate  isEqual: @"optional"]) {
                [_resetBtn setEnabled:true];
            }else{
                //默认不可点击
                [_resetBtn setEnabled:false];
            }
        }else if ([resetObject  isEqual: @"美妆"]){
            if ([makeupstate  isEqual: @"optional"]) {
                [_resetBtn setEnabled:true];
            }else{
                [_resetBtn setEnabled:false];
            }
        }
        [_resetBtn setHidden:true];
    }
    return _resetBtn;
}

- (UIView *)masklayersView{
    if (!_masklayersView) {
        _masklayersView = [[UIView alloc] init];
        _masklayersView.backgroundColor = TI_RGB_Alpha(0.0, 0.0, 0.0, 0.4);
        [_masklayersView setHidden:true];
    }
    return _masklayersView;
}

- (UIView *)resetBgView{
    if (!_resetBgView) {
        _resetBgView = [[UIView alloc] init];
        _resetBgView.backgroundColor = TI_RGB_Alpha(255.0, 255.0, 255.0, 1.0);
        _resetBgView.layer.cornerRadius = 10;
        [_resetBgView setHidden:true];
    }
    return _resetBgView;
}

- (UILabel *)resetBgLabel{
    if(!_resetBgLabel){
        _resetBgLabel = [[UILabel alloc] init];
        _resetBgLabel.textColor = TI_RGB_Alpha(68.0, 68.0, 68.0, 1.0);
        _resetBgLabel.textAlignment = NSTextAlignmentCenter;
        _resetBgLabel.font = [UIFont fontWithName:@"PingFang-SC-Regular" size:15];
        _resetBgLabel.text = @"确定将所有参数值恢复默认吗？";
        [_resetBgLabel setHidden:true];
    }
    return _resetBgLabel;
}

- (UIButton *)reset_MY_YesBtn{
    if (!_reset_MY_YesBtn) {
        _reset_MY_YesBtn = [UIButton buttonWithType:0];
        _reset_MY_YesBtn.backgroundColor = TI_RGB_Alpha(255.0, 255.0, 255.0, 1.0);
        [_reset_MY_YesBtn setTitle:@"确定" forState:UIControlStateNormal];
        [_reset_MY_YesBtn setTitleColor: TI_RGB_Alpha(255.0, 255.0, 255.0, 1.0) forState:UIControlStateNormal];
        [_reset_MY_YesBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_reset_MY_YesBtn.titleLabel setFont:[UIFont fontWithName:@"PingFang-SC-Regular" size:16]];
        [_reset_MY_YesBtn addTarget:self action:@selector(ResetYNClick:) forControlEvents:UIControlEventTouchUpInside];
        [_reset_MY_YesBtn setBackgroundImage:[UIImage imageNamed:@"bg_chongzhi_yes.png" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] forState:UIControlStateNormal];
        [_reset_MY_YesBtn setHidden:true];
        [_reset_MY_YesBtn setEnabled:false];
    }
    return _reset_MY_YesBtn;
}

- (UIButton *)reset_MY_NoBtn{
    if (!_reset_MY_NoBtn) {
        _reset_MY_NoBtn = [UIButton buttonWithType:0];
        _reset_MY_NoBtn.backgroundColor = TI_RGB_Alpha(255.0, 255.0, 255.0, 1.0);
        [_reset_MY_NoBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_reset_MY_NoBtn setTitleColor:TI_RGB_Alpha(88.0, 221.0, 221.0, 1.0) forState:UIControlStateNormal];
        [_reset_MY_NoBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_reset_MY_NoBtn.titleLabel setFont:[UIFont fontWithName:@"PingFang-SC-Regular" size:16]];
        [_reset_MY_NoBtn addTarget:self action:@selector(ResetYNClick:) forControlEvents:UIControlEventTouchUpInside];
        _reset_MY_NoBtn.layer.borderWidth = 0.5;
        _reset_MY_NoBtn.layer.borderColor = TI_RGB_Alpha(88.0, 221.0, 221.0, 1.0).CGColor;
        _reset_MY_NoBtn.layer.cornerRadius = 20;
        [_reset_MY_NoBtn setHidden:true];
    }
    return _reset_MY_NoBtn;
}

//腮红、睫毛。。
- (UIView *)topView{
    if (!_topView) {
        _topView = [[UIView alloc] init];
        [_topView setBackgroundColor:TI_RGB_Alpha(45.0, 45.0, 45.0, 0.6)];
        [_topView setHidden:true];
    }
    return _topView;
}

- (UILabel *)topLabel{
    if (!_topLabel) {
        _topLabel = [[UILabel alloc] init];
        _topLabel.font = [UIFont fontWithName:@"PingFang-SC-Regular" size:13];
        _topLabel.textAlignment = NSTextAlignmentLeft;
        _topLabel.textColor = UIColor.whiteColor;
        [_topLabel setHidden:true];
    }
    return _topLabel;
}

//绿幕抠图编辑标题。。
- (UIView *)editView{
    if (!_editView) {
        _editView = [[UIView alloc] init];
        [_editView setBackgroundColor:TI_RGB_Alpha(45.0, 45.0, 45.0, 0.6)];
        [_editView setHidden:true];
    }
    return _editView;
}

- (UILabel *)editLabel{
    if (!_editLabel) {
        _editLabel = [[UILabel alloc] init];
        _editLabel.font = [UIFont fontWithName:@"PingFang-SC-Regular" size:13];
        _editLabel.textAlignment = NSTextAlignmentLeft;
        _editLabel.textColor = UIColor.whiteColor;
        [_editLabel setHidden:true];
    }
    return _editLabel;
}

- (void)setMakeUpTitle:(BOOL)is_hidden withName:(NSString *)name{
    if (is_hidden) {
        [self.topView setHidden:true];
        [self.topLabel setHidden:true];
    }else{
        [self.topView setHidden:false];
        [self.topLabel setText:name];
        [self.topLabel setHidden:false];
    }
}

- (void)setEditTitle:(BOOL)is_hidden withName:(NSString *)name{
    [self.editView setHidden:!is_hidden];
    [self.editLabel setHidden:!is_hidden];
    [self.editLabel setText:name];
    [self.menuView setHidden:is_hidden];
    [self.back2Btn setHidden:is_hidden];
    [self.lineView setHidden:is_hidden];
    [self.backView setHidden:is_hidden];
}

- (void)ResetClick:(UIButton *)sender{
    if ([resetObject  isEqual: @"美颜"]) {
        //美颜重置
        //弹出弹框
        [self.masklayersView setHidden:false];
        [self.resetBgView setHidden:false];
        [self.resetBgLabel setHidden:false];
        [self.reset_MY_YesBtn setHidden:false];
        [self.reset_MY_YesBtn setEnabled:true];
        [self.reset_MY_NoBtn setHidden:false];
        is_reset = true;
    }else if([resetObject  isEqual: @"美妆"]){
        //美妆重置
        //弹出弹框
        [self.masklayersView setHidden:false];
        [self.resetBgView setHidden:false];
        [self.resetBgLabel setHidden:false];
        [self.reset_MY_YesBtn setHidden:false];
        [self.reset_MY_YesBtn setEnabled:true];
        [self.reset_MY_NoBtn setHidden:false];
        is_reset = true;
    }
}

- (void)ResetYNClick:(UIButton *)sender{
    
    if (sender == _reset_MY_YesBtn) {
        //确认重置
        [self.masklayersView setHidden:true];
        [self.resetBgView setHidden:true];
        [self.resetBgLabel setHidden:true];
        [self.reset_MY_YesBtn setHidden:true];
        [self.reset_MY_NoBtn setHidden:true];
        if ([resetObject  isEqual: @"美颜"]) {
            is_resetBeauty = true;
            [[TiMenuPlistManager shareManager] reset:@"美颜重置"];
            //设置重置按钮状态
            [[NSUserDefaults standardUserDefaults] setObject:@"not_optional" forKey:@"beautystate"];
        }else if([resetObject  isEqual: @"美妆"]){
            [[TiMenuPlistManager shareManager] reset:@"美妆重置"];
            //设置重置按钮状态
            [[NSUserDefaults standardUserDefaults] setObject:@"not_optional" forKey:@"makeupstate"];
        }
        
        [self didSelectParentMenuCell:self.selectedIndexPath];
        //关闭重置功能
        [self.resetBtn setEnabled:false];
        is_reset = false;
    }else if (sender == _reset_MY_NoBtn){
        //取消重置
        [self.masklayersView setHidden:true];
        [self.resetBgView setHidden:true];
        [self.resetBgLabel setHidden:true];
        [self.reset_MY_YesBtn setHidden:true];
        [self.reset_MY_NoBtn setHidden:true];
        is_reset = false;
    }
    
}

//让超出父控件的方法触发响应事件
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *view = [super hitTest:point withEvent:event];
    
    if (!view) {
        //转换坐标系
        CGPoint newPointYes = [self.reset_MY_YesBtn convertPoint:point fromView:self];
        CGPoint newPointNo = [self.reset_MY_NoBtn convertPoint:point fromView:self];
        //判断触摸点是否在button上
        if (CGRectContainsPoint(self.reset_MY_YesBtn.bounds, newPointYes)) {
            //resetYesBtn就是我们想点击的控件，让这个控件作为可点击的view返回
            view = self.reset_MY_YesBtn;
        }
        if (CGRectContainsPoint(self.reset_MY_NoBtn.bounds, newPointNo)) {
            view = self.reset_MY_NoBtn;
        }
    }
    return view;
}

- (void)BackPrevious:(UIButton *)sender{
    
    [_backView setHidden:true];
    if (!self.resetBtn.hidden) {
        self.resetBtn.hidden = YES;
    }
    if (sender == _back2Btn) {
        [_back2Btn setHidden:true];
        [_lineView setHidden:true];
    }
    
    if ([TiUIManager shareManager].tiUIViewBoxView.isClassifyShow) {
        [[TiUIManager shareManager] popAllViews];
    }else{
        [[TiUIManager shareManager].tiUIViewBoxView showClassifyView];
    }

}

-(void)resetAllSetting {
    [TiMenuPlistManager.shareManager reset:@"美颜重置"];
}

- (UICollectionView *)menuView{
    if (!_menuView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        // 设置最小行间距
        layout.minimumLineSpacing = 0;
        _menuView =[[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_menuView setTag:10];
        _menuView.showsHorizontalScrollIndicator = NO;
        _menuView.backgroundColor = [UIColor hexStringToColor:@"aa000000"];
        _menuView.dataSource= self;
        _menuView.delegate = self;
        _menuView.contentInset = UIEdgeInsetsMake(0, 0, 0, 10);
        [_menuView registerClass:[TiUIMenuViewCell class] forCellWithReuseIdentifier:TiUIMenuViewCollectionViewCellId];
    }
    return _menuView;
}

- (UICollectionView *)subMenuView{
    if (!_subMenuView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(self.frame.size.width, TiUIViewBoxTotalHeight- TiUIMenuViewHeight - TiUISliderRelatedViewHeight-1);
        // 设置最小行间距
        layout.minimumLineSpacing = 0;
        _subMenuView =[[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_subMenuView setTag:20];
        _subMenuView.showsHorizontalScrollIndicator = NO;
        _subMenuView.backgroundColor = [UIColor hexStringToColor:@"aa000000"];
        _subMenuView.dataSource= self;
        _subMenuView.scrollEnabled = NO;//禁止滑动
        //注册多个cell 不重用，重用会导致嵌套的UICollectionView内的cell 错乱
        // FIXME: --json 数据完善后可再次尝试--
        for (TIMenuMode *mod in [TiMenuPlistManager shareManager].mainModeArr) {
            
            switch (mod.menuTag) {
                case 0:
                case 1:
                case 6:
                case 12:
                case 13:
                {
                    [_subMenuView registerClass:[TiUIMenuOneViewCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%ld",TiUISubMenuViewCollectionViewCellId,(long)mod.menuTag]];
                }
                    break;
                case 4:
                case 5:
                case 10:
                case 15:
                      {
                    [_subMenuView registerClass:[TiUIMenuTwoViewCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%ld",TiUISubMenuViewCollectionViewCellId,(long)mod.menuTag]];
                      }
                     break;
                case 2:
                case 3:
                case 7:
                case 8:
                case 9:
                case 11:
                case 14:
                case 16:
                       {
                     [_subMenuView registerClass:[TiUIMenuThreeViewCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%ld",TiUISubMenuViewCollectionViewCellId,(long)mod.menuTag]];
                        }
                    break;
                    
                default:
                {
                [_subMenuView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%ld",TiUISubMenuViewCollectionViewCellId,(long)mod.menuTag]];
                }
                    break;
            }
            
        }
    }
    return _subMenuView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView* resetBack = [[UIView alloc] init];
        resetBack.backgroundColor = UIColor.blackColor;
        [self addSubview:self.sliderRelatedView];//滑动条模块
        [self addSubview:self.backgroundView];
        [self.backgroundView addSubview:self.menuView];//美颜分割线上的一级菜单
        [self.backgroundView addSubview:self.subMenuView];//二级菜单
        [self.backgroundView addSubview:resetBack];
        [resetBack addSubview:self.resetAllBtn];
        [self.backgroundView addSubview:self.lineView];
        
        self.sliderRelatedView.hidden = YES;
        self.sliderRelatedView.tiContrastBtn.hidden = YES;
        self.sliderRelatedView.sliderLabelRight.hidden = NO;
        [self.sliderRelatedView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.equalTo(self);
            make.height.mas_offset(TiUISliderRelatedViewHeight);
        }];
        [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.top.equalTo(self.sliderRelatedView.mas_bottom);
        }];
        [self.menuView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(resetBack.mas_left).offset(0);
            make.top.equalTo(self.backgroundView);
            make.left.equalTo(self.backgroundView);
            make.height.mas_offset(TiUIMenuViewHeight);
        }];
        [self.subMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
              make.left.right.bottom.equalTo(self.backgroundView);
              make.top.equalTo(self.menuView.mas_bottom);
         }];

        [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-55);
            make.width.equalTo(@0.5);
            make.height.equalTo(@18);
            make.centerY.equalTo(self.menuView);
        }];

        //美妆
        [self addSubview:self.topView];
        [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.top.equalTo(self.backgroundView);
            make.left.equalTo(self.backgroundView);
            make.height.mas_offset(TiUIMenuViewHeight+0.5);
        }];
        [self addSubview:self.topLabel];
        [self.topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(30);
            make.centerY.equalTo(self.topView);
            make.width.equalTo(@50);
        }];
        //绿幕编辑
        [self addSubview:self.editView];
        [self.editView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.top.equalTo(self.backgroundView);
            make.left.equalTo(self.backgroundView);
            make.height.mas_offset(TiUIMenuViewHeight);
        }];
        [self addSubview:self.editLabel];
        [self.editLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(30);
            make.centerY.equalTo(self.editView);
            make.width.equalTo(@100);
        }];
        
        [resetBack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(0);
            make.top.mas_equalTo(self.menuView.mas_top);
            make.bottom.mas_equalTo(self.menuView.mas_bottom);
            make.width.mas_equalTo(60);
        }];
        
        [self.resetAllBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(0);
            make.top.mas_equalTo(0);
            make.bottom.mas_equalTo(0);
            make.width.mas_equalTo(resetBack.mas_width);
        }];
        //重置功能
        [self addSubview:self.masklayersView];
        [self addSubview:self.resetBgView];
        [self addSubview:self.resetBgLabel];
        [self.resetBgView addSubview:self.reset_MY_YesBtn];
        [self.resetBgView addSubview:self.reset_MY_NoBtn];
        [self.masklayersView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.right.equalTo(self);
            make.top.equalTo(self).offset(self.frame.size.height-SCREEN_HEIGHT);
        }];
        [self.resetBgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.masklayersView);
            make.centerX.equalTo(self.masklayersView);
            make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH*280/375, (SCREEN_WIDTH*280/375)*200/280));
        }];
        [self.resetBgLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.resetBgView).offset(40);
            make.centerX.equalTo(self.resetBgView);
            make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH*280/375, 15));
        }];
        [self.reset_MY_YesBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.resetBgView).offset(78);
            make.centerX.equalTo(self.resetBgView);
            make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH*180/375, (SCREEN_WIDTH*180/375)*40/180));
        }];
        [self.reset_MY_NoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.reset_MY_YesBtn.mas_bottom).offset(12);
            make.centerX.equalTo(self.resetBgView);
            make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH*180/375, (SCREEN_WIDTH*180/375)*40/180));
        }];
        
        self.classifyArr = @[@(10),@(4),@(0),@(1),@(13),@(6)];
        [self.menuView reloadData];
        [self.subMenuView reloadData];
        for (int i = 0; i<self.classifyArr.count; i++){
            NSNumber *menuTag = self.classifyArr[i];
            TIMenuMode *mode =  [[TiMenuPlistManager shareManager] mainModeArr][[menuTag intValue]];
            if (mode.selected)
            {
                NSIndexPath * menuIndex = [NSIndexPath indexPathForRow:i inSection:0];
                self.selectedIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [self.menuView scrollToItemAtIndexPath:menuIndex atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
             }
        }
        self.menuView.hidden = NO;
        self.subMenuView.hidden = NO;
        [self hiddenClassifyView];
    }
    return self;
}

 
#pragma mark ---UICollectionViewDataSource---
//设置每个section包含的item数目
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag==10) {
        return self.classifyArr.count;
    }else{
        return [[TiMenuPlistManager shareManager] mainModeArr].count;
    }
}

// 定义每个Cell的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag ==10) {
        int menuTag = [self.classifyArr[indexPath.row] intValue];
        TIMenuMode *mode =  [[TiMenuPlistManager shareManager] mainModeArr][menuTag];
        CGSize size = [self sizeWithString:mode.name font:[UIFont fontWithName:@"PingFang SC" size:14]];
        return CGSizeMake(size.width, TiUIMenuViewHeight);
    }else{
        return CGSizeMake(SCREEN_WIDTH, TiUIViewBoxTotalHeight- TiUIMenuViewHeight - TiUISliderRelatedViewHeight-1);
    }
}

//自适应大小
- (CGSize)sizeWithString:(NSString *)str font:(UIFont *)font
{
    CGSize maxSize = CGSizeMake(1000,2000);//设置最大容量
    NSDictionary *dict = @{NSFontAttributeName:font};
    CGSize size = [str boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:dict context:nil].size;//计算实际高度和宽度
    return size;
}

// 定义每个Section的四边间距
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (section == 0) {
        return UIEdgeInsetsMake(0, 30, 0, 0);
    }else{
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

// 两列cell之间的间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 36;
}

// 两行cell之间的间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 36;
}

 //返回对应indexPath的cell
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (collectionView.tag==10) {
        
        int menuTag = [self.classifyArr[indexPath.row] intValue];
        TIMenuMode *mode =  [[TiMenuPlistManager shareManager] mainModeArr][menuTag];
        TiUIMenuViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:TiUIMenuViewCollectionViewCellId forIndexPath:indexPath];
        if (mode.selected)
        {
             self.selectedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
             [self didSelectParentMenuCell:self.selectedIndexPath];
        }
        [cell setMenuMode:mode];
        
        return cell;
        
    }else if (collectionView.tag==20){
        
        TIMenuMode *mode = [[TiMenuPlistManager shareManager] mainModeArr][indexPath.row];
        switch (mode.menuTag) {
            case 0:
            case 1:
            case 6:
            case 12:
            case 13:
            {
                TiUIMenuOneViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%ld",TiUISubMenuViewCollectionViewCellId,(long)mode.menuTag] forIndexPath:indexPath];
                WeakSelf;
                [cell setClickOnCellBlock:^(NSInteger index) {
                    weakSelf.subindex = index;
                    [weakSelf setSliderTypeAndValue];
                    if (mode.menuTag==12) {
                        int thousand = (int)index/1000 *1000;//千
                        //设置美颜参数
                        [TiSetSDKParameters setBeautySlider:[TiSetSDKParameters getFloatValueForKey:thousand] forKey:thousand withIndex:index];
                            //保存选中的美妆
                        [TiSetSDKParameters setBeautyMakeupIndex:(int)index forKey:thousand];
                    }
                }];
                
                [cell setMakeupShowDisappearBlock:^(BOOL Hidden) {
                    if (Hidden) {
                        [weakSelf.sliderRelatedView setSliderHidden:YES];
                    }
                }];
                [cell setMode:mode];
                return cell;
            }
                break;

            case 4:
            case 5:
            case 10:
            case 15:
            {
                TiUIMenuTwoViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%ld",TiUISubMenuViewCollectionViewCellId,(long)mode.menuTag] forIndexPath:indexPath];
                WeakSelf;
                [cell setClickOnCellBlock:^(NSInteger index) {
                    weakSelf.subindex = index;
                    [weakSelf setSliderTypeAndValue];
                }];
                [cell setMode:mode];
               return cell;
            }
                break;
                
            case 2:
            case 3:
            case 7:
            case 8:
            case 9:
            case 11:
            case 14:
            case 16:
            {
                TiUIMenuThreeViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%ld",TiUISubMenuViewCollectionViewCellId,(long)mode.menuTag] forIndexPath:indexPath];
                [cell setMode:mode];
                return cell;
            }
                break;
                
            default:
            {
                UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%ld",TiUISubMenuViewCollectionViewCellId,(long)mode.menuTag] forIndexPath:indexPath];
                cell.backgroundColor = [UIColor orangeColor];
                return cell;
            }
                break;
        }
         
    }
        return nil;
}

#pragma mark ---UICollectionViewDelegate---
//选择了某个cell
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag ==10)
    {
        if(indexPath.row == self.selectedIndexPath.row) return;
        [self didSelectParentMenuCell:indexPath];
    }
}

- (void)didSelectParentMenuCell:(NSIndexPath *)indexPath{
    
    int menuTag = [self.classifyArr[indexPath.row] intValue];
    self.mainindex = menuTag;
    switch (menuTag) {
        case 0:
            for (TIMenuMode *mod in [TiMenuPlistManager shareManager].beautyModeArr) {
                if (mod.selected) {
                    self.subindex = mod.menuTag;
                }
            }
            [self.sliderRelatedView setSliderHidden:NO];
            [self setSliderTypeAndValue];
            break;
        case 1:
            for (TIMenuMode *mod in [TiMenuPlistManager shareManager].appearanceModeArr) {
                if (mod.selected) {
                    self.subindex = mod.menuTag;
                }
            }
            [self.sliderRelatedView setSliderHidden:NO];
            [self setSliderTypeAndValue];
            break;
        case 4:
            for (TIMenuMode *mod in [TiMenuPlistManager shareManager].filterModeArr) {
                if (mod.selected) {
                    self.subindex = mod.menuTag;
                }
            }
            [self.sliderRelatedView setSliderHidden:NO];
            [self setSliderTypeAndValue];
            break;
        case 10:
            for (TIMenuMode *mod in [TiMenuPlistManager shareManager].onekeyModeArr) {
                if (mod.selected) {
                    self.subindex = mod.menuTag;
                }
            }
            //强制开启美颜、美型
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NotificationName_TIUIMenuOne_isOpen" object:@(true)];
            [self.sliderRelatedView setSliderHidden:NO];
            [self setSliderTypeAndValue];
            break;
        case 11:
            for (TIMenuMode *mod in [TiMenuPlistManager shareManager].interactionsArr) {
                if (mod.selected) {
                    [[TiUIManager shareManager] setInteractionHintL:mod.hint];
                }
            }
            [self.sliderRelatedView setSliderHidden:YES];
            break;
        case 12:
           //显示重置按钮
           self.resetBtn.hidden = NO;
           [self setSliderTypeAndValue];
           [self.sliderRelatedView setSliderHidden:YES];
           break;
       case 13: //脸型
            for (TIMenuMode *mod in [TiMenuPlistManager shareManager].faceshapeModeArr) {
                if (mod.selected) {
                    self.subindex = mod.menuTag;
                    
                }
            }
            [self.sliderRelatedView setSliderHidden:NO];
            [self setSliderTypeAndValue];
            break;
       case 15://美发
            for (TIMenuMode *mod in [TiMenuPlistManager shareManager].hairdressModArr) {
                if (mod.selected) {
                    self.subindex = mod.menuTag;
                }
            }
            //隐藏重置按钮
            self.resetBtn.hidden = YES;
            [self.sliderRelatedView setSliderHidden:NO];
            [self setSliderTypeAndValue];
            break;
        case 16:
            for (TIMenuMode *mod in [TiMenuPlistManager shareManager].gesturesModArr) {
                if (mod.selected) {
                    [[TiUIManager shareManager] setInteractionHintL:mod.hint];
                }
            }
            [self.sliderRelatedView setSliderHidden:YES];
            break;
        default:
            [self.sliderRelatedView setSliderHidden:YES];
            break;
    }
    int selectedMenuTag = [self.classifyArr[self.selectedIndexPath.row] intValue];
    if (selectedMenuTag != menuTag) {
        [TiMenuPlistManager shareManager].mainModeArr   = [[TiMenuPlistManager shareManager] modifyAllWithSelectedindex:menuTag WithPath:@"TiMenu.json"];
        if(self.selectedIndexPath)
        {
            [self.menuView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
        }else{
            [self.menuView reloadItemsAtIndexPaths:@[indexPath]];
        }
        self.selectedIndexPath = indexPath;
    }
    
    NSIndexPath * submenuIndex = [NSIndexPath indexPathForRow:menuTag inSection:0];
    [self.subMenuView scrollToItemAtIndexPath:submenuIndex atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    
}

//设置滑动条参数
- (void)setSliderTypeAndValue{
    TiUISliderType sliderType = TI_UI_SLIDER_TYPE_ONE;
    TiUIDataCategoryKey categoryKey = TI_UIDCK_SKIN_WHITENING_SLIDER;
    
    if (self.mainindex==0) {
        NSInteger key = self.subindex;
        if (!is_resetBeauty) {
            TIMenuMode *mod = [TiMenuPlistManager shareManager].beautyModeArr[self.subindex];
            key = mod.menuTag;
        }
        is_resetBeauty = false;
        switch (key) {
            case 0:
                sliderType = TI_UI_SLIDER_TYPE_ONE;
                categoryKey = TI_UIDCK_SKIN_WHITENING_SLIDER;// 美白
                break;
            case 1:
                sliderType = TI_UI_SLIDER_TYPE_ONE;
                categoryKey = TI_UIDCK_SKIN_BLEMISH_REMOVAL_SLIDER;// 磨皮
                break;
            case 2:
                sliderType = TI_UI_SLIDER_TYPE_ONE;
                categoryKey = TI_UIDCK_SKIN_TENDERNESS_SLIDER;// 粉嫩
                break;
            case 3:
                sliderType = TI_UI_SLIDER_TYPE_ONE;
                categoryKey = TI_UIDCK_SKIN_SKINBRIGGT_SLIDER;// 清晰
                break;
            case 4:
                sliderType = TI_UI_SLIDER_TYPE_TWO;
                categoryKey = TI_UIDCK_SKIN_BRIGHTNESS_SLIDER;// 亮度
                break;
            case 5:
                sliderType = TI_UI_SLIDER_TYPE_ONE;
                categoryKey = TI_UIDCK_SKIN_PRECISE_BEAUTY_SLIDER;// 精准美肤
                break;
            default:
                break;
        }
    }else if (self.mainindex==1){
        categoryKey = (self.mainindex+1)*100 + self.subindex;
        switch (self.subindex) {
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
            case 6:
            case 13:
            case 17:
            case 22:
                sliderType = TI_UI_SLIDER_TYPE_ONE;
                break;
            case 5:
            case 7:
            case 8:
            case 9:
            case 10:
            case 11:
            case 12:
            case 14:
            case 15:
            case 16:
            case 18:
            case 19:
            case 20:
            case 21:
                sliderType = TI_UI_SLIDER_TYPE_TWO;
                break;
            default:
                break;
        }
    }else if (self.mainindex==4){
        
        sliderType = TI_UI_SLIDER_TYPE_ONE;
        categoryKey = (self.mainindex-1)*100 + self.subindex;
        if (self.subindex != 0) {
            [self.sliderRelatedView setSliderHidden:NO];
        }else{
            [self.sliderRelatedView setSliderHidden:YES];
        }
        
    }else if (self.mainindex == 9){
        
        if (is_greenEdit == 1) {
            sliderType = TI_UI_SLIDER_TYPE_TWO;
        }else{
            sliderType = TI_UI_SLIDER_TYPE_ONE;
        }
        categoryKey = 700 + is_greenEdit;
        [self.sliderRelatedView setSliderHidden:NO];
        
    }else if (self.mainindex==10){
        
        categoryKey = TI_UIDCK_ONEKEY_SLIDER;//一键美颜
        
    }else if (self.mainindex == 12){
        
        int thousand = (int)self.subindex/1000 *1000;//千
        categoryKey = thousand;//  对应key
        sliderType = TI_UI_SLIDER_TYPE_ONE;
        if (Default_is_Null) {
            [self.sliderRelatedView setSliderHidden:YES];
        }else{
            [self.sliderRelatedView setSliderHidden:NO];
        }
        
    }else if (self.mainindex==13){
        
        categoryKey = TI_UIDCK_FACESHAPE_SLIDER;//脸型
        
    }else if (self.mainindex==15){
        
        sliderType = TI_UI_SLIDER_TYPE_ONE;
        categoryKey = TI_UIDCK_HAIRDRESS_SLIDER;//美发
        if (self.subindex != 0) {
            [self.sliderRelatedView setSliderHidden:NO];
        }else{
            [self.sliderRelatedView setSliderHidden:YES];
        }
        
    }
    [self.sliderRelatedView.sliderView setSliderType:sliderType WithValue:[TiSetSDKParameters getFloatValueForKey:categoryKey]];
    self.sliderRelatedView.sliderLabel.text = [NSString stringWithFormat:@"%d%%",(int)(_sliderRelatedView.sliderView.minimumValue)];
    self.sliderRelatedView.sliderLabelRight.text = [NSString stringWithFormat:@"%d%%",(int)(_sliderRelatedView.sliderView.maximumValue)];
}

//返回 显示分类view
- (void)showClassifyView{
    self.backBtn.hidden = false;
    self.menuView.hidden = YES;
    self.subMenuView.hidden = YES;
    [self.classifyView showView];
}

- (void)hiddenClassifyView{
    [self.classifyView hiddenView];
}

- (void)dealloc{
    [TiMenuPlistManager releaseShareManager];
    [TiDownloadZipManager releaseShareManager];
    //移除通知
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
