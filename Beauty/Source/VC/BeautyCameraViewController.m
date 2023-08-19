//
//  BeautyCameraViewController.m
//  TiSDKDemo
//
//  Created by N17 on 2022/5/6.
//  Copyright © 2022 Tillusory Tech. All rights reserved.
//

#import "BeautyCameraViewController.h"
#import "TiInitManagerOC.h"
#import <TiSDK/TiSDK.h>

#import <Masonry/Masonry.h>
@import MeMeKit;

#import "BeautySettingCardViewController.h"

#import "BeautyCameraView.h"

@interface BeautyCameraViewController ()

@property(nonatomic, nonnull,strong)BeautyCameraView *cameraView;

@property (nonatomic, weak) BeautySettingCardViewController *settingVC;


@end

@implementation BeautyCameraViewController


- (BeautyCameraView *)cameraView{
    if (_cameraView==nil) {
        _cameraView = [[BeautyCameraView alloc] initWithFrame:CGRectMake(0, 0, 720, 1280)];
        
    }
    return _cameraView;
}
 
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBarHidden = YES;
    [self setUI];
     self.view.userInteractionEnabled = YES;
    
    
    BeautySettingCardViewController* vc = [[BeautySettingCardViewController alloc] init];
    __weak __typeof(self)weakSelf = self;
    vc.resetAllClickedBlock = ^(void) {
        if(weakSelf==nil){return;}
        if (weakSelf.resetAllClickedBlock != nil) {
            weakSelf.resetAllClickedBlock();
        }
    };
    self.settingVC = vc;
    [MeMeShowManager commonBottomShowWithSuperController:self rootVC:vc isCornerLandscape:NO fadeColor:UIColor.clearColor topRadius:0 needClip:NO tapDismiss:NO];
    
    [self.cameraView startCapture];
}

-(void)setUI{
    
    [TiInitManagerOC.shareinstance initSDK];

    [self.view addSubview:self.cameraView];
    [self.cameraView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
}

// MARK: --TiUIManagerDelegate Delegate--
-(void)didClickCameraCaptureButton{
    //拍照
    
}

-(void)didClickSwitchCameraButton{
    //切换摄像头
    
}

-(void)resetAllSetting {
    [self.settingVC resetAllSetting];
}



- (void)dealloc {
 
}

@end
