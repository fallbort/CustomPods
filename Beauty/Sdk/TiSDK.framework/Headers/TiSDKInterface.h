//
//  TiSDKInterface.h
//  TiSDK
//
//  Created by Cat66 on 2018/5/10.
//  Copyright © 2018年 Tillusory Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

#pragma mark - TiSDK初始化类 -

// 初始化状态回调值
typedef struct InitStatus {
    int code ;//100正式、101测试
    const char*message;
} InitStatus;

typedef void (^TiInitCallbackBlock)(InitStatus callBack);

@interface TiSDK : NSObject

/**
 * 初始化函数一
 *
 * @param key TiSDK在线鉴权Key
 */
+ (TiSDK *)init:(NSString *)key;

/**
 * 初始化函数二
 *
 * @param key TiSDK在线鉴权Key
 * @param block 初始化回调block
 */
+ (TiSDK *)init:(NSString *)key CallBack:(TiInitCallbackBlock)block;

/**
 * 初始化函数三，适配最新版本swift
 *
 * @param key TiSDK在线鉴权Key
 * @param block 初始化回调block
 */
+ (TiSDK *)initSDK:(NSString *)key CallBack:(TiInitCallbackBlock)block;

/**
 * 初始化函数四
 *
 * @param license TiSDK离线鉴权license
 */
+ (TiSDK *)initOffline:(NSString *)license;

/**
 * 资源文件（贴纸、互动等）URL是否获取成功通知名称
 */
#define TiResourceURLNotificationName @"TiResourceURLNotification"

/**
 * 贴纸文件URL地址设置函数
 */
+ (void)setStickerUrl:(NSString *)url;
/**
 * 贴纸文件URL地址获取函数
 */
+ (NSString *)getStickerURL;
/**
 * 贴纸文件本地沙盒地址获取函数
 */
+ (NSString *)getStickerPath;
/**
 * 贴纸IconURL地址设置函数
 */
+ (void)setStickerThumbUrl:(NSString *)url;
/**
 * 贴纸IconURL地址获取函数
 */
+ (NSString *)getStickerIconURL;

/**
 * 礼物文件URL地址设置函数
 */
+ (void)setGiftUrl:(NSString *)url;
/**
 * 礼物文件URL地址获取函数
 */
+ (NSString *)getGiftURL;
/**
 * 礼物文件本地沙盒地址获取函数
 */
+ (NSString *)getGiftPath;
/**
 * 礼物IconURL地址设置函数
 */
+ (void)setGiftThumbUrl:(NSString *)url;
/**
 * 礼物IconURL地址获取函数
 */
+ (NSString *)getGiftIconURL;

/**
 * 水印文件URL地址设置函数
 */
+ (void)setWatermarkUrl:(NSString *)url;
/**
 * 水印文件URL地址获取函数
 */
+ (NSString *)getWatermarkURL;
/**
 * 水印文件本地沙盒地址获取函数
 */
+ (NSString *)getWatermarkPath;
/**
 * 水印IconURL地址设置函数
 */
+ (void)setWatermarkThumbUrl:(NSString *)url;
/**
 * 水印IconURL地址获取函数
 */
+ (NSString *)getWatermarkIconURL;

/**
 * 面具文件URL地址设置函数
 */
+ (void)setMaskUrl:(NSString *)url;
/**
 * 面具文件URL地址获取函数
 */
+ (NSString *)getMaskURL;
/**
 * 面具文件本地沙盒地址获取函数
 */
+ (NSString *)getMaskPath;
/**
 * 面具IconURL地址设置函数
 */
+ (void)setMaskThumbUrl:(NSString *)url;
/**
 * 面具IconURL地址获取函数
 */
+ (NSString *)getMaskIconURL;

/**
 * 绿幕文件URL地址设置函数
 */
+ (void)setGreenScreenUrl:(NSString *)url;
/**
 * 绿幕文件URL地址获取函数
 */
+ (NSString *)getGreenScreenURL;
/**
 * 绿幕文件本地沙盒地址获取函数
 */
+ (NSString *)getGreenScreenPath;
/**
 * 绿幕IconURL地址设置函数
 */
+ (void)setGreenScreenThumbUrl:(NSString *)url;
/**
 * 绿幕IconURL地址获取函数
 */
+ (NSString *)getGreenScreenIconURL;

/**
 * 互动文件URL地址设置函数
 */
+ (void)setInteractionUrl:(NSString *)url;
/**
 * 互动文件URL地址获取函数
 */
+ (NSString *)getInteractionURL;
/**
 * 互动文件本地沙盒地址获取函数
 */
+ (NSString *)getInteractionPath;
/**
 * 互动IconURL地址设置函数
 */
+ (void)setInteractionThumbUrl:(NSString *)url;
/**
 * 互动IconURL地址获取函数
 */
+ (NSString *)getInteractionIconURL;

/**
 * 美妆文件URL地址设置函数
 */
+ (void)setMakeupUrl:(NSString *)url;
/**
 * 美妆文件URL地址获取函数
 */
+ (NSString *)getMakeupURL;
/**
 * 美妆文件本地地址获取函数
 */
+ (NSString *)getMakeupPath;
/**
 * 美妆IconURL地址设置函数
 */
+ (void)setMakeupThumbUrl:(NSString *)url;

/**
 * 美妆IconURL地址获取函数
 */
+ (NSString *)getMakeupIconURL;

/**
 * 人像抠图文件URL地址设置函数
 */
+ (void)setPortraitUrl:(NSString *)url;
/**
 * 人像抠图文件URL地址获取函数
 */
+ (NSString *)getPortraitURL;
/**
 * 人像抠图文件本地沙盒地址获取函数
 */
+ (NSString *)getPortraitPath;
/**
 * 人像抠图IconURL地址设置函数
 */
+ (void)setPortraitThumbUrl:(NSString *)url;
/**
 * 人像抠图IconURL地址获取函数
 */
+ (NSString *)getPortraitIconURL;

/**
 * 手势识别文件URL地址设置函数
 */
+ (void)setGestureUrl:(NSString *)url;
/**
 * 手势识别文件URL地址获取函数
 */
+ (NSString *)getGestureURL;
/**
 * 手势识别文件本地沙盒地址获取函数
 */
+ (NSString *)getGesturePath;
/**
 * 手势识别IconURL地址设置函数
 */
+ (void)setGestureThumbUrl:(NSString *)url;
/**
 * 手势识别IconURL地址获取函数
 */
+ (NSString *)getGestureIconURL;

/**
 * 模型文件本地沙盒路径获取函数
 */
+ (NSString *)getModelPath;

/**
 * 打开/关闭日志
 */
+ (void)setLog:(BOOL)enable;

@end

#pragma mark - TiSDK渲染管理器类 -

@interface TiSDKManager : NSObject

// 视频帧格式
typedef NS_ENUM(NSInteger, TiImageFormatEnum) {
    BGRA = 0,
    NV21 = 1,
    RGB = 2,
    RGBA = 3,
    NV12 = 4,
    I420 = 5
};

// 视频帧旋转角度
typedef NS_ENUM(NSInteger, TiRotationEnum){
    CLOCKWISE_0 = 0,
    CLOCKWISE_90 = 90,
    CLOCKWISE_180 = 180,
    CLOCKWISE_270 = 270
};

/**
 * 滤镜类型
 * 该枚举类型适用于老版本滤镜接口:
 *  - (void)setFilterEnum:(TiFilterEnum)filterEnum;
 *  - (void)setFilterEnum:(TiFilterEnum)filterEnum Param:(int)param;
 * 包括特效滤镜类型、美颜滤镜类型
 * 注释中的滤镜中文名称仅供参考，用户可在外部UI根据产品需求自定义中文名称
 */
typedef NS_ENUM(NSInteger, TiFilterEnum) {
    NO_FILTER = 0, // 无
    SKETCH_FILTER = 1, // 素描
    SOBELEDGE_FILTER = 2, // 黑边
    TOON_FILTER = 3, // 卡通
    EMBOSS_FILTER = 4, // 浮雕
    FILM_FILTER = 5, // 胶片
    PIXELLATION_FILTER = 6, // 马赛克
    HALFTONE_FILTER = 7, // 半色调
    CROSSHATCH_FILTER = 8, // 交叉线
    NASHVILLE_FILTER = 9, // 那舍尔
    COFFEE_FILTER = 10, // 咖啡
    CHOCOLATE_FILTER = 11, // 巧克力
    COCO_FILTER = 12, // 可可
    DELICIOUS_FILTER = 13, // 美味
    FIRSTLOVE_FILTER = 14, // 初恋
    FOREST_FILTER = 15, // 森林
    GLOSSY_FILTER = 16, // 光泽
    GRASS_FILTER = 17, // 禾草
    HOLIDAY_FILTER = 18, // 假日
    KISS_FILTER = 19, // 初吻
    LOLITA_FILTER = 20, // 洛丽塔
    MEMORY_FILTER = 21, // 回忆
    MOUSSE_FILTER = 22, // 慕斯
    NORMAL_FILTER = 23, // 标准
    OXGEN_FILTER = 24, // 氧气
    PLATYCODON_FILTER = 25, // 桔梗
    RED_FILTER = 26, // 赤红
    SUNLESS_FILTER = 27, // 冷日
    PINCH_DISTORTION_FILTER = 28, // 扭曲
    KUWAHARA_FILTER = 29, // 油画
    POSTERIZE_FILTER = 30, // 分色
    SWIRL_DISTORTION_FILTER = 31, // 漩涡
    VIGNETTE_FILTER = 32, // 光晕
    ZOOM_BLUR_FILTER = 33, // 眩晕
    POLKA_DOT_FILTER = 34, // 圆点
    POLAR_PIXELLATE_FILTER = 35, // 极坐标
    GLASS_SPHERE_REFRACTION_FILTER = 36, // 水晶球
    SOLARIZE_FILTER = 37, // 曝光
    INK_WASH_PAINTING_FILTER = 38, // 水墨
    ARABICA_FILTER = 39, // 阿拉比卡
    AVA_FILTER = 40, // 阿瓦
    AZREAL_FILTER = 41, // 艾瑟瑞尔
    BOURBON_FILTER = 42, // 波旁
    BYERS_FILTER = 43, // 拜尔斯
    CHEMICAL_FILTER = 44, // 化学
    CLAYTON_FILTER = 45, // 克莱顿
    CLOUSEAU_FILTER = 46, // 克卢索
    COBI_FILTER = 47, // 小新
    CONTRAIL_FILTER = 48, // 凝迹
    CUBICLE_FILTER = 49, // 隔间
    DJANGO_FILTER = 50, // 姜戈
    FUJI_REALA_FILTER = 90 // 真实
};

// 抖动类型
typedef NS_ENUM(NSInteger, TiRockEnum) {
    NO_ROCK = 0, // 无抖动特效
    DAZZLED_COLOR_ROCK = 1, // 炫彩抖动
    LIGHT_COLOR_ROCK = 2, // 轻彩抖动
    DIZZY_GIDDY_ROCK = 3, // 头晕目眩
    ASTRAL_PROJECTION_ROCK = 4, // 灵魂出窍
    BLACK_MAGIC_ROCK = 5, // 暗黑魔法
    VIRTUAL_MIRROR_ROCK = 6, // 虚拟镜像
    DYNAMIC_SPLIT_SCREEN_ROCK = 7, //动感分屏
    BLACK_WHITE_FILM_ROCK = 8, // 黑白电影
    GRAY_PETRIFACTION_ROCK = 9, // 瞬间石化
    BULGE_DISTORTION__ROCK = 10 // 魔法镜面
};

// 哈哈镜类型
typedef NS_ENUM(NSInteger, TiDistortionEnum) {
    NO_DISTORTION = 0, // 无
    ET_DISTORTION = 1, // 外星人
    PEAR_FACE_DISTORTION = 2, // 梨梨脸
    SLIM_FACE_DISTORTION = 3, // 瘦瘦脸
    SQUARE_FACE_DISTORTION = 4 // 方方脸
};

// 美发类型
typedef NS_ENUM(NSInteger, TiHairEnum) {
    NO_HAIR = 0, // 无
    MY_PURPLE_HAIR = 1, // 神秘紫
    CHOCOLATE_HAIR = 2, // 巧克力
    AJ_BROWN_HAIR = 3, // 青木棕
    CA_BROWN_HAIR = 4, // 焦糖棕
    HON_BROWN_HAIR = 5, // 蜂蜜醇棕
    LTG_BROWN_HAIR = 6, // 浅金棕
    ROSE_GOLD_HAIR = 7, // 玫瑰金
    FW_GOLD_HAIR = 8, // 亚麻白金
    SS_ORANGE_HAIR = 9, // 落日橘
    FL_ORANGE_HAIR = 10, // 亚麻浅橘
    VINTAGE_ROSE_HAIR = 11, // 复古玫瑰
    TENDER_ROSE_HAIR = 12, // 深玫瑰
    MG_PURPLE_HAIR = 13, // 烟灰雾紫
    SPR_BROWN_HAIR = 14, // 粉玫甜棕
    FROG_TARO_HAIR = 15, // 雾霾香芋
    PEACOCK_BLUE_HAIR = 16, // 孔雀蓝
    FB_GRAY_HAIR = 17, // 雾霾蓝灰
    FG_BROWN_HAIR = 18, // 亚麻灰棕
    FL_GRAY_HAIR = 19 // 亚麻浅灰
};

// 一键美颜类型
typedef NS_ENUM(NSInteger, TiOnekeyBeautyEnum) {
    STANDARD_ONEKEY_BEAUTY = 0, // 标准
    DELICATE_ONEKEY_BEAUTY = 1, // 精致
    LOVELY_ONEKEY_BEAUTY = 2, // 可爱
    INTERNET_CELEBRITY_ONEKEY_BEAUTY = 3, // 网红
    NATURAL_ONEKEY_BEAUTY = 4, // 自然
    LOLITA_ONEKEY_BEAUTY = 5, // 萝莉
    ELEGANT_ONEKEY_BEAUTY = 6, // 优雅
    FIRST_LOVE_ONEKEY_BEAUTY = 7, // 初恋
    GODNESS_ONEKEY_BEAUTY = 8, // 女神
    ADVANCED_ONEKEY_BEAUTY = 9, // 高级
    LOW_END_ONEKEY_BEAUTY = 10 // 低端机适配
};

// 脸型类型
typedef NS_ENUM(NSInteger, TiFaceShapeEnum) {
    CLASSIC_FACE_SHAPE = 0, // 经典
    SQUARE_FACE_SHAPE = 1, // 方脸
    LONG_FACE_SHAPE = 2, // 长脸
    ROUNDED_FACE_SHAPE = 3, // 圆脸
    SLIM_FACE_SHAPE = 4 // 瘦脸
};

+ (TiSDKManager *)shareManager;

/**
 * 纹理渲染接口函数一
 *
 * @param texture2D 待渲染纹理
 * @param imageWidth 纹理宽度
 * @param imageHeight 纹理高度
 * @param rotation 纹理转为正向（home键向下）待旋转角度
 * @param isMirror 是否存在镜像
 *
 * @return 渲染后的纹理
 */
- (GLuint)renderTexture2D:(GLuint)texture2D Width:(CGFloat)imageWidth Height:(CGFloat)imageHeight Rotation:(TiRotationEnum)rotation Mirror:(BOOL)isMirror;

/**
 * 纹理渲染接口函数二
 *
 * @param texture2D 待渲染纹理
 * @param imageWidth 纹理宽度
 * @param imageHeight 纹理高度
 * @param rotation 纹理转为正向（home键向下）待旋转角度
 * @param isMirror 是否存在镜像
 * @param faceNumber 人脸相关特效可支持的人脸数 [1, 5]
 *
 * @return 渲染后的纹理
 */
- (GLuint)renderTexture2D:(GLuint)texture2D Width:(CGFloat)imageWidth Height:(CGFloat)imageHeight Rotation:(TiRotationEnum)rotation Mirror:(BOOL)isMirror FaceNumber:(int)faceNumber;

/**
 * pixelBuffer渲染接口函数一
 *
 * @param pixels 待渲染视频帧
 * @param imageWidth 纹理宽度
 * @param imageHeight 纹理高度
 * @param rotation 纹理转为正向（home键向下）待旋转角度
 * @param isMirror 是否存在镜像
 *
 */
- (void)renderPixels:(unsigned char *)pixels Format:(TiImageFormatEnum)imageFormat Width:(CGFloat)imageWidth Height:(CGFloat)imageHeight Rotation:(TiRotationEnum)rotation Mirror:(BOOL)isMirror;

/**
 * pixelBuffer渲染接口函数二
 *
 * @param pixels 待渲染视频帧
 * @param imageWidth 视频帧宽度
 * @param imageHeight 视频帧高度
 * @param rotation 视频帧转为正向（home键向下）待旋转角度
 * @param isMirror 是否存在镜像
 * @param faceNumber 人脸相关特效可支持的人脸数 [1, 5]
 *
 */
- (void)renderPixels:(unsigned char *)pixels Format:(TiImageFormatEnum)imageFormat Width:(CGFloat)imageWidth Height:(CGFloat)imageHeight Rotation:(TiRotationEnum)rotation Mirror:(BOOL)isMirror FaceNumber:(int)faceNumber;

/**
 * image渲染接口函数
 *
 * @param pixels 待渲染图片
 * @param imageWidth 图片宽度
 * @param imageHeight 图片高度
 * @param rotation 图片转为正向（home键向下）待旋转角度
 * @param isMirror 是否存在镜像
 * @param faceNumber 人脸相关特效可支持的人脸数 [1, 5]
 *
 */
- (void)renderImage:(unsigned char *)pixels Format:(TiImageFormatEnum)imageFormat Width:(CGFloat)imageWidth Height:(CGFloat)imageHeight Rotation:(TiRotationEnum)rotation Mirror:(BOOL)isMirror FaceNumber:(int)faceNumber;

/**
 * 渲染特效总开关
 *
 * @param enable YES是打开渲染；NO是关闭开关
 */
-(void)setRenderEnable:(bool)enable;

/**
 * 开启/关闭美颜特效函数
 *
 * @param enable 是否开启美颜特效
 */
- (void)setBeautyEnable:(BOOL)enable;

/**
 * 设置美颜-美白特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setSkinWhitening:(int)param;

/**
 * 设置美颜-磨皮特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setSkinBlemishRemoval:(int)param;

/**
 * 设置美颜-精准美肤特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setSkinPreciseBeauty:(int)param;

/**
 * 设置美颜-粉嫩特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setSkinTenderness:(int)param;

/**
 * 设置美颜-清晰特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setSkinSharpness:(int)param;

/**
 * 设置美颜-亮度特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setSkinBrightness:(int)param;

/**
 * 设置美颜-饱和特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setSkinSaturation:(int)param;

/**
 * 打开/关闭美型特效函数
 *
 * @param enable 是否打开美型特效
 */
- (void)setFaceTrimEnable:(BOOL)enable;

/**
 * 设置美型-大眼特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setEyeMagnifying:(int)param;

/**
 * 设置美型-瘦脸特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setChinSlimming:(int)param;

/**
 * 设置美型-窄脸特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setFaceNarrowing:(int)param;

/**
 * 设置美型-瘦颧骨特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setCheekboneSlimming:(int)param;

/**
 * 设置美型-瘦下颌特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setJawboneSlimming:(int)param;

/**
 * 设置美型-下巴特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setJawTransforming:(int)param;

/**
 * 设置美型-削下巴特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setJawSlimming:(int)param;

/**
 * 设置美型-额头特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setForeheadTransforming:(int)param;

/**
 * 设置美型-内眼角特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setEyeInnerCorners:(int)param;

/**
 * 设置美型-外眼尾特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setEyeOuterCorners:(int)param;

/**
 * 设置美型-眼间距特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setEyeSpacing:(int)param;

/**
 * 设置美型-眼角特效参数函数
 *
 * @param param [-50, 50]
 * 默认值为0
 */
- (void)setEyeCorners:(int)param;

/**
 * 设置美型-瘦鼻特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setNoseMinifying:(int)param;

/**
 * 设置美型-长鼻特效参数函数
 *
 * @param param [0, 100]
 * 默认值为0
 */
- (void)setNoseElongating:(int)param;

/**
 * 设置美型-嘴型特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setMouthTransforming:(int)param;

/**
 * 设置美型-嘴高低特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setMouthHeight:(int)param;

/**
 * 设置美型-唇薄厚特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setMouthLipSize:(int)param;

/**
 * 设置美型-扬嘴角特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setMouthSmiling:(int)param;

/**
 * 设置美型-眉高低特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setBrowHeight:(int)param;

/**
 * 设置美型-眉长短特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setBrowLength:(int)param;

/**
 * 设置美型-眉间距特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setBrowSpace:(int)param;

/**
 * 设置美型-眉粗细特效参数函数
 *
 * @param param [-50, 50]
 */
- (void)setBrowSize:(int)param;

/**
 * 设置美型-提眉尾特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setBrowCorner:(int)param;

/**
 * 设置美型-美牙特效参数函数
 *
 * @param param [0, 100]
 */
- (void)setTeethWhitening:(int)param;

/**
 * 切换滤镜函数
 * 老版本滤镜接口一
 * 不可调节滤镜效果
 *
 * @param filterEnum 参考宏定义TiFilterEnum
 */
- (void)setFilterEnum:(TiFilterEnum)filterEnum;

/**
 * 切换滤镜并设置相应参数函数
 * 老版本滤镜接口二
 * 可调节滤镜效果
 *
 * @param filterEnum 参考宏定义TiFilterEnum
 * @param param 滤镜参数
 */
- (void)setFilterEnum:(TiFilterEnum)filterEnum Param:(int)param;

/**
 * 美颜滤镜设置函数
 * 新版本滤镜接口
 *
 * @param filterName 滤镜名称
 * @param param 滤镜参数
 */
- (void)setBeautyFilter:(NSString *)filterName Param:(int)param;

/**
 * 设置抖动特效参数函数
 *
 * @param rockEnum 参考宏定义TiRockEnum
 */
- (void)setRockEnum:(TiRockEnum)rockEnum;

/**
 * 设置哈哈镜特效参数函数
 *
 * @param distortionEnum 参考宏定义TiDistortionEnum
 */
- (void)setDistortionEnum:(TiDistortionEnum)distortionEnum;

/**
 * 切换贴纸函数
 *
 * @param stickerName 贴纸名称
 */
- (void)setStickerName:(NSString *)stickerName;

/**
 * 设置互动特效参数函数
 *
 * @param interactionName 互动特效名称
 */
- (void)setInteraction:(NSString *)interactionName;

/**
 * 设置礼物特效参数函数
 *
 * @param giftName 礼物名称
 */
- (void)setGift:(NSString *)giftName;

/**
 * 设置面具特效参数函数
 *
 * @param maskName 面具名称
 */
- (void)setMask:(NSString *)maskName;

/**
 * 设置水印参数函数
 *
 * @param enable  true: 开启 false: 关闭
 * @param x         水印左上角横坐标[0, 100]
 * @param y         水印右上角纵坐标[0, 100]
 * @param ratio    水印横向占据屏幕的比例[0, 100]
 */
- (void)setWatermark:(BOOL)enable Left:(int)x Top:(int)y Ratio:(int)ratio FileName:(NSString *)fileName;

/**
 * 设置绿幕特效参数函数一
 *
 * @param greenScreenName 幕布名称
 */
- (void)setGreenScreen:(NSString *)greenScreenName;

/**
 * 设置绿幕特效参数函数二
 *
 * @param greenScreenName 幕布名称
 * @param similarity 相似度
 * @param smoothness 平滑度
 * @param alpha 透明度
 */
- (void)setGreenScreen:(NSString *)greenScreenName Similarity:(int)similarity Smoothness:(int)smoothness Alpha:(int)alpha;

/**
 * 设置人像抠图特效参数函数
 *
 * @param portraitName 人像抠图特效名称
 */
- (void)setPortrait:(NSString *)portraitName;

/**
 * 设置美发特效参数函数
 *
 * @param hairEnum 参考宏定义TiHairEnum
 * @param param 美发参数
 */
- (void)setHairEnum:(TiHairEnum)hairEnum Param:(int)param;

/**
 * 设置手势识别特效参数函数
 *
 * @param gestureName 手势识别特效名称
 */
- (void)setGesture:(NSString *)gestureName;

/**
 * 美妆特效开关函数
 *
 * @param enable 是否开启美妆
 */
- (void)setMakeupEnable:(bool)enable;

/**
 * 美妆-腮红特效开关函数
 *
 * @param name 腮红特效名称
 * @param param 腮红特效参数
 */
- (void)setBlusher:(NSString*)name Param:(int)param;

/**
 * 美妆-眉毛特效开关函数
 *
 * @param name 眉毛特效名称
 * @param param 眉毛特效参数
 */
- (void)setEyeBrow:(NSString*)name Param:(int)param;

/**
 * 美妆-睫毛特效开关函数
 *
 * @param name 睫毛特效名称
 * @param param 睫毛特效参数
 */
- (void)setEyeLash:(NSString*)name Param:(int)param;

/**
 * 美妆-眼影特效开关函数
 *
 * @param name 眼影特效名称
 * @param param 眼影特效参数
 */
- (void)setEyeShadow:(NSString*)name Param:(int)param;

/**
 * 美妆-眼线特效开关函数
 *
 * @param name 眼线特效名称
 * @param param 眼线特效参数
 */
- (void)setEyeLine:(NSString*)name Param:(int)param;

/**
 * 美体特效开关函数
 *
 *
 * @param enable YES是打开渲染；NO是关闭开关
 */
- (void)setBodyShapingEnable:(BOOL)enable;

/**
 * 美体-长腿特效函数
 *
 * 美体特效目前仅限用于图片编辑条件下
 *
 * @param param 长腿特效参数
 * @param top 长腿特效上边界值
 * @param bottom 长腿特效下边界值
 */
- (void)setLongLeg:(int)param Top:(int)top Bottom:(int)bottom;

/**
 * 美体-瘦身特效函数
 *
 * 美体特效目前仅限用于图片编辑条件下
 *
 * @param param 瘦身特效参数
 * @param left 瘦身特效左边界值
 * @param right 瘦身特效右边界值
 */
- (void)setSlimBody:(int)param Left:(int)left Right:(int)right;

/**
 * 一键美颜
 *
 * @param onekeyBeautyEnum 一键美颜类型，参考枚举类型 TiOnekeyBeautyEnum
 * @param param [0, 100]
 */
- (void)setOnekeyBeauty:(TiOnekeyBeautyEnum)onekeyBeautyEnum Param:(int)param;

/**
 * 脸型
 *
 * @param faceShapeNum 脸型类型，参考枚举类型 TiFaceShapeEnum
 * @param param [0, 100]
 */
- (void)setFaceShape:(TiFaceShapeEnum)faceShapeNum Param:(int)param;

/**
 * 设置人脸识别距离
 *
 * @param level 识别距离级别，默认值为1，取值范围为[0, 1, 2, 3, 4, 5, 6]，值越大，识别距离越远，但性能会相应下降，对机器硬件要求越高
 */
- (void)setTrackDistance:(int)level;

/**
 * 获取识别到的人脸数目
 * @return -1（没有检测人脸）, 其他返回检测到的人脸数量
 */
- (int)getFaceNumber;

/**
 * 资源释放函数
 */
- (void)destroy;

@end

