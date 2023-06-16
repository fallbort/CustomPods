//
//  MGFaceIDLiveDetectCustomConfigItem.h
//  MGFaceIDLiveDetect
//
//  Created by MegviiDev on 2018/10/23.
//  Copyright © 2018年 Megvii. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MGFaceIDLiveDetectCustomConfigItem : NSObject

@property (nonatomic, strong) UIColor* livenessGuideRemindTextColor;    //  引导页提示文本颜色
@property (nonatomic, strong) UIColor* livenessGuideReadColor;          //  引导页已阅读文本颜色
@property (nonatomic, strong) UIColor* livenessDetectButtonTextColor;   //  引导页开始按钮文本颜色
@property (nonatomic, strong) UIColor* livenessDetectButtonSelectedBGColor;     //  引导页开始按钮已同意背景颜色
@property (nonatomic, strong) UIColor* livenessDetectButtonHighlightBGColor;    //  引导页开始按钮选中时背景颜色
@property (nonatomic, strong) UIColor* livenessDetectButtonNormalBGColor;       //  引导页开始按钮未同意背景颜色

@property (nonatomic, strong) UIColor* livenessHomeBackgroundColor;   //  背景色
@property (nonatomic, strong) UIColor* livenessHomeRingColor;         //  检测中圆环背景色
@property (nonatomic, strong) UIColor* livenessHomeProcessBarColor;   //  圆环进度颜色
@property (nonatomic, strong) UIColor* livenessHomeValidationFailProcessBarColor;  //  检测失败时圆环背景色
@property (nonatomic, strong) UIColor* livenessHomePromptColor;       //  提示文本字体颜色
@property (nonatomic, strong) UIColor* livenessHomePromptFlashColor;       //  炫彩阶段提示文本字体颜色
@property (nonatomic, assign) CGFloat livenessHomePromptSize;         //  提示文本字体大小
@property (nonatomic, strong) UIColor* livenessHomePromptCountDownColor;       //  动作活体倒计时文本字体颜色
@property (nonatomic, assign) CGFloat livenessHomePromptCountDownSize;         //  动作活体倒计时文本字体大小
@property (nonatomic, assign) CGFloat livenessGuideImageSize;    //  照镜子阶段静态引导图尺寸，宽高一致

@property (nonatomic, strong) UIColor* livenessExitTitlePromptColor;  //  退出弹框内容字体颜色
@property (nonatomic, assign) CGFloat livenessExitTitlePromptSize;    //  退出弹框内容字体大小

@property (nonatomic, strong) UIColor* livenessExit2HeadlineTextColor;  //  退出弹框风格2标题字体颜色
@property (nonatomic, strong) UIColor* livenessExit2MainTextColor;  //  退出弹框风格2内容字体颜色

@property (nonatomic, strong) UIColor* livenessExitLeftPromptColor;   //  退出弹框左按钮字体颜色
@property (nonatomic, assign) CGFloat livenessExitLeftPromptSize;     //  退出弹框左按钮字体大小
@property (nonatomic, strong) UIColor* livenessExitRightPromptColor;  //  退出弹框右按钮字体颜色
@property (nonatomic, assign) CGFloat livenessExitRightPromptSize;    //  退出弹框右按钮字体大小

@property (nonatomic, strong) UIColor* livenessExit2LeftTextColor;   //  退出弹框风格2左按钮字体颜色
@property (nonatomic, strong) UIColor* livenessExit2LeftButtonColor;   //  退出弹框风格2左按钮背景颜色
@property (nonatomic, strong) UIColor* livenessExit2LeftButtonBorderColor;   //  退出弹框风格2左按钮边框颜色
@property (nonatomic, strong) UIColor* livenessExit2RightTextColor;  //  退出弹框风格2右按钮字体颜色
@property (nonatomic, strong) UIColor* livenessExit2RightButtonColor;   //  退出弹框风格2右按钮背景颜色
@property (nonatomic, strong) UIColor* livenessExit2RightButtonBorderColor;    //  退出弹框风格2右按钮边框颜色

@property (nonatomic, strong) UIColor *livenessHomeUpperInfoTextFontColor;    // 检测页面提示文字颜色
@property (nonatomic, assign) CGFloat livenessHomeUpperInfoTextFontSize;    // 检测页面提示文字字体大小

@end

NS_ASSUME_NONNULL_END
