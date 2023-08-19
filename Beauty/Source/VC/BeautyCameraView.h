//
//  BeautyCameraView.h
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/18.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface BeautyCameraView : UIView
@property (nonatomic, assign) CGSize captureVideoSize;
@property (nonatomic,copy)void(^sampleBufferBlock)(CMSampleBufferRef sampleBuffer,CVPixelBufferRef pixelBuffer);
-(void)startCapture;
-(void)stopCapture;
-(void)switchCamera;

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position;
@end

NS_ASSUME_NONNULL_END
