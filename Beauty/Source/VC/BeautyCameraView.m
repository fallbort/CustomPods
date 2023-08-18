//
//  BeautyCameraView.m
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/18.
//

#import "BeautyCameraView.h"
#import "TiCaptureSessionManager.h"
#import <TiSDK/TiLiveView.h>
#import "TiInitManagerOC.h"
#import <TiSDK/TiSDK.h>
#import <Masonry/Masonry.h>
@import MeMeKit;

NSInteger m_beautyCameraViewCount = 0;

@interface BeautyCameraView ()
@property(nonatomic, nonnull,strong)TiLiveView *tiLiveView;
@property (nonatomic, strong) TiCaptureSessionManager *captureManager;
@end

@implementation BeautyCameraView

#pragma mark <>外部变量

#pragma mark <>外部block

#pragma mark <>生命周期开始
- (void)dealloc {
    m_beautyCameraViewCount -= 1;
    if (m_beautyCameraViewCount <=0) {
        [[TiSDKManager shareManager] destroy];
    }
    [self.captureManager destroy];
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        m_beautyCameraViewCount += 1;
        _captureVideoSize = CGSizeMake(720, 1280);
        [self setupViews];
        [self setupData];
    }
    return self;
}

-(void)setupViews {
    [self addSubview:self.tiLiveView];
    [self.tiLiveView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
}

-(void)setupData {
    self.captureManager = [[TiCaptureSessionManager alloc] init];
}

#pragma mark <>功能性方法
-(void)switchCamera{
    //切换摄像头
    [self.captureManager didClickSwitchCameraButton];
}

#pragma mark <>内部View
- (TiLiveView *)tiLiveView{
    if (_tiLiveView==nil) {
        [_tiLiveView setupPreview:kCV_BGRA];
        
    }
    return _tiLiveView;
}

#pragma mark <>内部UI变量

#pragma mark <>内部数据变量

#pragma mark <>内部block

// MARK: --TiCaptureSessionManager Delegate--
-(void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer Rotation:(NSInteger)rotation Mirror:(BOOL)isMirror{
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    if (pixelBuffer == NULL) {
        return;
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    unsigned char *baseAddress = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    // 视频帧格式
    TiImageFormatEnum format;
    switch (CVPixelBufferGetPixelFormatType(pixelBuffer)) {
        case kCVPixelFormatType_32BGRA:
            format = BGRA;
            break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            format = NV12;
            break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            format = NV12;
            break;
        default:
            NSLog(@"错误的视频帧格式！");
            format = BGRA;
            break;
    }
    
    int imageWidth, imageHeight;
    if (format == BGRA) {
        imageWidth = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) / 4;
        imageHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    } else {
        imageWidth = (int)CVPixelBufferGetWidthOfPlane(pixelBuffer , 0);
        imageHeight = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer , 0);
    }
        
    // FIXME: --QZW baseAddress pixelBuffer 不为空，但是无图像，导致渲染方法奔溃--
    /////////////////// TiFaceSDK 添加 开始 ///////////////////

    [[TiSDKManager shareManager] renderPixels:baseAddress Format:format Width:imageWidth Height:imageHeight Rotation:rotation Mirror:isMirror FaceNumber:5];
    /////////////////// TiFaceSDK 添加 结束 ///////////////////
    if (self.tiLiveView) {
        [self.tiLiveView startPreview:pixelBuffer isMirror:isMirror];
    }
    
//    self.outputImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//    self.outputImagePixelBuffer = pixelBuffer;
//    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
}


@end
