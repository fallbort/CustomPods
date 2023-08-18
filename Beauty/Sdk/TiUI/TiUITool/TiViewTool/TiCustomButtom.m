//
//  TiCustomButtom.m
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/18.
//

#import "TiCustomButtom.h"
#import "Masonry.h"
@import MeMeKit;

@interface TiCustomButtom ()
@property (nonatomic, strong) UIView *selectedDot;
@end

@implementation TiCustomButtom

#pragma mark <>外部变量

#pragma mark <>外部block

#pragma mark <>生命周期开始
- (instancetype)initWithScaling:(CGFloat)scaling {
    self = [super initWithScaling:scaling];
    if (self) {
        [self setupViews];
    }
    return self;
}

-(void)setupViews {
    [self addSubview:self.selectedDot];
    [self.bottomLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.top.mas_equalTo(self.selectView.mas_bottom).offset(6);
        make.height.mas_equalTo(22);
    }];
    
    [self.selectedDot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.top.equalTo(self.bottomLabel.mas_bottom).offset(6);
        make.width.mas_equalTo(6);
        make.height.mas_equalTo(6);
    }];
}

#pragma mark <>功能性方法
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.selectedDot.hidden = !selected;
    
}
#pragma mark <>内部View
-(UIView *)selectedDot {
    if (!_selectedDot) {
        _selectedDot = [[UIView alloc]init];
        _selectedDot.backgroundColor =  [UIColor hexStringToColor:@"#FD4186"];
        _selectedDot.layer.cornerRadius = 3.0;
        _selectedDot.clipsToBounds = YES;
    }
    return _selectedDot;
}
#pragma mark <>内部UI变量

#pragma mark <>内部数据变量

#pragma mark <>内部block


@end
