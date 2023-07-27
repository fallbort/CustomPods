//
//  MMFaceDetectManager.m
//  Alamofire
//
//  Created by xfb on 2023/6/16.
//

#import "MMFaceDetectManager.h"
#import "FaceDetectUtils.h"
#import "FaceMegNetwork.h"
#if !TARGET_IPHONE_SIMULATOR
#import <MGFaceIDLiveDetect/MGFaceIDLiveDetect.h>
#endif

@implementation MMFaceDetectManager

static MMFaceDetectManager* sing = nil;
+(instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sing = [[MMFaceDetectManager alloc] init];
    });
    return sing;
}

-(void)startupWithAppKey:(NSString*)appKey appSecret:(NSString* _Nullable)appSecret {
    [[FaceMegNetwork singleton] configWithAppKey:appKey appSecret:appSecret];
}

-(void)startFaceDetectWithUserName:(NSString*)userName idCardNumber:(NSString*)idCardNumber complete:(void(^ _Nullable)(BOOL success,NSInteger statusCode, NSError * _Nullable error,UIImage* _Nullable image))complete {
    NSMutableDictionary* liveInfoDict = [[NSMutableDictionary alloc] initWithCapacity:1];
    [liveInfoDict setObject:@"meglive" forKey:@"liveness_type"];
    __weak __typeof(self)weakSelf = self;
    [[FaceMegNetwork singleton] queryDemoMGFaceIDAntiSpoofingBizTokenWithUserName:userName idcardNumber:idCardNumber liveConfig:liveInfoDict success:^(NSInteger statusCode, NSDictionary * _Nonnull responseObject) {
        if (statusCode == 200 && responseObject && [[responseObject allKeys] containsObject:@"biz_token"] && [responseObject objectForKey:@"biz_token"]) {
            NSString* bizToken = [responseObject objectForKey:@"biz_token"];
            [weakSelf realStartDetectWithToken:bizToken complete:^(BOOL success, NSInteger statusCode, NSError * _Nullable error, NSData * _Nullable data) {
                if (success == YES) {
                    [weakSelf afterToVerifyWithWithToken:bizToken data:data complete:^(BOOL success, NSInteger statusCode, NSError * _Nullable error, UIImage * _Nullable image) {
                        if (success == YES) {
                            if (complete != nil) {
                                complete(success,statusCode,error,image);
                            }
                        }else{
                            if (complete != nil) {
                                complete(success,statusCode,error,nil);
                            }
                        }
                    }];
                }else{
                    if (complete != nil) {
                        complete(success,statusCode,error,nil);
                    }
                }
            }];
        }else{
            if (complete != nil) {
                NSError* error = [NSError errorWithDomain:@"" code:-99123 userInfo:nil];
                complete(NO,statusCode,error,nil);
            }
        }
    } failure:^(NSInteger statusCode, NSError * _Nonnull error) {
        if (complete != nil) {
            complete(NO,statusCode,error,nil);
        }
    }];
}

-(void)startFaceDetectWithToken:(NSString*)bizToken complete:(void(^ _Nullable)(BOOL success,NSInteger statusCode, NSError * _Nullable error,NSData* _Nullable data))complete {
    NSMutableDictionary* liveInfoDict = [[NSMutableDictionary alloc] initWithCapacity:1];
    [liveInfoDict setObject:@"meglive" forKey:@"liveness_type"];
    __weak __typeof(self)weakSelf = self;
    [weakSelf realStartDetectWithToken:bizToken complete:complete];
}

-(void)realStartDetectWithToken:(NSString*)bizToken complete:(void(^ _Nullable)(BOOL success,NSInteger statusCode, NSError * _Nullable error,NSData* _Nullable data))complete {
    NSString* bundlePath = [NSBundle.mainBundle pathForResource:@"MGFaceIDLiveCustomDetect" ofType:@"bundle"];
    if (bundlePath == nil) {
        bundlePath = @"";
    }
#if !TARGET_IPHONE_SIMULATOR
    BOOL loadResrouce = [MGFaceIDLiveDetectManager designationMGFaceIDLiveDetectFilePath:bundlePath];
    if (loadResrouce == YES) {
        MGFaceIDLiveDetectError* error = nil;
        MGFaceIDLiveDetectManager* detectManager = [[MGFaceIDLiveDetectManager alloc] initMGFaceIDLiveDetectManagerWithBizToken:bizToken
                                                                                                                       language:MGFaceIDLiveDetectLanguageCh
                                                                                                                    networkHost:@"https://api.megvii.com"
                                                                                                                      extraData:nil
                                                                                                                          error:&error];
        if (detectManager != nil && error == nil) {
            //  可选方法-当前使用默认值
            {
                MGFaceIDLiveDetectCustomConfigItem* customConfigItem = [[MGFaceIDLiveDetectCustomConfigItem alloc] init];
                [detectManager setMGFaceIDLiveDetectCustomUIConfig:customConfigItem];
                [detectManager setMGFaceIDLiveDetectPhoneVertical:MGFaceIDLiveDetectPhoneVerticalFront];
            }
            UIViewController* vc = [FaceDetectUtils getTopController];
            
            [detectManager startMGFaceIDLiveDetectWithCurrentController:vc
                                                               callback:^(MGFaceIDLiveDetectError *error, NSData *deltaData, NSString *bizTokenStr, NSDictionary *extraOutDataDict) {
                if (error.errorType == MGFaceIDLiveDetectErrorNone && deltaData) {
                    complete(YES,0,nil,deltaData);
                }else{
                    if (complete != nil) {
                        NSInteger statusCode = -99126;
                        NSError* resultError = [NSError errorWithDomain:error.errorMessageStr code:error.errorType userInfo:nil];
                        complete(NO,statusCode,resultError,nil);
                    }
                }
            }];
        }else{
            if (complete != nil) {
                NSInteger statusCode = -99125;
                NSError* resultError = [NSError errorWithDomain:error.errorMessageStr code:error.errorType userInfo:nil];
                complete(NO,statusCode,resultError,nil);
            }
        }
    }else{
        if (complete != nil) {
            NSInteger statusCode = -99124;
            NSError* error = [NSError errorWithDomain:@"" code:statusCode userInfo:nil];
            complete(NO,statusCode,error,nil);
        }
    }
#else
    if (complete != nil) {
        NSInteger statusCode = -99123;
        NSError* error = [NSError errorWithDomain:@"模拟器无法启动人脸识别" code:statusCode userInfo:nil];
        complete(NO,statusCode,error,nil);
    }
#endif
    
}

-(void)afterToVerifyWithWithToken:(NSString*)bizToken data:(NSData*)deltaData complete:(void(^ _Nullable)(BOOL success,NSInteger statusCode, NSError * _Nullable error,UIImage* _Nullable image))complete {
    [[FaceMegNetwork singleton] queryDemoMGFaceIDAntiSpoofingVerifyWithBizToken:bizToken
                                                                         verify:deltaData
                                                                        success:^(NSInteger statusCode, NSDictionary * _Nonnull responseObject) {
        NSString* imageString = responseObject[@"images"][@"image_best"];
        
        NSData* data = [[NSData alloc] initWithBase64EncodedString:imageString options:0];
        UIImage* image = [UIImage imageWithData:data];
        if (complete != nil) {
            complete(YES,statusCode,nil,image);
        }
    }
                                                                        failure:^(NSInteger statusCode, NSError * _Nonnull error) {
        if (complete != nil) {
            complete(NO,statusCode,error,nil);
        }
    }];
}

@end
