//
//  TiCaptureSessionManager.m
//  TiSDKDemo
//
//  Created by N17 on 2021/2/23.
//  Copyright © 2021 Tillusory Tech. All rights reserved.
//

#import "TiCaptureSessionManager.h"
#import <UIKit/UIKit.h>

static TiCaptureSessionManager *shareManager = NULL;
static dispatch_once_t token;

@interface TiCaptureSessionManager ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation TiCaptureSessionManager

// MARK: --单例初始化方法--
+ (TiCaptureSessionManager *)shareManager {
    dispatch_once(&token, ^{
        shareManager = [[TiCaptureSessionManager alloc] init];
    });
    return shareManager;
}

+ (void)releaseShareManager{
    token = 0; // 只有置成0,GCD才会认为它从未执行过.它默认为0.这样才能保证下次再次调用shareInstance的时候,再次创建对象.
    shareManager = nil;
}

- (void)startAVCaptureDelegate:(id<TiCaptureSessionManagerDelegate>)delegate{
    if (self.session != nil)  {return;}
    self.delegate = delegate;
    self.session = [[AVCaptureSession alloc] init];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [self.session setSessionPreset:AVCaptureSessionPreset1280x720]; // 设置视频帧尺寸
    }
    else
    {
        [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    // 设置摄像头采集位置（前置/后置）
    // 默认为前置摄像头
    if (@available(iOS 10.0, *)) {
        NSArray *devices = [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront] devices];
        for (AVCaptureDevice *device in devices) {
            if ([device hasMediaType: AVMediaTypeVideo]) {
                if ([device position] == AVCaptureDevicePositionFront) {
                    self.cameraPosition = device;
                }
            }
        }
    } else {
        // Fallback on earlier versions
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice: self.cameraPosition error:&error];
    if (!input) {
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    
    AVCaptureVideoDataOutput * dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames: false];
    // 设置视频帧格式
    [dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    dispatch_queue_t queue = dispatch_queue_create("dataOutputQueue", NULL);
    [dataOutput setSampleBufferDelegate:self queue:queue];
    
    
    __weak __typeof(self)weakSelf = self;

    
    [weakSelf.session beginConfiguration];
    if ([weakSelf.session canAddInput:input]) {
        [weakSelf.session addInput:input];
    }
    if ([weakSelf.session canAddOutput:dataOutput]) {
        [weakSelf.session addOutput:dataOutput];
    }
    AVCaptureConnection* connect = [dataOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connect isVideoOrientationSupported]) {
        connect.videoOrientation = [self getCaptureVideoOrientation];
    }
    [weakSelf.session commitConfiguration];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf.session startRunning];
    });
    
}

// 视频帧回调函数
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    BOOL isMirror = ([self.cameraPosition position] == AVCaptureDevicePositionFront);
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    NSInteger rotation;
    
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            rotation = 0;
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotation = isMirror ? 90 : 0;
            break;
        case UIDeviceOrientationLandscapeRight:
            rotation = isMirror ? 0 : 90;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotation = 180;
            break;
        default:
            rotation = 0;
            break;
    }
    
    if (self.delegate) {
        [self.delegate captureSampleBuffer:sampleBuffer Rotation:rotation Mirror:isMirror];
    }
    
}

- (AVCaptureVideoOrientation)getCaptureVideoOrientation {
    AVCaptureVideoOrientation result;
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            //如果这里设置成AVCaptureVideoOrientationPortraitUpsideDown，则视频方向和拍摄时的方向是相反的。
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            result = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            result = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            result = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    return result;
}

- (void)didClickSwitchCameraButton {
    
    NSArray *inputs = self.session.inputs;
    if (inputs != nil) {
        for ( AVCaptureDeviceInput *input in inputs ) {
            AVCaptureDevice *device = input.device;
            //先移除当前摄像头采集的画面
            [self.session removeInput:input];
            AVCaptureVideoDataOutput * dataOutput = self.session.outputs.firstObject;
            if ( [device hasMediaType:AVMediaTypeVideo] ) {
                AVCaptureDevicePosition position = device.position;
                self.cameraPosition = nil;
                AVCaptureDeviceInput *newInput = nil;
                if (position == AVCaptureDevicePositionFront){
                    self.cameraPosition = [self cameraWithPosition:AVCaptureDevicePositionBack];
                }else{
                    self.cameraPosition = [self cameraWithPosition:AVCaptureDevicePositionFront];
                }
                newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.cameraPosition error:nil];
                // beginConfiguration ensures that pending changes are not applied immediately
                [self.session beginConfiguration];
                [self.session addInput:newInput];
                // Changes take effect once the outermost commitConfiguration is invoked.
                
                [self.session commitConfiguration];
                if(dataOutput != nil) {
                    AVCaptureConnection* connect = [dataOutput connectionWithMediaType:AVMediaTypeVideo];
                    if ([connect isVideoOrientationSupported]) {
                        connect.videoOrientation = [self getCaptureVideoOrientation];
                    }
                }
                
                break;
            }
        }
    }
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    AVCaptureDevice* useDevice = nil;
    // 默认为前置摄像头
    if (@available(iOS 10.0, *)) {
        NSArray *devices = [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position] devices];
        for (AVCaptureDevice *device in devices) {
            if ([device hasMediaType: AVMediaTypeVideo]) {
                if ([device position] == position) {
                    useDevice = device;
                    break;
                }
            }
        }
    } else {
        // Fallback on earlier versions
    }
    return useDevice;
}


// MARK: --destroy释放 相关代码--
- (void)destroy{
    [self.session stopRunning];
    self.session = nil;
}

@end
