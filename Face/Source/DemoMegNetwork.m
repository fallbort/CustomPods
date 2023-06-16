//
//  DemoMegNetwork.m
//  DemoMegLiveCustomUI
//
//  Created by Megvii on 2018/11/2.
//  Copyright © 2018 Megvii. All rights reserved.
//

#import "DemoMegNetwork.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>
#import <math.h>

#if UserAFNetwork
#import <AFNetworking/AFNetworking.h>
#endif

#if UserDownload
#import <SSZipArchive/SSZipArchive.h>
#endif

#define kMGFaceIDNetworkHost @"https://api.megvii.com"
#define kMGFaceIDNetworkTimeout 30

@interface DemoMegNetwork ()
#if !UserAFNetwork
@property (nonatomic, copy) NSString* formMPboundary;
@property (nonatomic, copy) NSString* startMPboundary;
@property (nonatomic, copy) NSString* endMPboundary;
#endif

@property (nonatomic, copy) NSString* appKey;
@property (nonatomic, copy) NSString* appSecret;
@end

@implementation DemoMegNetwork

static DemoMegNetwork* sing = nil;
#if UserAFNetwork
//  使用AFNetworking作为项目中的网络请求库
static AFHTTPSessionManager* sessionManager = nil;
#endif
+ (DemoMegNetwork *)singleton {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sing = [[DemoMegNetwork alloc] init];
#if UserAFNetwork
        //  使用AFNetworking作为项目中的网络请求库
        sessionManager = [[AFHTTPSessionManager manager] init];
#endif
    });
    return sing;
}

-(void)configWithAppKey:(NSString*)appKey appSecret:(NSString*)appSecret {
    self.appKey = appKey;
    self.appSecret = appSecret;
}

- (void)queryDemoMGFaceIDAntiSpoofingBizTokenWithUserName:(NSString *)userNameStr idcardNumber:(NSString *)idcardNumberStr liveConfig:(NSDictionary *)liveInfo success:(RequestSuccess)successBlock failure:(RequestFailure)failureBlock {
#if !UserAFNetwork
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithDictionary:@{@"idcard_name" : userNameStr,
                                                                                    @"idcard_number" : idcardNumberStr,
                                                                                    @"sign" : [self getFaceIDSignStr],
                                                                                    @"sign_version" : [self getFaceIDSignVersionStr],
                                                                                    @"comparison_type" : @"1" }];
    [params addEntriesFromDictionary:liveInfo];
    NSString* urlStr = [NSString stringWithFormat:@"%@/faceid/v3/sdk/get_biz_token", kMGFaceIDNetworkHost];
    NSMutableURLRequest* request = [self getRequest:[NSURL URLWithString:urlStr]
                                             method:@"POST"];

    [self request:request appendParameter:(NSDictionary *)params];
    [self requestAppendEND:request];
    [self requestAppendHeaderField:request];
    
    [self sendAsynchronousRequest:request
                          success:successBlock
                          failure:failureBlock];
#else
    //  使用AFNetworking作为项目中的网络请求库进行`biztoken`的获取和活体结果的验证。
    [sessionManager.requestSerializer setValue:@"multipart/form-data; charset=utf-8; boundary=__X_PAW_BOUNDARY__" forHTTPHeaderField:@"Content-Type"];
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithDictionary:@{@"idcard_name" : userNameStr,
                                                                                    @"idcard_number" : idcardNumberStr,
                                                                                    @"sign" : [self getFaceIDSignStr],
                                                                                    @"sign_version" : [self getFaceIDSignVersionStr],
                                                                                    @"comparison_type" : @"1" ,
                                                                                    }];
    [params addEntriesFromDictionary:liveInfo];
    [sessionManager POST:[NSString stringWithFormat:@"%@/faceid/v3/sdk/get_biz_token", kMGFaceIDNetworkHost]
              parameters:params
constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
}
                progress:nil
                 success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                     if (successBlock) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             NSHTTPURLResponse* urlResponse = (NSHTTPURLResponse *)task.response;
                             successBlock([urlResponse statusCode], (NSDictionary *)responseObject);
                         });
                     }
                 }
                 failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                     if (failureBlock) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             NSHTTPURLResponse* urlResponse = (NSHTTPURLResponse *)task.response;
                             failureBlock([urlResponse statusCode], error);
                         });
                     }
                 }];
#endif
}

- (void)queryDemoMGFaceIDAntiSpoofingVerifyWithBizToken:(NSString *)bizTokenStr verify:(NSData *)megliveData success:(RequestSuccess)successBlock failure:(RequestFailure)failureBlock {
#if !UserAFNetwork
    NSDictionary* params = @{@"sign" : [self getFaceIDSignStr],
                             @"sign_version" : [self getFaceIDSignVersionStr],
                             @"biz_token" : bizTokenStr};
    NSString* urlStr = [NSString stringWithFormat:@"%@/faceid/v3/sdk/verify", kMGFaceIDNetworkHost];
    NSMutableURLRequest* request = [self getRequest:[NSURL URLWithString:urlStr]
                                             method:@"POST"];

    [self request:request appendParameter:(NSDictionary *)params];
    [self request:request appendFile:megliveData fileName:@"meglive_data" contentType:@"text/html"];
    [self requestAppendEND:request];
    [self requestAppendHeaderField:request];
    
    [self sendAsynchronousRequest:request
                          success:successBlock
                          failure:failureBlock];
#else
    //  使用AFNetworking作为项目中的网络请求库进行`biztoken`的获取和活体结果的验证。
    [sessionManager.requestSerializer setValue:@"multipart/form-data; charset=utf-8; boundary=__X_PAW_BOUNDARY__" forHTTPHeaderField:@"Content-Type"];
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithDictionary:@{@"sign" : [self getFaceIDSignStr],
                                                                                    @"sign_version" : [self getFaceIDSignVersionStr],
                                                                                    @"biz_token" : bizTokenStr,
                                                                                    }];
    [sessionManager POST:[NSString stringWithFormat:@"%@/faceid/v3/sdk/verify", kMGFaceIDNetworkHost]
              parameters:params
constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    [formData appendPartWithFileData:megliveData name:@"meglive_data" fileName:@"meglive_data" mimeType:@"text/html"];
}
                progress:nil
                 success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                     if (successBlock) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             NSHTTPURLResponse* urlResponse = (NSHTTPURLResponse *)task.response;
                             successBlock([urlResponse statusCode], (NSDictionary *)responseObject);
                         });
                     }
                 }
                 failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                     if (failureBlock) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             NSHTTPURLResponse* urlResponse = (NSHTTPURLResponse *)task.response;
                             failureBlock([urlResponse statusCode], error);
                         });
                     }
                 }];
#endif
}

- (void)downloadBundleResourceWithSuccess:(RequestSuccess)successBlock {
#if UserDownload
    NSString* ossStr = @"";
    NSAssert(ossStr.length != 0, @"Please set `ossStr`");
    NSURL* ossUrl = [NSURL URLWithString:ossStr];
    NSURLRequest* request = [NSURLRequest requestWithURL:ossUrl];
    NSURLSessionDownloadTask* downloadTask = [[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //  将下载完成的文件迁移到Document文件夹下
        NSString* toURLStr = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"bundle.zip"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:toURLStr]) {
            [[NSFileManager defaultManager] removeItemAtPath:toURLStr error:nil];
        }
        BOOL isSuccess = NO;
        isSuccess = [[NSFileManager defaultManager] moveItemAtPath:location.path toPath:toURLStr error:nil];
        if (isSuccess) {
            NSString* sourceHomeFilePath = [NSString stringWithFormat:@"%@/", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) firstObject]];
            isSuccess = [SSZipArchive unzipFileAtPath:toURLStr toDestination:sourceHomeFilePath];
            [[NSFileManager defaultManager] removeItemAtURL:toURL error:nil];
        }
        if (successBlock) {
            successBlock(isSuccess ? 200 : 400, @{@"URL" : [NSString stringWithFormat:@"%@/MGFaceIDLiveCustomDetect.bundle", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) firstObject]]});
        }
    }];
    [downloadTask resume];
#else
    if (successBlock) {
        successBlock(400, @{@"URL" : @""});
    }
#endif
}

#if !UserAFNetwork
- (NSMutableURLRequest *)getRequest:(NSURL *)uri method:(NSString *)method {
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:uri
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                          timeoutInterval:30];
    [urlRequest setHTTPMethod:method];
    return urlRequest;
}

- (void)request:(NSMutableURLRequest *)request appendParameter:(NSDictionary *)dic {
    NSMutableString *tempString = [NSMutableString stringWithString:@""];
    
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        [tempString appendFormat:@"%@\r\n", self.startMPboundary];
        [tempString appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key];
        [tempString appendFormat:@"%@\r\n", obj];
    }];
    
    NSData *dicData = [tempString dataUsingEncoding:NSUTF8StringEncoding];
    [self requestUpdata:request updata:dicData];
}

- (void)request:(NSMutableURLRequest *)request appendFile:(NSData *)fileData fileName:(NSString *)fileName contentType:(NSString *)type {
    if (fileData) {
        NSMutableString *tempString = [NSMutableString stringWithString:@""];
        [tempString appendFormat:@"%@\r\n", self.startMPboundary];
        [tempString appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fileName, fileName];
        [tempString appendFormat:@"Content-Type: %@\r\n\r\n", type];
        NSData *tempData = [tempString dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableData *resultData = [NSMutableData dataWithData:tempData];
        [resultData appendData:fileData];
        NSData *tempData2 = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
        [resultData appendData:tempData2];
        
        [self requestUpdata:request updata:resultData];
    }
}

- (void)requestAppendHeaderField:(NSMutableURLRequest *)request {
    NSString *content = [[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@", self.formMPboundary];
    [request setValue:content forHTTPHeaderField:@"Content-Type"];
}

- (void)requestAppendEND:(NSMutableURLRequest *)request {
    NSString *end = [[NSString alloc] initWithFormat:@"%@", self.endMPboundary];
    NSData *endData = [end dataUsingEncoding:NSUTF8StringEncoding];
    [self requestUpdata:request updata:endData];
}

- (void)requestUpdata:(NSMutableURLRequest *)request updata:(NSData *)data {
    NSData *body = request.HTTPBody;
    NSMutableData *resultData = [NSMutableData dataWithData:body];
    [resultData appendData:data];
    [request setHTTPBody:resultData];
}

- (void)sendAsynchronousRequest:(NSURLRequest *)request success:(RequestSuccess)successBlock failure:(RequestFailure)failureBlock {
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *_data, NSURLResponse *_response, NSError *_error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_error == nil) {
                if (successBlock) {
                    NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:_data
                                                                                 options:NSJSONReadingMutableLeaves
                                                                                   error:nil];
                    successBlock([(NSHTTPURLResponse *)_response statusCode], responseDict);
                }
            } else {
                if (failureBlock) {
                    failureBlock([(NSHTTPURLResponse *)_response statusCode], _error);
                }
            }
        });
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

#pragma mark - Getter
- (NSString *)formMPboundary {
    if (!_formMPboundary) {
        _formMPboundary = @"4123h4l1k24hk123jh4jkhfksdhafkljh23kj41h23kj4h1kh4k23jh";
    }
    return _formMPboundary;
}

- (NSString *)startMPboundary {
    if (!_startMPboundary) {
        _startMPboundary = [[NSString alloc]initWithFormat:@"--%@", self.formMPboundary];
    }
    return _startMPboundary;
}

- (NSString *)endMPboundary {
    if (!_endMPboundary) {
        _endMPboundary = [[NSString alloc]initWithFormat:@"%@--", self.startMPboundary];
    }
    return _endMPboundary;
}
#endif

- (NSString *)getFaceIDSignStr {
    int valid_durtion = 1000;
    long int current_time = [[NSDate date] timeIntervalSince1970];
    long int expire_time = current_time + valid_durtion;
    long random = labs((long)(arc4random() % 100000000000));
    NSString* str = [NSString stringWithFormat:@"a=%@&b=%ld&c=%ld&d=%ld", self.appKey, expire_time, current_time, random];
    const char *cKey  = [self.appSecret cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [str cStringUsingEncoding:NSUTF8StringEncoding];
    char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    NSData* sign_raw_data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData* data = [[NSMutableData alloc] initWithData:HMAC];
    [data appendData:sign_raw_data];
    NSString* signStr = [data base64EncodedStringWithOptions:0];
    return signStr;
}

- (NSString *)getFaceIDSignVersionStr {
    return @"hmac_sha1";
}

@end
