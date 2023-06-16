//
//  MGFaceIDLivenessFileResult.h
//  MGFaceIDLiveCustomDetect
//
//  Created by Megvii on 2021/1/5.
//  Copyright © 2021 Megvii. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    MGFaceIDLivenessResultCodeSucceed = 1000,   //获取成功
    MGFaceIDLivenessResultCodeVideoKeyError = 2000,  //video_key不正确
    MGFaceIDLivenessResultCodePathError = 2100,  //path不正确
    MGFaceIDLivenessResultCodeFailed = 3000,    //其他错误
} MGFaceIDLivenessResultCode;

NS_ASSUME_NONNULL_BEGIN

@class MGFaceIDLivenessFile;
@interface MGFaceIDLivenessFileResult : NSObject
/**解密错误码*/
@property (nonatomic, assign) MGFaceIDLivenessResultCode resultCode;
/**活体类型（动作：meglive 静默：still 炫彩：flash）*/
@property (nonatomic, strong) NSString *livenessType;
/**文件信息*/
@property (nonatomic, strong) NSArray<MGFaceIDLivenessFile *>* files;

- (instancetype)initWithLivenessType:(NSString *)livenessType;

@end

NS_ASSUME_NONNULL_END

NS_ASSUME_NONNULL_BEGIN
@interface MGFaceIDLivenessFile : NSObject
/**图片或视频路径*/
@property (nonatomic, strong) NSString *path;
/**文件类型（视频：video 图片：image）*/
@property (nonatomic, strong) NSString *fileType;
/**动作类型(只有动作活体有值，其他为空。 眨眼：blink 张嘴：open_mouth 左右摇头：shake 上下点头：nod)*/
@property (nonatomic, strong) NSString *actionType;

@end

NS_ASSUME_NONNULL_END

