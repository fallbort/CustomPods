//
//  TiUIMenuThreeViewCell.m
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/6.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import "TiUIMenuThreeViewCell.h"
#import "TiConfig.h"
#import "TiUISubMenuThreeViewCell.h"
#import "TiDownloadZipManager.h"
#import "TiUIGreenScreensView.h"
#import "TiSetSDKParameters.h"
@import MeMeKit;

@interface TiUIMenuThreeViewCell ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property(nonatomic,strong) NSIndexPath *selectedIndexPath;
@property(nonatomic,strong) TiUIGreenScreensView *editGreenScreensView;
@property(nonatomic,strong) UIButton *backGreenBtn;//返回绿幕菜单

@end

static NSString *const TiUIMenuCollectionViewCellId = @"TiUIMainMenuTiUIMenuThreeViewCellId";

@implementation TiUIMenuThreeViewCell

- (UICollectionView *)menuCollectionView{
    if (!_menuCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.itemSize = CGSizeMake(TiUISubMenuThreeViewTiButtonWidth, TiUISubMenuThreeViewTiButtonHeight);
        // 设置最小行间距
        layout.minimumLineSpacing = 4;//最小行间距
        layout.minimumInteritemSpacing = 10;//同一列中间隔的cell最小间距
        _menuCollectionView =[[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _menuCollectionView.showsVerticalScrollIndicator = NO;
        _menuCollectionView.backgroundColor = [UIColor clearColor];
        _menuCollectionView.dataSource= self;
        _menuCollectionView.delegate = self;
        
        [_menuCollectionView registerClass:[TiUISubMenuThreeViewCell class] forCellWithReuseIdentifier:TiUIMenuCollectionViewCellId];
        
    }
    return _menuCollectionView;
}

- (TiUIGreenScreensView *)editGreenScreensView{
    if (!_editGreenScreensView) {
        _editGreenScreensView = [[TiUIGreenScreensView alloc] init];
        _editGreenScreensView.backgroundColor = [UIColor clearColor];
        [_editGreenScreensView setHidden:YES];
    }
    return _editGreenScreensView;
}

- (UIButton *)backGreenBtn{
    if (!_backGreenBtn) {
        _backGreenBtn = [[UIButton alloc] init];
        [_backGreenBtn setImage:[UIImage imageNamed:@"icon_back_white.png" inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] forState:UIControlStateNormal];
        [_backGreenBtn addTarget:self action:@selector(backGreen) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backGreenBtn;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self.contentView addSubview:self.menuCollectionView];
        [self.menuCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_top).offset(13.5);
            make.bottom.equalTo(self.mas_bottom).offset(-5);
            make.left.equalTo(self.contentView.mas_left).offset(12.5);
            make.right.equalTo(self.contentView.mas_right).offset(-12.5);
        }];
        
        [self.contentView addSubview:self.editGreenScreensView];
        [self.editGreenScreensView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_top).offset(13.5);
            make.bottom.equalTo(self.mas_bottom).offset(-5);
            make.left.equalTo(self.contentView.mas_left).offset(12.5);
            make.right.equalTo(self.contentView.mas_right).offset(-12.5);
        }];
        
        [self.editGreenScreensView addSubview:self.backGreenBtn];
        [self.backGreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.editGreenScreensView).offset(19);
            make.bottom.equalTo(self.editGreenScreensView.mas_bottom).offset(-16);
            make.width.height.equalTo(@18);
        }];
        
        //注册通知——通知当前是否启用第三套手势（绿幕编辑）
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isThirdGesture:) name:@"NotificationName_TiUIMenuThreeViewCell_isThirdGesture" object:nil];
        
    }
    return self;
}

#pragma mark ---UICollectionViewDataSource---
//设置每个section包含的item数目
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{

    switch (self.mode.menuTag) {
        case 2:
            return [TiMenuPlistManager shareManager].stickersModeArr.count;
            break;
        case 3:
            return [TiMenuPlistManager shareManager].giftModeArr.count;
            break;
        case 7:
            return [TiMenuPlistManager shareManager].watermarksModeArr.count;
            break;
        case 8:
            return [TiMenuPlistManager shareManager].masksModeArr.count;
            break;
        case 9:
            return [TiMenuPlistManager shareManager].greenscreensModeArr.count;
            break;
        case 11:
            return [TiMenuPlistManager shareManager].interactionsArr.count;
            break;
        case 14:
            return [TiMenuPlistManager shareManager].portraitsModArr.count;
            break;
        case 16:
            return [TiMenuPlistManager shareManager].gesturesModArr.count;
            break;
        default:
            return 0;
            break;
    }
    
}

//返回对应indexPath的cell
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
   TiUISubMenuThreeViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:TiUIMenuCollectionViewCellId forIndexPath:indexPath];
    TIMenuMode *subMod = nil;
    switch (self.mode.menuTag) {
        case 2:
        {
            subMod = [TiMenuPlistManager shareManager].stickersModeArr[indexPath.row];
            [cell setSubMod:subMod WithTag:2];
        }
            break;
        case 3:
        {
            subMod = [TiMenuPlistManager shareManager].giftModeArr[indexPath.row];
            [cell setSubMod:subMod WithTag:3];
        }
            break;
        case 7:
        {
            subMod = [TiMenuPlistManager shareManager].watermarksModeArr[indexPath.row];
            [cell setSubMod:subMod WithTag:7];
        }
            break;
        case 8:
        {
            subMod = [TiMenuPlistManager shareManager].masksModeArr[indexPath.row];
            [cell setSubMod:subMod WithTag:8];
        }
            break;
        case 9:
        {
            subMod = [TiMenuPlistManager shareManager].greenscreensModeArr[indexPath.row];
            [cell setSubMod:subMod WithTag:9];
        }
            break;
        case 11:
        {
            subMod = [TiMenuPlistManager shareManager].interactionsArr[indexPath.row];
            [cell setSubMod:subMod WithTag:11];
        }
            break;
        case 14:
        {
            subMod = [TiMenuPlistManager shareManager].portraitsModArr[indexPath.row];
            [cell setSubMod:subMod WithTag:14];
        }
            break;
        case 16:
        {
            subMod = [TiMenuPlistManager shareManager].gesturesModArr[indexPath.row];
            [cell setSubMod:subMod WithTag:16];
        }
            break;
        default:
            break;
    }
    if (subMod.selected)
    {
        self.selectedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    }
    return cell;
    
}

#pragma mark ---UICollectionViewDelegate---
//选择了某个cell
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.selectedIndexPath.row==indexPath.row) {
        return;//选中同一个cell不做处理
    }
    switch (self.mode.menuTag) {
        case 2:
        {
            TIMenuMode *mode = [TiMenuPlistManager shareManager].stickersModeArr[indexPath.row];
            if (mode.downloaded==TI_DOWNLOAD_STATE_CCOMPLET){
                
                [TiMenuPlistManager shareManager].stickersModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiStickers.json"];
                [TiMenuPlistManager shareManager].stickersModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiStickers.json"];
                if (self.selectedIndexPath) {
                    [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                }else{
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                self.selectedIndexPath = indexPath;
                [[TiSDKManager shareManager] setStickerName:mode.name];
                
            }else if (mode.downloaded==TI_DOWNLOAD_STATE_NOTBEGUN){
                
                // 开始下载
                [TiMenuPlistManager shareManager].stickersModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(TI_DOWNLOAD_STATE_BEBEING) forKey:@"downloaded" In:indexPath.row WithPath:@"TiStickers.json"];
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                WeakSelf;
                [[TiDownloadZipManager shareManager] downloadSuccessedType:TI_DOWNLOAD_TYPE_Sticker MenuMode:mode completeBlock:^(BOOL successful) {
                    DownloadedState state = TI_DOWNLOAD_STATE_BEBEING;
                    if (successful) {
                        // 开始下载
                        state = TI_DOWNLOAD_STATE_CCOMPLET;
                    }else{
                        state = TI_DOWNLOAD_STATE_NOTBEGUN;
                    }
                    [TiMenuPlistManager shareManager].stickersModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(state) forKey:@"downloaded" In:indexPath.row WithPath:@"TiStickers.json"];
                    [weakSelf.menuCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                }];
                
            }
        }
            break;
        case 3:
        {
            TIMenuMode *mode = [TiMenuPlistManager shareManager].giftModeArr[indexPath.row];
            if (mode.downloaded==TI_DOWNLOAD_STATE_CCOMPLET){
                
                [TiMenuPlistManager shareManager].giftModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiGifts.json"];
                [TiMenuPlistManager shareManager].giftModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiGifts.json"];
                if (self.selectedIndexPath) {
                    [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                }else{
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                self.selectedIndexPath = indexPath;
                [[TiSDKManager shareManager] setGift:mode.name];
            }else if (mode.downloaded==TI_DOWNLOAD_STATE_NOTBEGUN){
                
                // 开始下载
                [TiMenuPlistManager shareManager].giftModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(TI_DOWNLOAD_STATE_BEBEING) forKey:@"downloaded" In:indexPath.row WithPath:@"TiGifts.json"];
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                WeakSelf;
                [[TiDownloadZipManager shareManager] downloadSuccessedType:TI_DOWNLOAD_STATE_Gift MenuMode:mode completeBlock:^(BOOL successful) {
                    DownloadedState state = TI_DOWNLOAD_STATE_BEBEING;
                    if (successful) {
                        // 开始下载
                        state = TI_DOWNLOAD_STATE_CCOMPLET;
                    }else{
                        state = TI_DOWNLOAD_STATE_NOTBEGUN;
                    }
                    [TiMenuPlistManager shareManager].giftModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(state) forKey:@"downloaded" In:indexPath.row WithPath:@"TiGifts.json"];
                    [weakSelf.menuCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                }];
                
            }
        }
            break;
        case 7:
        {
            TIMenuMode *mode = [TiMenuPlistManager shareManager].watermarksModeArr[indexPath.row];
            if (mode.downloaded==TI_DOWNLOAD_STATE_CCOMPLET){
                
                [TiMenuPlistManager shareManager].watermarksModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiWaterMarks.json"];
                [TiMenuPlistManager shareManager].watermarksModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiWaterMarks.json"];
                if (self.selectedIndexPath) {
                    [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                }else{
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                self.selectedIndexPath = indexPath;
                if (indexPath.row)
                {
                    [[TiSDKManager shareManager] setWatermark:YES Left:(int)mode.x Top:(int)mode.y Ratio:(int)mode.ratio FileName:mode.name];
                }else{
                    [[TiSDKManager shareManager] setWatermark:NO Left:0 Top:0 Ratio:0 FileName:@"watermark.png"];
                }
            }else if (mode.downloaded==TI_DOWNLOAD_STATE_NOTBEGUN){
                
                // 开始下载
                [TiMenuPlistManager shareManager].watermarksModeArr  = [[TiMenuPlistManager shareManager] modifyObject:@(TI_DOWNLOAD_STATE_BEBEING) forKey:@"downloaded" In:indexPath.row WithPath:@"TiWaterMarks.json"];
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                WeakSelf;
                [[TiDownloadZipManager shareManager] downloadSuccessedType:TI_DOWNLOAD_STATE_Watermark MenuMode:mode completeBlock:^(BOOL successful) {
                    DownloadedState state = TI_DOWNLOAD_STATE_BEBEING;
                    if (successful) {
                        // 开始下载
                        state = TI_DOWNLOAD_STATE_CCOMPLET;
                        }else{
                            state = TI_DOWNLOAD_STATE_NOTBEGUN;
                        }
                        [TiMenuPlistManager shareManager].watermarksModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(state) forKey:@"downloaded" In:indexPath.row WithPath:@"TiWaterMarks.json"];
                        [weakSelf.menuCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                }];
                
            }
        }
            break;
        case 8:
        {
            TIMenuMode *mode = [TiMenuPlistManager shareManager].masksModeArr[indexPath.row];
            if (mode.downloaded==TI_DOWNLOAD_STATE_CCOMPLET){
                
                [TiMenuPlistManager shareManager].masksModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiMasks.json"];
                [TiMenuPlistManager shareManager].masksModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiMasks.json"];
                if (self.selectedIndexPath) {
                    [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                }else{
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                self.selectedIndexPath = indexPath;
                [[TiSDKManager shareManager] setMask:mode.name];
                
            }else if (mode.downloaded==TI_DOWNLOAD_STATE_NOTBEGUN){
                
                // 开始下载
                [TiMenuPlistManager shareManager].masksModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(TI_DOWNLOAD_STATE_BEBEING) forKey:@"downloaded" In:indexPath.row WithPath:@"TiMasks.json"];
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                  WeakSelf;
                [[TiDownloadZipManager shareManager] downloadSuccessedType:TI_DOWNLOAD_STATE_Mask MenuMode:mode completeBlock:^(BOOL successful) {
                       DownloadedState state = TI_DOWNLOAD_STATE_BEBEING;
                       if (successful) {
                           // 开始下载
                           state = TI_DOWNLOAD_STATE_CCOMPLET;
                       }else{
                           state = TI_DOWNLOAD_STATE_NOTBEGUN;
                       }
                    [TiMenuPlistManager shareManager].masksModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(state) forKey:@"downloaded" In:indexPath.row WithPath:@"TiMasks.json"];
                    [weakSelf.menuCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                }];
                
            }
        }
            break;
        case 9:
        {
            TIMenuMode *editMode = [TiMenuPlistManager shareManager].greenscreensModeArr[1];
            NSIndexPath *editPath = [NSIndexPath indexPathForRow:1 inSection:0];
            TiUISubMenuThreeViewCell *cell = (TiUISubMenuThreeViewCell *)[collectionView cellForItemAtIndexPath:editPath];
            if (indexPath.row == 1) {
                if ([cell isEdit]) {
                    [self.menuCollectionView setHidden:YES];
                    [[TiUIManager shareManager].tiUIViewBoxView setEditTitle:true withName:self.mode.name];
                    [self.editGreenScreensView setHidden:NO];
                    [[TiUIManager shareManager].tiUIViewBoxView setSliderTypeAndValue];
                    isswitch_greenEdit = true;
                }
                return;
            }
            if (indexPath.row == 0) {
                [cell setSubMod:editMode WithTag:9 isEnabled:NO];
            }else{
                [cell setSubMod:editMode WithTag:9 isEnabled:YES];
            }
            
            TIMenuMode *mode = [TiMenuPlistManager shareManager].greenscreensModeArr[indexPath.row];
            if (mode.downloaded==TI_DOWNLOAD_STATE_CCOMPLET){
                
                [TiMenuPlistManager shareManager].greenscreensModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiGreenScreens.json"];
                [TiMenuPlistManager shareManager].greenscreensModeArr   =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiGreenScreens.json"];
                if (self.selectedIndexPath) {
                    [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                }else{
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                self.selectedIndexPath = indexPath;
                [[TiSDKManager shareManager] setGreenScreen:mode.name Similarity:[TiSetSDKParameters getFloatValueForKey:TI_UIDCK_SIMILARITY_SLIDER] Smoothness:[TiSetSDKParameters getFloatValueForKey:TI_UIDCK_SMOOTH_SLIDER] Alpha:[TiSetSDKParameters getFloatValueForKey:TI_UIDCK_HYALINE_SLIDER]];
                
            }else if (mode.downloaded==TI_DOWNLOAD_STATE_NOTBEGUN){
                
                // 开始下载
                [TiMenuPlistManager shareManager].greenscreensModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(TI_DOWNLOAD_STATE_BEBEING) forKey:@"downloaded" In:indexPath.row WithPath:@"TiGreenScreens.json"];
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                WeakSelf;
                [[TiDownloadZipManager shareManager] downloadSuccessedType:TI_DOWNLOAD_STATE_Greenscreen MenuMode:mode completeBlock:^(BOOL successful) {
                   DownloadedState state = TI_DOWNLOAD_STATE_BEBEING;
                if (successful) {
                    // 开始下载
                    state = TI_DOWNLOAD_STATE_CCOMPLET;
                }else{
                    state = TI_DOWNLOAD_STATE_NOTBEGUN;
                }
                    [TiMenuPlistManager shareManager].greenscreensModeArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(state) forKey:@"downloaded" In:indexPath.row WithPath:@"TiGreenScreens.json"];
                    [weakSelf.menuCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                }];
                
            }
            
        }
            break;
        case 11:
        {
            TIMenuMode *mode = [TiMenuPlistManager shareManager].interactionsArr[indexPath.row];
            if (mode.downloaded==TI_DOWNLOAD_STATE_CCOMPLET){
                
                [TiMenuPlistManager shareManager].interactionsArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiInteractions.json"];
                [TiMenuPlistManager shareManager].interactionsArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiInteractions.json"];
                if (self.selectedIndexPath) {
                    [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                }else{
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                self.selectedIndexPath = indexPath;
                [[TiSDKManager shareManager] setInteraction:mode.name];
                [[TiUIManager shareManager] setInteractionHintL:mode.hint];
                
            }else if (mode.downloaded==TI_DOWNLOAD_STATE_NOTBEGUN){
                
                // 开始下载
                [TiMenuPlistManager shareManager].interactionsArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(TI_DOWNLOAD_STATE_BEBEING) forKey:@"downloaded" In:indexPath.row WithPath:@"TiInteractions.json"];
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                WeakSelf;
                [[TiDownloadZipManager shareManager] downloadSuccessedType:TI_DOWNLOAD_STATE_Interactions MenuMode:mode completeBlock:^(BOOL successful) {
                       DownloadedState state = TI_DOWNLOAD_STATE_BEBEING;
                       if (successful) {
                           // 开始下载
                           state = TI_DOWNLOAD_STATE_CCOMPLET;
                       }else{
                           state = TI_DOWNLOAD_STATE_NOTBEGUN;
                       }
                    [TiMenuPlistManager shareManager].interactionsArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(state) forKey:@"downloaded" In:indexPath.row WithPath:@"TiInteractions.json"];
                    [weakSelf.menuCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                }];
                
            }
            
        }
            break;
        case 14:
        {
            TIMenuMode *mode = [TiMenuPlistManager shareManager].portraitsModArr[indexPath.row];
            if (mode.downloaded==TI_DOWNLOAD_STATE_CCOMPLET){
                
                [TiMenuPlistManager shareManager].portraitsModArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiPortraits.json"];
                [TiMenuPlistManager shareManager].portraitsModArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiPortraits.json"];
                if (self.selectedIndexPath) {
                    [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                }else{
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                self.selectedIndexPath = indexPath;
                [[TiSDKManager shareManager] setPortrait:mode.name];
                
            }else if (mode.downloaded==TI_DOWNLOAD_STATE_NOTBEGUN){
                
                // 开始下载
                [TiMenuPlistManager shareManager].portraitsModArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(TI_DOWNLOAD_STATE_BEBEING) forKey:@"downloaded" In:indexPath.row WithPath:@"TiPortraits.json"];
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                WeakSelf;
                [[TiDownloadZipManager shareManager] downloadSuccessedType:TI_DOWNLOAD_STATE_Portraits MenuMode:mode completeBlock:^(BOOL successful) {
                    DownloadedState state = TI_DOWNLOAD_STATE_BEBEING;
                    if (successful) {
                        // 开始下载
                        state = TI_DOWNLOAD_STATE_CCOMPLET;
                    }else{
                        state = TI_DOWNLOAD_STATE_NOTBEGUN;
                    }
                    [TiMenuPlistManager shareManager].portraitsModArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(state) forKey:@"downloaded" In:indexPath.row WithPath:@"TiPortraits.json"];
                    [weakSelf.menuCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                }];
                
            }
        }
            break;
        case 16:
        {
            TIMenuMode *mode = [TiMenuPlistManager shareManager].gesturesModArr[indexPath.row];
            if (mode.downloaded==TI_DOWNLOAD_STATE_CCOMPLET){
                
                [TiMenuPlistManager shareManager].gesturesModArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(YES) forKey:@"selected" In:indexPath.row WithPath:@"TiGestures.json"];
                [TiMenuPlistManager shareManager].gesturesModArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(NO) forKey:@"selected" In:self.selectedIndexPath.row WithPath:@"TiGestures.json"];
                if (self.selectedIndexPath) {
                    [collectionView reloadItemsAtIndexPaths:@[self.selectedIndexPath,indexPath]];
                }else{
                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                self.selectedIndexPath = indexPath;
                [[TiSDKManager shareManager] setGesture:mode.name];
                [[TiUIManager shareManager] setInteractionHintL:mode.hint];
                
            }else if (mode.downloaded==TI_DOWNLOAD_STATE_NOTBEGUN){
                
                // 开始下载
                [TiMenuPlistManager shareManager].gesturesModArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(TI_DOWNLOAD_STATE_BEBEING) forKey:@"downloaded" In:indexPath.row WithPath:@"TiGestures.json"];
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                WeakSelf;
                [[TiDownloadZipManager shareManager] downloadSuccessedType:TI_DOWNLOAD_STATE_Gestures MenuMode:mode completeBlock:^(BOOL successful) {
                    DownloadedState state = TI_DOWNLOAD_STATE_BEBEING;
                    if (successful) {
                        // 开始下载
                        state = TI_DOWNLOAD_STATE_CCOMPLET;
                    }else{
                        state = TI_DOWNLOAD_STATE_NOTBEGUN;
                    }
                    [TiMenuPlistManager shareManager].gesturesModArr  =  [[TiMenuPlistManager shareManager] modifyObject:@(state) forKey:@"downloaded" In:indexPath.row WithPath:@"TiGestures.json"];
                    [weakSelf.menuCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                }];
                
            }
        }
            break;
        default:
            break;
    }
    
}

- (void)isThirdGesture:(NSNotification *)notification{
    
    NSNumber *isThirdN = notification.object;
    BOOL isThird =  [isThirdN boolValue];
    if (isThird) {
        [self backGreen];
    }
    
}

- (void)backGreen{
    [self.menuCollectionView setHidden:NO];
    [[TiUIManager shareManager].tiUIViewBoxView setEditTitle:false withName:@""];
    [self.editGreenScreensView setHidden:YES];
    [[TiUIManager shareManager].tiUIViewBoxView.sliderRelatedView setSliderHidden:YES];
    isswitch_greenEdit = false;
}

- (void)setMode:(TIMenuMode *)mode{
    if (mode) {
       _mode = mode;
      }
}

- (void)dealloc{
    //移除通知
   [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
