//
//  BeautySettingCardViewController.h
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BeautySettingCardViewController : UIViewController
@property (nonatomic,copy)void(^resetAllClickedBlock)(void);

-(void)resetAllSetting;
@end

NS_ASSUME_NONNULL_END
