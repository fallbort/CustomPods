//
//  TiUISliderNew.m
//  TiSDKDemo
//
//  Created by iMacA1002 on 2019/12/2.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import "TiUISliderNew.h"
#import "TiConfig.h"

@interface TiUISliderNew (){
    CGRect _trackRect;
    TiUISliderType _sliderType;
}

@end

@implementation TiUISliderNew

- (UIImageView *)tagView{
    if (!_tagView) {
//        (TiUISliderHeight*4+2)为滑块直径 TiUISliderHeight/2 为滑条半经
        _tagView = [[UIImageView alloc]initWithFrame:CGRectMake(-TiUISliderTagViewWidth/2+1, -(TiUISliderTagViewHeight + (TiUISliderHeight*6+2)/2 - TiUISliderHeight/2),TiUISliderTagViewWidth, TiUISliderTagViewHeight)];
        //滑动条颜色
        [_tagView setImage:[UIImage imageNamed:@"icon_drag_white.png"]];
        _tagView.alpha = 0;
        _tagView.contentMode = UIViewContentModeScaleAspectFit;
        [_tagView addSubview:self.tagLabel];
    }
    return _tagView;
}

- (UILabel *)tagLabel{
    if (!_tagLabel) {
        _tagLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.tagView.bounds.origin.x,self.tagView.bounds.origin.y,self.tagView.bounds.size.width,self.tagView.bounds.size.height*0.85)];
        [_tagLabel setTextColor:TI_RGB_Alpha(45.0, 45.0, 45.0, 1.0)];
        [_tagLabel setTextAlignment:NSTextAlignmentCenter];
        [_tagLabel setFont:TI_Font_Default_Size_Small];
        _tagLabel.userInteractionEnabled = NO;
    }
    return _tagLabel;
}

- (UIView *)trackColorView{
    if (!_trackColorView) {
        _trackColorView = [[UIView alloc] init];
        _trackColorView.frame = _trackRect;
        _trackColorView.backgroundColor = UIColor.whiteColor;
        _trackColorView.layer.cornerRadius = TiUISliderHeight/2;
        _trackColorView.userInteractionEnabled = NO;
    }
    return _trackColorView;
}

- (UIView *)tagLine{
    if (!_tagLine) {
        _tagLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, TiUISliderHeight*3)];
        _tagLine.hidden = YES;
        _tagLine.backgroundColor = TI_Color_Default_Text_White;
        _tagLine.userInteractionEnabled = NO;
        _tagLine.layer.cornerRadius = 0.5;
    }
    return _tagLine;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _trackRect = CGRectZero;
        [self setBackgroundColor:TI_RGB_Alpha(238.0, 238.0, 238.0, 0.5)];
        self.minimumTrackTintColor = [UIColor clearColor];
        self.maximumTrackTintColor = [UIColor clearColor];
        
        //滑块背景
        [self setThumbImage:[self resizeImage:[UIImage imageNamed:@"icon_huakuai"] toSize:CGSizeMake(TiUISliderHeight*6, TiUISliderHeight*6)]  forState:UIControlStateNormal];
        [self setThumbImage:[self resizeImage:[UIImage imageNamed:@"icon_huakuai"] toSize:CGSizeMake(TiUISliderHeight*6+2, TiUISliderHeight*6+2)] forState:UIControlStateHighlighted];
        self.layer.cornerRadius = TiUISliderHeight/2;
        
        [self addSubview:self.tagView];
        [self addSubview:self.trackColorView];
        [self addSubview:self.tagLine];
        
        //ios 14.0
        [self insertSubview:self.tagLine atIndex:0];
        [self insertSubview:self.trackColorView atIndex:0];
        [self insertSubview:self.tagView atIndex:0];
        [self addTarget:self action:@selector(didBeginUpdateValue:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(didUpdateValue:) forControlEvents:UIControlEventValueChanged];
        [self addTarget:self action:@selector(didEndUpdateValue:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];

    }
    return self;
}

- (void)setSliderType:(TiUISliderType)sliderType WithValue:(float)value{
    _sliderType = sliderType;
    [self refreshWithValue:value isSet:YES];
    if (sliderType == TI_UI_SLIDER_TYPE_ONE)
    {
        self.tagLine.hidden = YES;
        self.minimumValue = 0;
        self.maximumValue = 100;
        [self setValue:value animated:YES];
    }else if (sliderType == TI_UI_SLIDER_TYPE_TWO){
        self.tagLine.hidden = NO;
        self.minimumValue = -50;
        self.maximumValue = 50;
        [self setValue:value animated:YES];
    }
}

//开始拖拽
- (void)didBeginUpdateValue:(UISlider *)sender {
    [self refreshWithValue:sender.value isSet:NO];
    [UIView animateWithDuration:0.3 animations:^{
       [self.tagView setAlpha:1.0f];
    }];
}

//正在拖拽
- (void)didUpdateValue:(UISlider *)sender {
    [self refreshWithValue:sender.value isSet:NO];
}

//结束拖拽
- (void)didEndUpdateValue:(UISlider *)sender {
    [self refreshWithValue:sender.value isSet:NO];
    [UIView animateWithDuration:0.1 animations:^{
       [self.tagView setAlpha:0];
    }];
}

- (void)refreshWithValue:(float)value isSet:(BOOL)set{
    if (self.refreshValueBlock&&!set) {
        self.refreshValueBlock(value);
    }
    if(self.valueBlock){
        self.valueBlock(value);
    }
    if (self->_sliderType == TI_UI_SLIDER_TYPE_ONE)
    {
        self.trackColorView.frame =CGRectMake(0, 0, self->_trackRect.origin.x + TiUISliderHeight*6/2, TiUISliderHeight);
    }
    else if (self->_sliderType == TI_UI_SLIDER_TYPE_TWO)
    {
        CGFloat W = -(self.frame.size.width/2 - (self->_trackRect.origin.x + TiUISliderHeight*6/2));
        self.trackColorView.frame =CGRectMake(self.frame.size.width/2 +0.5 , 0,W , TiUISliderHeight);
    }
    self.tagView.center = CGPointMake(self->_trackRect.origin.x + (TiUISliderHeight*6)/2+1,self.tagView.center.y);
    [self.tagLabel setText:[NSString stringWithFormat:@"%d%@", (int)value, @"%"]];
    
}

//返回滑块轨迹的绘制矩形。
- (CGRect)trackRectForBounds:(CGRect)bounds {
    return CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, MAX(bounds.size.height, 2.0));
}

//调整中间滑块位置，并获取滑块坐标
- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value{
    rect.origin.x = rect.origin.x;
    rect.size.width = rect.size.width;
    _trackRect = [super thumbRectForBounds:bounds trackRect:rect value:value];
    return _trackRect;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *result = [super hitTest:point withEvent:event];
    if (point.x < 0 || point.x > self.bounds.size.width){
        return result;
    }
    if ((point.y >= -TiUISliderHeight*6) && (point.y < _trackRect.size.height + TiUISliderHeight*6)) {
        float value = 0.0;
        value = point.x - self.bounds.origin.x;
        value = value/self.bounds.size.width;
        
        value = value < 0? 0 : value;
        value = value > 1? 1: value;
        
        value = value * (self.maximumValue - self.minimumValue) + self.minimumValue;
        [self setValue:value animated:YES];
    }
    return result;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    BOOL result = [super pointInside:point withEvent:event];
    if (!result && point.y > -10) {
        if ((point.x >= _trackRect.origin.x - TiUISliderHeight*6) && (point.x <= (_trackRect.origin.x + _trackRect.size.width + TiUISliderHeight*6)) && (point.y < (_trackRect.size.height + TiUISliderHeight*6))) {
        result = YES;
        }
      
    }
      return result;
}
 
// FIXME: --layoutSubviews--
- (void)layoutSubviews
{
    [super layoutSubviews];
    //使用 mas //这里才能获取到self.frame 并且刷新Value 视图变动的时候也会调用
     self.tagLine.frame = CGRectMake(self.frame.size.width/2, -TiUISliderHeight*3/2 + TiUISliderHeight/2, 1, TiUISliderHeight*3);
    [self refreshWithValue:self.value isSet:YES];
    
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size{
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}

@end
