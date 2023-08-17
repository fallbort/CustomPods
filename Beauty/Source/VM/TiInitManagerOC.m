//
//  TiInitManagerOC.m
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/17.
//

#import "TiInitManagerOC.h"
#import <TiSDK/TiSDK.h>

@interface TiInitManagerOC ()
@property (nonatomic, assign) BOOL initSuccess;
@end

@implementation TiInitManagerOC
+(instancetype)shareinstance{
    
    static TiInitManagerOC *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TiInitManagerOC alloc] init];
    });
    
    return instance;
    
}
#pragma mark <>外部变量

#pragma mark <>外部block

#pragma mark <>生命周期开始

#pragma mark <>功能性方法
-(void)initSDK {
    if(self.initSuccess == NO) {
        __weak __typeof(self)weakSelf = self;
        [TiSDK initSDK:self.appKey CallBack:^(InitStatus callBack) {
            if (callBack.code == 100) {
                weakSelf.initSuccess = YES;
            }
        }];
//        [TiSDK.shareInstance initSDK:self.appKey withDelegate:self];
    }
}

#pragma mark <>内部View

#pragma mark <>内部UI变量

#pragma mark <>内部数据变量

#pragma mark <>内部block

- (void)success {
    self.initSuccess = YES;
}

- (void)failure {
    
}

@end
