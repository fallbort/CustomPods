//
//  BeautyGLView.h
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/19.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
@interface BeautyGLView : UIView

- (void)setupGL;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
