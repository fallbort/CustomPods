//
//  TiInitManagerOC.h
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TiInitManagerOC : NSObject
+(instancetype)shareinstance;
@property (nonatomic, strong) NSString *appKey;

-(void)initSDK;
@end

NS_ASSUME_NONNULL_END
