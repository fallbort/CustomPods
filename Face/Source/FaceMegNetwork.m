//
//  FaceMegNetwork.m
//
//  Created by Megvii on 2018/11/2.
//  Copyright © 2018 Megvii. All rights reserved.
//

#import "FaceMegNetwork.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>
#import <math.h>

#define kMGFaceIDNetworkHost @"https://api.megvii.com"
#define kMGFaceIDNetworkTimeout 30

@interface FaceMegNetwork ()
@property (nonatomic, copy) NSString* formMPboundary;
@property (nonatomic, copy) NSString* startMPboundary;
@property (nonatomic, copy) NSString* endMPboundary;

@property (nonatomic, copy) NSString* appKey;
@property (nonatomic, copy) NSString* _Nullable appSecret;
@end

@implementation FaceMegNetwork

static FaceMegNetwork* sing = nil;

+ (FaceMegNetwork *)singleton {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sing = [[FaceMegNetwork alloc] init];
    });
    return sing;
}

-(void)configWithAppKey:(NSString*)appKey appSecret:(NSString* _Nullable)appSecret {
    self.appKey = appKey;
    self.appSecret = appSecret;
}

- (void)queryDemoMGFaceIDAntiSpoofingBizTokenWithUserName:(NSString *)userNameStr idcardNumber:(NSString *)idcardNumberStr liveConfig:(NSDictionary *)liveInfo success:(RequestSuccess)successBlock failure:(RequestFailure)failureBlock {

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
}

- (void)queryDemoMGFaceIDAntiSpoofingVerifyWithBizToken:(NSString *)bizTokenStr verify:(NSData *)megliveData success:(RequestSuccess)successBlock failure:(RequestFailure)failureBlock {

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
}

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
