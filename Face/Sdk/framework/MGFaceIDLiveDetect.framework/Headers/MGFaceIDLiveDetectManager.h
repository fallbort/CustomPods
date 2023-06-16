//
//  MGFaceIDLiveDetectManager.h
//  MGFaceIDLiveDetect
//
//  Created by MegviiDev on 2018/6/21.
//  Copyright © 2018年 Megvii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGFaceIDLiveDetectConfig.h"
#import "MGFaceIDLiveDetectError.h"
#import "MGFaceIDLiveDetectLanguageConfig.h"
#import "MGFaceIDLiveDetectCustomConfigItem.h"
#import "MGFaceIDLivenessFileResult.h"

typedef enum : NSUInteger {
    MGFaceIDLiveDetectModel_A            = 0,            //  方案A
    MGFaceIDLiveDetectModel_B            = 1,            //  方案B
} MGFaceIDLiveDetectModel;

@interface MGFaceIDLiveDetectManager : NSObject

/**
 指定 FaceID 活体检测资源路径。请在调用初始化接口前调用该接口进行路径指定。

 @param bundleFilePath 资源路径。请添加资源包绝对路径，以`bundle`为地址后缀名。
 @return 指定资源路径是否成功。默认为NO，设置指定路径失败。
 */
+ (BOOL)designationMGFaceIDLiveDetectFilePath:(NSString *__nonnull)bundleFilePath;

/**
 初始化 FaceID 活体检测 Manager，建议在子线程中调用该方法。
 由于 bizTokenStr 的唯一性，每一次调用 startMGFaceIDLiveDetectWithCurrentController:callback: 检测方法都需要重新初始化该 Manager.

 @param bizTokenStr 业务串号
 @param languageType 选择语言种类
 @param hostUrl 网络请求host地址
 @param extraDict 预留信息。非必选参数，可以为nil
 @param error 初始化错误信息
 @return 初始化对象
 */
- (instancetype _Nullable)initMGFaceIDLiveDetectManagerWithBizToken:(NSString *__nonnull)bizTokenStr
                                                           language:(MGFaceIDLiveDetectLanguageType)languageType
                                                        networkHost:(NSString *__nullable)hostUrl
                                                          extraData:(NSDictionary *__nullable)extraDict
                                                              error:(MGFaceIDLiveDetectError *_Nullable*__nonnull)error;

/**
初始化 FaceID 活体检测 Manager，建议在子线程中调用该方法。
由于 bizTokenStr 的唯一性，每一次调用 startMGFaceIDLiveDetectWithCurrentController:callback: 检测方法都需要重新初始化该 Manager.

@param bizTokenStr 业务串号
@param languageType 选择语言种类
@param host1 网络请求host1地址
@param host2 网络请求host1地址
@param extraDict 预留信息。非必选参数，可以为nil
@param configData 预留信息。(model为A时，非必选参数；model为B时，必选参数)
@param model 集成方案
@param error 初始化错误信息
@return 初始化对象
*/
- (instancetype _Nullable)initMGFaceIDLiveDetectManagerWithBizToken:(NSString *__nonnull)bizTokenStr
                                                           language:(MGFaceIDLiveDetectLanguageType)languageType
                                                       networkHost1:(NSString *__nullable)host1
                                                       networkHost2:(NSString *__nullable)host2
                                                          extraData:(NSDictionary *__nullable)extraDict
                                                         configData:(NSString *__nullable)configData
                                                              model:(MGFaceIDLiveDetectModel)model
                                                              error:(MGFaceIDLiveDetectError * _Nullable *__nonnull)error;

/**
初始化 FaceID 活体检测 Manager，建议在子线程中调用该方法。
该方法为私有化初始化方法

@param presetConfig 活体配置参数(其中liveness_type为必选，其他可选；当liveness_type为meglive时，action_sequence为必选)
@param configPath 活体配置文件路径
@param languageType 选择语言种类
@param extraDict 预留信息。非必选参数，可以为nil
@param error 初始化错误信息
@return 初始化对象
*/
- (instancetype _Nullable)initMGFaceIDLiveDetectManagerWithPresetConfig:(NSDictionary *__nonnull)presetConfig
                                                         configDataPath:(NSString *_Nonnull)configPath
                                                               language:(MGFaceIDLiveDetectLanguageType)languageType
                                                              extraData:(NSDictionary *__nullable)extraDict
                                                                  error:(MGFaceIDLiveDetectError *_Nullable*__nonnull)error;

/**
 开启 FaceID 活体检测

 @param detectVC 启动检测的当前页面
 @param block 检测结果
 */
- (void)startMGFaceIDLiveDetectWithCurrentController:(UIViewController *__nonnull)detectVC
                                            callback:(MGFaceIDLiveDetectResultBlock __nonnull)block;

/**
 开启 FaceID 活体检测

 @param detectVC 启动检测的当前页面
 @param block 检测结果
 @param completion 检测界面dismiss完成回调
 */
- (void)startMGFaceIDLiveDetectWithCurrentController:(UIViewController *__nonnull)detectVC
                                            callback:(MGFaceIDLiveDetectResultBlock __nonnull)block
                                   dismissCompletion:(MGFaceIDLiveDetectDismissBlock __nonnull )completion;

/**
 设置 FaceID 活体检测的垂直检测类型

 @param verticalType 垂直检测类型
 */
- (void)setMGFaceIDLiveDetectPhoneVertical:(MGFaceIDLiveDetectPhoneVerticalType)verticalType;

/**
 设置 FaceID 活体检测的自定义UI效果

 @param configItem 自定义UI配置
 */
- (void)setMGFaceIDLiveDetectCustomUIConfig:(MGFaceIDLiveDetectCustomConfigItem *__nullable)configItem;

/**
 调节 FaceID 活体检测时的语音提示音量。如果开启音量调节，在退出活体检测后会自动恢复到初始音量
 该设置仅在动作活体时有效
 
 @param isOpen 是否开启音量调节。YES为开启，NO为不开启，默认为不开启。
 @param volume 调节后的音量，取值范围为[0, 1]，其中0为最小音量，1为最大音量，默认值为0.5。如果设备当前音量大于该阈值，则不进行调节。
 */
- (void)setMGFaceIDLiveDetectAdjustAudio:(BOOL)isOpen minVolume:(float)volume;

- (void)setTextContentWithKey:(NSString *_Nullable)key value:(NSString *_Nullable)value;

/**
 获取 SDK 版本号信息
 
 @return SDK 版本号
 */
+ (NSString *_Nonnull)getSDKVersion;

/**
 获取 SDK 构建信息
 
 @return SDK 构建号
 */
+ (NSString *_Nonnull)getSDKBuild;

/**
 解密返回的视频和图片文件
 
 @param path 待解密文件路径
 @param key 密钥
 @return 解密结果
 */
+ (MGFaceIDLivenessFileResult *_Nonnull)decryptVideoPath:(NSString *_Nonnull)path key:(NSString *_Nonnull)key;

/**
 返回活体验证过程中的信息，请在活体检测流程结束后进行调用。
 
 @return 活体流程信息。加密信息，可能为nil。
 */
- (NSData *_Nullable)queryFaceIDDetectInfo;

@end
