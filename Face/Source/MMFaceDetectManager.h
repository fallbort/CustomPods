//
//  MMFaceDetectManager.h
//  Alamofire
//
//  Created by xfb on 2023/6/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMFaceDetectManager : NSObject
+(instancetype)shared;

-(void)startupWithAppKey:(NSString*)appKey appSecret:(NSString*)appSecret;

-(void)startFaceDetectWithUserName:(NSString*)userName idCardNumber:(NSString*)idCardNumber complete:(void(^ _Nullable)(BOOL success,NSInteger statusCode, NSError * _Nullable error,UIImage* _Nullable image))complete;

@end

NS_ASSUME_NONNULL_END
