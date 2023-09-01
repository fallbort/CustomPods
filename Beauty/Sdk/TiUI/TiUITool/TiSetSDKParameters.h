//
//  TiSetSDKParameters.h
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/10.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TiConfig.h"
#import <TiSDK/TiSDKInterface.h>

//全局变量——用于判断是否同步滤镜
extern bool is_updateFilter;
extern bool is_updateFilterValue;

@interface TiSetSDKParameters : NSObject

#pragma mark -- UI保存参数时使用到的键值枚举
typedef NS_ENUM(NSInteger, TiUIDataCategoryKey) {
    
    TI_UIDCK_SKIN_WHITENING_SLIDER = 100, // 美白滑动条
    TI_UIDCK_SKIN_BLEMISH_REMOVAL_SLIDER = 101, // 磨皮滑动条
    
    TI_UIDCK_SKIN_PRECISE_BEAUTY_SLIDER = 105, //精准美肤滑动条

    TI_UIDCK_SKIN_TENDERNESS_SLIDER = 102, // 粉嫩滑动条
    TI_UIDCK_SKIN_SKINBRIGGT_SLIDER = 103, // 清晰滑动条
    TI_UIDCK_SKIN_BRIGHTNESS_SLIDER = 104, // 亮度滑动条
    
    TI_UIDCK_EYEMAGNIFYING_SLIDER = 200, // 大眼滑动条
    TI_UIDCK_CHINSLIMMING_SLIDER = 201, // 瘦脸滑动条
    TI_UIDCK_FACENARROWING_SLIDER = 202, // 窄脸滑动条
    //脸部
    TI_UIDCK_CHEEKBONESLIMMING_SLIDER = 203, // 瘦颧骨滑动条
    TI_UIDCK_JAWBONESLIMMING_SLIDER = 204, // 瘦下颌滑动条
    TI_UIDCK_JAWTRANSFORMING_SLIDER = 205, // 下巴滑动条
    TI_UIDCK_JAWSLIMMING_SLIDER = 206, // 削下巴滑动条
    TI_UIDCK_FOREHEADTRANSFORMING_SLIDER = 207, // 额头滑动条
    //眼部
    TI_UIDCK_EYEINNERCORNERS_SLIDER = 208, // 内眼角滑动条
    TI_UIDCK_EYEOUTERCORNERS_SLIDER = 209, //外眼尾滑动条
    TI_UIDCK_EYESPACING_SLIDER = 210, // 眼间距滑动条
    TI_UIDCK_EYECORNERS_SLIDER = 211, // 眼角滑动条
    //鼻子
    TI_UIDCK_NOSEMINIFYING_SLIDER = 212, // 瘦鼻滑动条
    TI_UIDCK_NOSEELONGATING_SLIDER = 213, // 长鼻滑动条
    //嘴巴
    TI_UIDCK_MOUTHTRANSFORMING_SLIDER = 214, // 嘴型滑动条
    TI_UIDCK_MOUTHHEIGHT_SLIDER = 215, // 嘴高低滑动条
    TI_UIDCK_MOUTHLIPSIZE_SLIDER = 216, // 唇厚薄滑动条
    TI_UIDCK_MOUTHSMILING_SLIDER = 217, // 扬嘴角滑动条
    //眉毛
    TI_UIDCK_BROWHEIGHT_SLIDER = 218, // 眉高低滑动条
    TI_UIDCK_BROWLENGTH_SLIDER = 219, // 眉长短滑动条
    TI_UIDCK_BROWSPACE_SLIDER = 220, // 眉间距滑动条
    TI_UIDCK_BROWSIZE_SLIDER = 221, // 眉粗细滑动条
    TI_UIDCK_BROWCORNER_SLIDER = 222, // 提眉峰滑动条
    
    TI_UIDCK_FILTER0_SLIDER = 300,// 原图滤镜滑动条
    //自然
    TI_UIDCK_FILTER1_SLIDER = 301,// 素颜滤镜滑动条
    TI_UIDCK_FILTER2_SLIDER = 302,// 绯樱滤镜滑动条
    TI_UIDCK_FILTER3_SLIDER = 303,// 浅杏滤镜滑动条
    TI_UIDCK_FILTER4_SLIDER = 304,// 蔷薇滤镜滑动条
    TI_UIDCK_FILTER5_SLIDER = 305,// 青柠滤镜滑动条
    TI_UIDCK_FILTER6_SLIDER = 306,// 珍珠滤镜滑动条
    TI_UIDCK_FILTER7_SLIDER = 307,// 暖春滤镜滑动条
    //清透
    TI_UIDCK_FILTER8_SLIDER = 308,// 清晰滤镜滑动条
    TI_UIDCK_FILTER9_SLIDER = 309,// 牛奶滤镜滑动条
    TI_UIDCK_FILTER10_SLIDER = 310,// 水雾滤镜滑动条
    TI_UIDCK_FILTER11_SLIDER = 311,// 盐系滤镜滑动条
    TI_UIDCK_FILTER12_SLIDER = 312,// 水光滤镜滑动条
    TI_UIDCK_FILTER13_SLIDER = 313,// 奶杏滤镜滑动条
    //元气
    TI_UIDCK_FILTER14_SLIDER = 314,// 少女滤镜滑动条
    TI_UIDCK_FILTER15_SLIDER = 315,// 白桃滤镜滑动条
    TI_UIDCK_FILTER16_SLIDER = 316,// 日系滤镜滑动条
    TI_UIDCK_FILTER17_SLIDER = 317,// 粉夏滤镜滑动条
    TI_UIDCK_FILTER18_SLIDER = 318,// 甜美滤镜滑动条
    TI_UIDCK_FILTER19_SLIDER = 319,// 奶油滤镜滑动条
    TI_UIDCK_FILTER20_SLIDER = 320,// 日杂滤镜滑动条
    TI_UIDCK_FILTER21_SLIDER = 321,// 奶油蜜桃滤镜滑动条
    TI_UIDCK_FILTER22_SLIDER = 322,// 橘子汽水滤镜滑动条
    //高级
    TI_UIDCK_FILTER23_SLIDER = 323,// 灰调滤镜滑动条
    TI_UIDCK_FILTER24_SLIDER = 324,// 冷淡滤镜滑动条
    TI_UIDCK_FILTER25_SLIDER = 325,// 花颜滤镜滑动条
    TI_UIDCK_FILTER26_SLIDER = 326,// 质感滤镜滑动条
    TI_UIDCK_FILTER27_SLIDER = 327,// 济州滤镜滑动条
    //氛围
    TI_UIDCK_FILTER28_SLIDER = 328,// 油画1滤镜滑动条
    TI_UIDCK_FILTER29_SLIDER = 329,// 油画2滤镜滑动条
    TI_UIDCK_FILTER30_SLIDER = 330,// 森系滤镜滑动条
    TI_UIDCK_FILTER31_SLIDER = 331,// 仲夏梦滤镜滑动条
    //美食
    TI_UIDCK_FILTER32_SLIDER = 332,// 美味滤镜滑动条
    TI_UIDCK_FILTER33_SLIDER = 333,// 新鲜滤镜滑动条
    TI_UIDCK_FILTER34_SLIDER = 334,// 蜜糖乌龙滤镜滑动条
    TI_UIDCK_FILTER35_SLIDER = 335,// 暖食滤镜滑动条
    TI_UIDCK_FILTER36_SLIDER = 336,// 深夜食堂滤镜滑动条
    //假日
    TI_UIDCK_FILTER37_SLIDER = 337,// 夏日滤镜滑动条
    TI_UIDCK_FILTER38_SLIDER = 338,// 暖阳滤镜滑动条
    TI_UIDCK_FILTER39_SLIDER = 339,// 昭和滤镜滑动条
    TI_UIDCK_FILTER40_SLIDER = 340,// 波士顿滤镜滑动条
    //胶片
    TI_UIDCK_FILTER41_SLIDER = 341,// 拍立得滤镜滑动条
    TI_UIDCK_FILTER42_SLIDER = 342,// 回忆滤镜滑动条
    TI_UIDCK_FILTER43_SLIDER = 343,// 反差色滤镜滑动条
    TI_UIDCK_FILTER44_SLIDER = 344,// 复古滤镜滑动条
    TI_UIDCK_FILTER45_SLIDER = 345,// 怀旧滤镜滑动条
    TI_UIDCK_FILTER46_SLIDER = 346,// 黑白滤镜滑动条
    
    TI_UIDCK_ONEKEY_SLIDER = 400, // 一键美颜
    TI_UIDCK_ONEKEY_SLIDER_Index = 401,  //一键美颜索引
    TI_UIDCK_FACESHAPE_SLIDER = 500, // 脸型
    TI_UIDCK_FACESHAPE_SLIDER_Index = 501, // 脸型索引
    TI_UIDCK_HAIRDRESS_SLIDER = 600, // 美发
    
    //绿幕
    TI_UIDCK_SIMILARITY_SLIDER = 701, //相似度
    TI_UIDCK_SMOOTH_SLIDER = 702, //平滑度
    TI_UIDCK_HYALINE_SLIDER = 703, //透明度
    
    TI_UIDCK_CheekRed_SLIDER = 1000, //  腮红
    TI_UIDCK_Eyelash_SLIDER = 2000, // 睫毛
    TI_UIDCK_Eyebrows_SLIDER = 3000, // 眉毛
    TI_UIDCK_Eyeshadow_SLIDER = 4000, // 眼影
    TI_UIDCK_Eyeline_SLIDER = 5000, // 眼线
    
    //哈哈镜
    TI_UIDCK_distortion_Index = 6000, // 哈哈镜索引
    
    //滤镜
    TI_UIDCK_filter_Index = 7000, // 滤镜索引
    
    
    
};

// 保存key float值
+ (void)setFloatValue:(float)value forKey:(TiUIDataCategoryKey)key;

// 获取key float值
+ (float)getFloatValueForKey:(TiUIDataCategoryKey)key;

 // 保存选中美妆的坐标
+ (void)setBeautyMakeupIndex:(int)index forKey:(TiUIDataCategoryKey)key;
 // 获取选中美妆的坐标
+ (int)getBeautyMakeupIndexForKey:(TiUIDataCategoryKey)key;


+ (void)initSDK;

+ (void)setTotalEnable:(BOOL)enable toIndex:(NSInteger)index;

+ (void)setBeautySlider:(float)v forKey:(TiUIDataCategoryKey)key withIndex:(NSInteger)index;
 
//+ (TiFilterEnum)getTiFilterEnumForIndex:(NSInteger)index;

+ (TiHairEnum)getTiHairEnumForIndex:(NSInteger)index;

+ (TiRockEnum)setRockEnumByIndex:(NSInteger)index;

+ (TiDistortionEnum)setDistortionEnumByIndex:(NSInteger)index;


+ (void)setOneKeyBeautySlider:(float)v Index:(NSInteger)index;
+ (void)setFaceShapeBeautySlider:(float)v Index:(NSInteger)index;

+ (NSString *)setMakeupByIndex:(NSInteger)index;

@end
