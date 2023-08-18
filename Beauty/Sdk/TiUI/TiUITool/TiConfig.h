//
//  Header.h
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/2.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//
#import <TiSDK/TiSDKInterface.h>
#import <Masonry/Masonry.h>
#import "TiMenuPlistManager.h"

#import "TiUIManager.h"

//UI版本号
#define Current_TISDK_Version @"1.5"

//点击子菜单总开关按钮发出的通知
#define NotificationCenterSubMenuOnTotalSwitch @"NotificationCenterSubMenuOnTotalSwitch"

#define SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define WeakSelf __weak typeof(self) weakSelf = self;

#define getSafeBottomHeight ([[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom)

// MARK: --默认配置--
//字体
#define TI_Font_Default_Size_Small [UIFont fontWithName:@"Helvetica" size:10]
#define TI_Font_Default_Size_Medium [UIFont fontWithName:@"Helvetica" size:12]
#define TI_Font_Default_Size_Big [UIFont fontWithName:@"Helvetica" size:14]
//颜色
#define TI_Color_Default_Text_White [UIColor colorWithRed:254/255.0 green:254/255.0 blue:254/255.0 alpha:1.0]
#define TI_Color_Default_Text_Black [UIColor colorWithRed:(149)/255.0f green:(149)/255.0f blue:(149)/255.0f alpha:(1.0)]
#define TI_Color_Default_Background_Pink [UIColor colorWithRed:88/255.0 green:221/255.0 blue:221/255.0 alpha:1.0]

#define TI_RGB_Alpha(r, g, b, a) [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:(a)]


// MARK: --默认按钮的宽度(以拍照按钮为基准) TiUIDefaultButtonView--
#define DefaultButton_WIDTH SCREEN_WIDTH/4

 // MARK: --美颜弹框视图总高度 TiUIManager--
#define TiUIViewBoxTotalHeight ((178.0) + (TiUISliderRelatedViewHeight) + (UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom))
#define TiUIViewBoxTotalHeightN 250
// MARK: --美颜弹框视图总高度 TiUIManager--
//#define TiUIViewBoxTotalHeight SCREEN_HEIGHT/2.5

 // MARK:  滑动条View --TiUISliderRelatedView--
#define TiUISliderRelatedViewHeight 50
#define TiUIMenuViewHeight 62

//左右按钮的宽度
#define TiUISliderLeftRightWidth 55
// slider高度
#define TiUISliderHeight 3
#define TiUISliderTagViewWidth 34
#define TiUISliderTagViewHeight TiUISliderTagViewWidth * 1.2353 // 更具UI图得出的比例

// MARK:  子菜单状态1View --TiUISubMenuOneView--
#define TiUISubMenuOneViewTiButtonWidth 56
#define TiUISubMenuOneViewTiButtonHeight 100

#define TiUISubMenuTwoViewTiButtonWidth 60
#define TiUISubMenuTwoViewTiButtonHeight 80

#define TiUISubMenuThreeViewTiButtonWidth 62
#define TiUISubMenuThreeViewTiButtonHeight 62

// MARK: -- 与一键美颜中“标准” 类型参数一致
#define SkinWhiteningValue 70 // 美白滑动条默认参数
#define SkinBlemishRemovalValue 70 // 磨皮滑动条默认参数

#define SkinPreciseBeautyValue 0 // 精准美肤滑动条默认参数

#define SkinTendernessValue 40 // 粉嫩滑动条默认参数
#define SkinBrightnessValue 0 // 亮度滑动条默认参数，0表示无亮度效果，[-50, 0]表示降低亮度，[0, 50]表示提升亮度
#define SkinBrightValue 60 // 清晰滑动条默认参数，

#define EyeMagnifyingValue 60 // 大眼滑动条默认参数
#define ChinSlimmingValue 60 // 瘦脸滑动条默认参数
#define FaceNarrowingValue 15 // 窄脸滑动条默认参数
//脸部
#define CheekboneSlimmingValue 0 // 瘦颧骨滑动条默认参数
#define JawboneSlimmingValue 0 // 瘦下颌滑动条默认参数
#define JawTransformingValue 0 // 下巴滑动条默认参数
#define JawSlimmingValue 0 // 削下巴滑动条默认参数
#define ForeheadTransformingValue 0 // 额头滑动条默认参数
//眼部
#define EyeInnerCornersValue 0 // 内眼角滑动条默认参数
#define EyeOuterCornersValue 0 // 外眼尾滑动条默认参数
#define EyeSpacingValue 0 // 眼间距滑动条默认参数
#define EyeCornersValue 0 // 眼角滑动条默认参数
//鼻子
#define NoseMinifyingValue 0 // 瘦鼻滑动条默认参数
#define NoseElongatingValue 0 // 长鼻滑动条默认参数
//嘴巴
#define MouthTransformingValue 0 // 嘴型滑动条默认参数
#define MouthHeightValue 0 // 嘴高低滑动条默认参数
#define MouthLipSizeValue 0 // 唇厚薄滑动条默认参数
#define MouthSmilingValue 0 // 扬嘴角滑动条默认参数
//眉毛
#define BrowHeightValue 0 // 眉高低滑动条默认参数
#define BrowLengthValue 0 // 眉长短滑动条默认参数
#define BrowSpaceValue 0 // 眉间距滑动条默认参数
#define BrowSizeValue 0 // 眉粗细滑动条默认参数
#define BrowCornerValue 0 // 提眉峰滑动条默认参数

#define FilterValue 100 // 滤镜滑动条默认参数

#define OnewKeyBeautyValue 100 // 一键美颜
#define FaceShapeBeautyValue 100 // 脸型

#define SimilarityValue 0 //相似度滑动条默认参数
#define SmoothnessValue 0 //平滑度滑动条默认参数
#define AlphaValue 0 //透明度滑动条默认参数

#define CheekRedValue 100 //腮红默认参数
#define EyelashValue 100 //睫毛默认参数
#define EyebrowsValue 100 //眉毛默认参数
#define EyeshadowValue 100 //眼影默认参数
#define EyelineValue 100 //眼线默认参数
 
#define HairdressValue 100 //美发滑动条默认参数
