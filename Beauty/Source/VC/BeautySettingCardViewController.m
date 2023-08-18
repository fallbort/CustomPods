//
//  BeautySettingCardViewController.m
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/17.
//

#import "BeautySettingCardViewController.h"
@import MeMeKit;
#import "TiUIMainMenuView.h"
#import "Masonry.h"

@interface BeautySettingCardViewController ()

@end

@implementation BeautySettingCardViewController

#pragma mark <>外部变量

#pragma mark <>外部block

#pragma mark <>生命周期开始
-(instancetype)init {
    self = [super initWithNibName:nil bundle:nil];
    CGFloat extraBottom = [UIWindow keyWindowSafeAreaInsets].bottom;
    self.contentSizeInPopup = CGSizeMake(UIScreen.mainScreen.bounds.size.width, 228 + extraBottom);
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupViews];
}

-(void)setupViews {
    TiUIMainMenuView* menuView = [[TiUIMainMenuView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeInPopup.width, self.contentSizeInPopup.height)];
    [self.view addSubview:menuView];
    [menuView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
}

#pragma mark <>功能性方法

#pragma mark <>内部View

#pragma mark <>内部UI变量

#pragma mark <>内部数据变量

#pragma mark <>内部block


@end
