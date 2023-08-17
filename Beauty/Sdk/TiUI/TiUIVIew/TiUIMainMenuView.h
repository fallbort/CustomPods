//
//  TiUIMainMenuView.h
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/2.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TiUIClassifyView.h"
#import "TiUISliderRelatedView.h"

NS_ASSUME_NONNULL_BEGIN

// --- 全局变量 ---

//是否打开重置开关
extern bool is_reset;
//当前重置对象
extern NSString *resetObject;
//绿幕编辑
extern int is_greenEdit;

@interface TiUIMainMenuView : UIView

@property(nonatomic,assign) BOOL isClassifyShow;
@property(nonatomic,strong) UIButton *backBtn;
@property(nonatomic,strong) UIButton *back2Btn;
@property(nonatomic,strong) UIView *backView;
@property(nonatomic,strong) UIView *lineView;
@property(nonatomic,strong) UIButton *resetBtn;

//美颜菜单view
@property(nonatomic,strong) UICollectionView *menuView;
//美颜菜单view字体颜色
@property(nonatomic,strong) UIColor *_Nullable menuFontColor;
//滑块相关View
@property(nonatomic,strong) TiUISliderRelatedView  *sliderRelatedView;
//菜单view背景
@property(nonatomic,strong) UIView *backgroundView;
//新增UI美颜分类功能
@property(nonatomic,strong) TiUIClassifyView *classifyView;
//美颜分组菜单信息
@property(nonatomic,strong) NSArray *classifyArr;
//美颜菜单二级联动CollectionView子菜单
@property(nonatomic,strong) UICollectionView *subMenuView;
//重置功能界面
@property(nonatomic,strong) UIView * _Nullable masklayersView;
@property(nonatomic,strong) UIView * _Nullable resetBgView;
@property(nonatomic,strong) UILabel * _Nullable resetBgLabel;
@property(nonatomic,strong) UIButton * _Nullable reset_MY_YesBtn;
@property(nonatomic,strong) UIButton * _Nullable reset_MY_NoBtn;
//腮红、睫毛title。。
@property(nonatomic,strong)UIView *topView;
@property(nonatomic,strong)UILabel *topLabel;

- (void)showClassifyView;
- (void)hiddenClassifyView;
- (void)setMakeUpTitle:(BOOL)is_hidden withName:(NSString *)name;
- (void)setSliderTypeAndValue;
- (void)didSelectParentMenuCell:(NSIndexPath *)indexPath;
- (void)setEditTitle:(BOOL)is_hidden withName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
