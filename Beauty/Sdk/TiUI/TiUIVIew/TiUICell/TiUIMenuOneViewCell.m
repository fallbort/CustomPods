//
//  TiUISubMenuOneViewCell.m
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/5.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import "TiUIMenuOneViewCell.h"
#import "TiButton.h"
#import "TiUISubMenuOneViewCell.h"
#import "TiUIMakeUpView.h"
#import "TiSetSDKParameters.h"
@import MeMeKit;

@interface TiUIMenuOneViewCell ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property(nonatomic,strong)TiButton *totalSwitch;
@property(nonatomic,strong)UIView *lineView;

@property(nonatomic,strong) NSIndexPath *selectedIndexPath;
@property(nonatomic,strong) NSIndexPath *FaceshapeIndexPath;

@property(nonatomic,strong)TiUIMakeUpView *meizhuangView;

@end

static NSString *const TiUIMenuCollectionViewCellId = @"TiUIMainMenuCollectionViewnOneCellId";

@implementation TiUIMenuOneViewCell
 
- (TiButton *)totalSwitch{
    if (!_totalSwitch) {
        _totalSwitch = [[TiButton alloc]initWithScaling:0.9];
        [_totalSwitch addTarget:self action:@selector(totalSwitch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _totalSwitch;
}

- (UIView *)lineView{
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = TI_Color_Default_Text_Black;
    }
    return _lineView;
}

- (UICollectionView *)menuCollectionView{
    if (!_menuCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        //设置最小行间距
        layout.minimumLineSpacing = 14;
        _menuCollectionView =[[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _menuCollectionView.showsHorizontalScrollIndicator = NO;
        _menuCollectionView.backgroundColor = [UIColor clearColor];
        _menuCollectionView.dataSource= self;
        _menuCollectionView.delegate = self;
       
        [_menuCollectionView registerClass:[TiUISubMenuOneViewCell class] forCellWithReuseIdentifier:TiUIMenuCollectionViewCellId];
    }
    return _menuCollectionView;
}

- (TiUIMakeUpView *)meizhuangView{
    if (!_meizhuangView) {
        _meizhuangView =[[TiUIMakeUpView alloc]init];
        WeakSelf;
        [_meizhuangView setClickOnCellBlock:^(NSInteger index) {
            if (weakSelf.clickOnCellBlock)
               {
                    weakSelf.clickOnCellBlock(index);
               }
        }];
        
        [_meizhuangView setMakeupShowDisappearBlock:^(BOOL Hidden) {
            if (weakSelf.makeupShowDisappearBlock)
            {
                weakSelf.makeupShowDisappearBlock(Hidden);
            }
        }];
        
        [_meizhuangView setBackBlock:^(BOOL is_back) {
            if(is_back){
                [[TiUIManager shareManager].tiUIViewBoxView.menuView setBackgroundColor:TI_RGB_Alpha(45.0, 45.0, 45.0, 0.6)];
                [[TiUIManager shareManager].tiUIViewBoxView.subMenuView setBackgroundColor:TI_RGB_Alpha(45.0, 45.0, 45.0, 0.6)];
                [weakSelf.meizhuangView setHidden:true];
                [weakSelf.menuCollectionView setHidden:false];
                [weakSelf.menuCollectionView reloadData];
                [weakSelf.totalSwitch setHidden:false];
                [weakSelf.lineView setHidden:false];
                [[TiUIManager shareManager].tiUIViewBoxView.menuView setHidden:false];

                [[TiUIManager shareManager].tiUIViewBoxView.backBtn setHidden:false];
                //显示重置
                [TiUIManager shareManager].tiUIViewBoxView.resetBtn.hidden = NO;
                [[TiUIManager shareManager].tiUIViewBoxView setMakeUpTitle:true withName:@""];
            }else{
                [weakSelf.menuCollectionView setHidden:true];
                [weakSelf.totalSwitch setHidden:true];
                [weakSelf.lineView setHidden:true];
                [[TiUIManager shareManager].tiUIViewBoxView.menuView setHidden:true];
                [[TiUIManager shareManager].tiUIViewBoxView.subMenuView setBackgroundColor:UIColor.clearColor];
                [[TiUIManager shareManager].tiUIViewBoxView.backBtn setHidden:true];
                
                [weakSelf.meizhuangView setBackgroundColor:TI_RGB_Alpha(45.0, 45.0, 45.0, 0.6)];
                [[TiUIManager shareManager].tiUIViewBoxView.topView setBackgroundColor:TI_RGB_Alpha(45.0, 45.0, 45.0, 0.6)];
                [[TiUIManager shareManager].tiUIViewBoxView.topLabel setTextColor:[UIColor whiteColor]];
                [weakSelf.meizhuangView.defaultBtn setImage:[UIImage imageNamed:@"meizhuang_wu_normal_white.png" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] forState:UIControlStateNormal];
                if (Default_is_Null) {
                    [weakSelf.meizhuangView.defaultLabel setTextColor:TI_RGB_Alpha(88.0, 221.0, 221.0, 1.0)];
                }else{
                    [weakSelf.meizhuangView.defaultLabel setTextColor:UIColor.whiteColor];
                }
                [weakSelf.meizhuangView setHidden:false];
                //隐藏重置
                [TiUIManager shareManager].tiUIViewBoxView.resetBtn.hidden = YES;
            }
        }];
        
    }
    return _meizhuangView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self addSubview:self.menuCollectionView];

        CGFloat safeBottomHeigh = 0.0f;
        if (@available(iOS 11.0, *)) {
            safeBottomHeigh = getSafeBottomHeight/2;
        }
    
        [self.menuCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(16);
            make.right.equalTo(self.mas_right).offset(-16);
            make.height.mas_equalTo(TiUISubMenuOneViewTiButtonHeight);
            make.top.equalTo(self).offset(1);
        }];
        [self addSubview:self.meizhuangView];
        [self.meizhuangView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        //注册通知——通知是否强制开启美颜美型
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(totalStatus:) name:@"NotificationName_TIUIMenuOne_isOpen" object:nil];
        //注册通知——通知是否重置脸型
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetFaceshape:) name:@"NotificationName_TIUIMenuOne_isReset" object:nil];
    }
    return self;
}

#pragma mark ---UICollectionViewDataSource---
//设置每个section包含的item数目
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    switch (self.mode.menuTag) {
        case 0:
            return [TiMenuPlistManager shareManager].beautyModeArr.count;
            break;
        case 1:
            return [TiMenuPlistManager shareManager].appearanceModeArr.count;
            break;
        case 6:
            return [TiMenuPlistManager shareManager].distortionModeArr.count;
            break;
        case 12:
            return [TiMenuPlistManager shareManager].makeupModArr.count;
            break;
        case 13:
            return [TiMenuPlistManager shareManager].faceshapeModeArr.count;
            break;
        default:
            return 0;
            break;
    }
}

// 定义每个Cell的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    TIMenuMode *subMod = nil;
    switch (self.mode.menuTag) {
        case 0:
        {
            subMod = [TiMenuPlistManager shareManager].beautyModeArr[indexPath.row];
        }
            break;
        case 1:
        {
            subMod = [TiMenuPlistManager shareManager].appearanceModeArr[indexPath.row];
        }
            break;
        case 6:
        {
            subMod = [TiMenuPlistManager shareManager].distortionModeArr[indexPath.row];
        }
            break;
        case 12:
        {
            subMod = [TiMenuPlistManager shareManager].makeupModArr[indexPath.row];
        }
            break;
        case 13:
        {
            subMod = [TiMenuPlistManager shareManager].faceshapeModeArr[indexPath.row];
        }
            break;
        default:
            break;
    }
    //美型分类单独判断
    if (self.mode.menuTag == 1 && [subMod.normalThumb  isEqual: @""]) {
        return CGSizeMake(30,TiUISubMenuOneViewTiButtonHeight);
    }else{
        return CGSizeMake(TiUISubMenuOneViewTiButtonWidth ,TiUISubMenuOneViewTiButtonHeight);
    }
    
}

//返回对应indexPath的cell
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    TiUISubMenuOneViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:TiUIMenuCollectionViewCellId forIndexPath:indexPath];
    switch (self.mode.menuTag) {
        case 0:
        {
            TIMenuMode * subMod = [[TiMenuPlistManager shareManager].beautyModeArr objectAtIndex:indexPath.row];
            if (subMod.selected)
            {
                self.selectedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
            }
            [cell setSubMod:subMod];
        }
            break;
        case 1:
        {
            TIMenuMode * subMod = [[TiMenuPlistManager shareManager].appearanceModeArr objectAtIndex:indexPath.row];
            if (subMod.selected)
            {
                self.selectedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
            }
            [cell setSubMod:subMod];
        }
            break;
        case 6:
        {
            //哈哈更新约束
            [self.totalSwitch setHidden:true];
            [self.lineView setHidden:true];
            [self.menuCollectionView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self).offset(40);
                make.right.equalTo(self).offset(-43);
            }];
            TIMenuMode * subMod = [[TiMenuPlistManager shareManager].distortionModeArr objectAtIndex:indexPath.row];
            if (subMod.selected)
                {
                    self.selectedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
                }
            subMod = [TiMenuPlistManager shareManager].distortionModeArr[indexPath.row];
            [cell setSubMod:subMod];
        }
            break;
        case 12:
        {
            [[TiUIManager shareManager].tiUIViewBoxView.sliderRelatedView setSliderHidden:YES];
            TIMenuMode * subMod = [[TiMenuPlistManager shareManager].makeupModArr objectAtIndex:indexPath.row];
            if (subMod.selected)
            {
                self.selectedIndexPath = nil;
            }
            [cell setSubMod:subMod];
        }
            break;
        case 13:
        {
            //脸型时更新约束
            [self.totalSwitch setHidden:true];
            [self.lineView setHidden:true];
            [self.menuCollectionView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self).offset(40);
                make.right.equalTo(self).offset(-43);
            }];
            TIMenuMode * subMod = [[TiMenuPlistManager shareManager].faceshapeModeArr objectAtIndex:indexPath.row];
            if (subMod.selected)
            {
                self.FaceshapeIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
            }
            [cell setSubMod:subMod];
        }
            break;
            
        default:
            break;
    }
    
    return cell;
         
}

//判断默认按钮状态
- (BOOL)is_selected{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.meizhuangView.mode.menuTag == 1) {
        NSString *cheekRed_default = [defaults objectForKey:@"cheekRed_default"];
        if (![cheekRed_default  isEqual: @"腮红"]) {
            return true;
        }else{
            return false;
        }
    }else if (self.meizhuangView.mode.menuTag == 2) {
        NSString *eyelash_default = [defaults objectForKey:@"eyelash_default"];
        if (![eyelash_default  isEqual: @"睫毛"]) {
            return true;
        }else{
            return false;
        }
    }else if (self.meizhuangView.mode.menuTag == 3) {
        NSString *eyebrows_default = [defaults objectForKey:@"eyebrows_default"];
        if (![eyebrows_default  isEqual: @"眉毛"]) {
            return true;
        }else{
            return false;
        }
    }else if (self.meizhuangView.mode.menuTag == 4) {
        NSString *eyeshadow_default = [defaults objectForKey:@"eyeshadow_default"];
        if (![eyeshadow_default  isEqual: @"眼影"]) {
            return true;
        }else{
            return false;
        }
    }else if (self.meizhuangView.mode.menuTag == 5) {
        NSString *eyeLine_default = [defaults objectForKey:@"eyeLine_default"];
        if (![eyeLine_default  isEqual: @"眼线"]) {
            return true;
        }else{
            return false;
        }
    }
    return true;
}

- (void)resetFaceshape:(NSNotification *)notification{

    NSIndexPath *IndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    if (self.FaceshapeIndexPath.row != 0) {
        if (self.clickOnCellBlock)
        {
          self.clickOnCellBlock(IndexPath.row);
        }
        [TiMenuPlistManager shareManager].faceshapeModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:IndexPath.row WithPath:@"TiFaceShape.json"];
        [TiMenuPlistManager shareManager].faceshapeModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.FaceshapeIndexPath.row WithPath:@"TiFaceShape.json"];
        if (self.FaceshapeIndexPath) {
            [self.menuCollectionView reloadItemsAtIndexPaths:@[self.FaceshapeIndexPath,IndexPath]];
        }else{
            [self.menuCollectionView reloadItemsAtIndexPaths:@[IndexPath]];
        }
        self.FaceshapeIndexPath = IndexPath;
    }
    
}

#pragma mark ---UICollectionViewDelegate---
//选择了某个cell
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    TIMenuMode *modX = [TiMenuPlistManager shareManager].appearanceModeArr[indexPath.row];
    //美型分类单独判断
    if (self.mode.menuTag == 1 && (indexPath.row == 3 || indexPath.row == 9 || indexPath.row == 14 || indexPath.row == 17 || indexPath.row == 22)) {
        return;
    }else{
        if (self.mode.menuTag ==12) {
            isswitch_makeup = true;
            [[TiUIManager shareManager].tiUIViewBoxView.backView setHidden:true];
            [self.meizhuangView setHiddenAnimation:NO];
            self.meizhuangView.mode = [[TiMenuPlistManager shareManager].makeupModArr objectAtIndex:indexPath.row];
            
            if (self.makeupShowDisappearBlock) {
                self.makeupShowDisappearBlock(NO);
            }
            //设置默认按钮状态
            Default_is_Null = [self is_selected];
            //判断默认按钮状态
            if (Default_is_Null) {
                [self.meizhuangView.defaultBtn setSelected:true];
                [self.meizhuangView.defaultLabel setTextColor:TI_RGB_Alpha(88.0, 221.0, 221.0, 1.0)];
            }else{
                [self.meizhuangView.defaultBtn setSelected:false];
                [self.meizhuangView.defaultLabel setTextColor:UIColor.whiteColor];
            }
            //单独设置文字
            self.meizhuangView.backBlock(NO);
            //是否已重置
            if (makeup_is_reset == true) {
    //            [self.meizhuangView defaultselected:self.meizhuangView.defaultBtn];
                makeup_is_reset = false;
            }
            //是否显示滑动条
            if (Default_is_Null) {
                [[TiUIManager shareManager].tiUIViewBoxView.sliderRelatedView setSliderHidden:YES];
            }else{
                [[TiUIManager shareManager].tiUIViewBoxView.sliderRelatedView setSliderHidden:NO];
            }
            [[TiUIManager shareManager].tiUIViewBoxView setMakeUpTitle:false withName:self.meizhuangView.mode.name];
            return;
        }
        if (self.clickOnCellBlock)
        {
            if (self.mode.menuTag != 1){
                self.clickOnCellBlock(indexPath.row);
            }else{
                self.clickOnCellBlock(modX.menuTag);
            }
        }
        if (self.mode.menuTag == 13) {
            if (indexPath.row == self.FaceshapeIndexPath.row)
            {
                return;
            }else{
                [TiMenuPlistManager shareManager].faceshapeModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiFaceShape.json"];
                [TiMenuPlistManager shareManager].faceshapeModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.FaceshapeIndexPath.row WithPath:@"TiFaceShape.json"];
                if (self.FaceshapeIndexPath) {
                    [collectionView reloadItemsAtIndexPaths:@[self.FaceshapeIndexPath,indexPath]];
                }else{
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                self.FaceshapeIndexPath = indexPath;
                [TiSetSDKParameters setBeautySlider:[TiSetSDKParameters getFloatValueForKey:TI_UIDCK_FACESHAPE_SLIDER] forKey:TI_UIDCK_FACESHAPE_SLIDER withIndex:indexPath.row];
            }
            return;
        }else{
            if(indexPath.row == self.selectedIndexPath.row)
            {
                return;
            }
            switch (self.mode.menuTag) {
                case 0:
                {
                    [TiMenuPlistManager shareManager].beautyModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiBeauty.json"];
                    [TiMenuPlistManager shareManager].beautyModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiBeauty.json"];
                    if (self.selectedIndexPath) {
                        [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                    }else{
                        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                    }
                    self.selectedIndexPath = indexPath;
                    
                    TIMenuMode *mod = [TiMenuPlistManager shareManager].beautyModeArr[indexPath.row];
                    [TiSetSDKParameters setBeautySlider:[TiSetSDKParameters getFloatValueForKey:(100 + mod.menuTag)] forKey:(100 + mod.menuTag) withIndex:indexPath.row];
                    
                }
                    break;
                case 1:
                {
                    [TiMenuPlistManager shareManager].appearanceModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiAppearance.json"];
                    [TiMenuPlistManager shareManager].appearanceModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiAppearance.json"];
                    if (self.selectedIndexPath) {
                        [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                    }else{
                        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                    }
                    self.selectedIndexPath = indexPath;
                }
                    break;
                case 6:
                {
                    [TiMenuPlistManager shareManager].distortionModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiDistortion.json"];
                    [TiMenuPlistManager shareManager].distortionModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiDistortion.json"];
                    if (self.selectedIndexPath) {
                        [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                    }else{
                        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                    }
                    self.selectedIndexPath = indexPath;
                    [[TiSDKManager shareManager] setDistortionEnum:[TiSetSDKParameters setDistortionEnumByIndex:indexPath.row]];
                }
                    break;
                default:
                    break;
            }
            
        }
        
    }
    
}

- (void)totalStatus:(NSNotification *)notification{
    
    NSNumber *successN = notification.object;
    BOOL success =  [successN boolValue];
    if (self.mode.menuTag == 0 || self.mode.menuTag == 1) {
        [TiMenuPlistManager shareManager].mainModeArr  = [[TiMenuPlistManager shareManager] modifyObject:@(success) forKey:@"totalSwitch" In:self.mode.menuTag WithPath:@"TiMenu.json"];
        TIMenuMode *newMod = [TiMenuPlistManager shareManager].mainModeArr[self.mode.menuTag];
        _mode = newMod;
        [self.totalSwitch setSelected:newMod.totalSwitch];
        [[TiSDKManager shareManager] setBeautyEnable:success];
        [[TiSDKManager shareManager] setFaceTrimEnable:success];
    }
    
}

- (void)dealloc{
    //移除通知
   [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)totalSwitch:(TiButton *)sender{
    
  [TiMenuPlistManager shareManager].mainModeArr  = [[TiMenuPlistManager shareManager] modifyObject:@(!self.mode.totalSwitch) forKey:@"totalSwitch" In:self.mode.menuTag WithPath:@"TiMenu.json"];
    TIMenuMode *newMod = [TiMenuPlistManager shareManager].mainModeArr[self.mode.menuTag];
    _mode = newMod;
    [self.totalSwitch setSelected:newMod.totalSwitch];
    
    if (newMod.menuTag ==0)
    {
        [[TiSDKManager shareManager] setBeautyEnable:newMod.totalSwitch];
    }
    else if(newMod.menuTag==1)
    {
        [[TiSDKManager shareManager] setFaceTrimEnable:newMod.totalSwitch];
    }
    else if(newMod.menuTag==12)
    {
        [[TiSDKManager shareManager] setMakeupEnable:newMod.totalSwitch];
    }
    
}

- (void)setMode:(TIMenuMode *)mode{
    if (mode) {
       _mode = mode;
        [self.totalSwitch setTitle:[NSString stringWithFormat:@"%@:关",mode.name] withImage:[UIImage imageNamed:@"btn_close" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] withTextColor:TI_Color_Default_Text_Black forState:UIControlStateNormal];
        [self.totalSwitch setTitle:[NSString stringWithFormat:@"%@:开",mode.name] withImage:[UIImage imageNamed:@"btn_open" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] withTextColor:TI_Color_Default_Background_Pink forState:UIControlStateSelected];
        [self.totalSwitch setSelected:mode.totalSwitch];
        
        [self.menuCollectionView reloadData];
    }
    
}

@end
