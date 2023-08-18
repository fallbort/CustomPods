//
//  BeautyCameraViewController.h
//  TiSDKDemo
//
//  Created by N17 on 2022/5/6.
//  Copyright © 2022 Tillusory Tech. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BeautyCameraViewController : UIViewController
@property (nonatomic,copy)void(^resetAllClickedBlock)(void);

-(void)resetAllSetting;
@end

NS_ASSUME_NONNULL_END
