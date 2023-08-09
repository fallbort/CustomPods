#
#  Be sure to run `pod spec lint MeMeCustomPods.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "MeMeCustomPods"
  spec.version      = "1.0.0"
  spec.summary      = "MeMeCustomPods Modules"

  spec.description  = <<-DESC
                   MeMeCustomPods Modules,contain,
                   1.MeMeCustomPods
                   DESC

  spec.homepage     = "https://bitbucket.org/funplus/streaming-client-compents"

  spec.license      = "MIT"
#  spec.license      = { :type => "MIT", :file => "LICENSE.md" }

  spec.author             = { "xfb" => "fabo.xie@nextentertain.com" }

  # spec.platform     = :ios
   spec.platform     = :ios, "10.0"
   spec.ios.deployment_target = "10.0"

  spec.source       = { :git => "https://bitbucket.org/funplus/streaming-client-compents.git",:tag => "#{spec.version}" }

  spec.swift_version = '5.0'
  spec.static_framework = true

  spec.default_subspec = 'Base'

  spec.subspec 'Base' do |base|
      base.source_files = 'Base/Source/**/*.{h,m,mm,swift}'
      base.framework    = "Foundation"
  end

  spec.subspec 'AnyImageKit' do |base|
      base.source_files = 'AnyImageKit/Sources/AnyImageKit/Core/**/*.swift','AnyImageKit/Sources/AnyImageKit/Picker/**/*.swift','AnyImageKit/Sources/AnyImageKit/Editor/**/*.swift','AnyImageKit/Sources/AnyImageKit/Capture/**/*.{swift,metal}'
      base.resource_bundles = {'AnyImageKit_Core' => 'AnyImageKit/Sources/AnyImageKit/Resources/Core/**/*', 'AnyImageKit_Picker' => 'AnyImageKit/Sources/AnyImageKit/Resources/Picker/**/*', 'AnyImageKit_Editor' => 'AnyImageKit/Sources/AnyImageKit/Resources/Editor/**/*', 'AnyImageKit_Capture' => 'AnyImageKit/Sources/AnyImageKit/Resources/Capture/**/*'}
      base.framework    = "UIKit","Foundation"
      base.dependency 'SnapKit'
      base.dependency 'MeMeKit'
      base.dependency 'Kingfisher'
      # base.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'ANYIMAGEKIT_ENABLE_PICKER' }
      # base.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'ANYIMAGEKIT_ENABLE_EDITOR' }
      # base.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'ANYIMAGEKIT_ENABLE_CAPTURE' }
  end
  
  spec.subspec 'PhotoPicker' do |base|
      base.source_files = 'PhotoPicker/Source/**/*.swift'
      base.dependency 'MeMeKit/MeMeBaseKit'
      base.dependency 'MeMeComponents/Net'
      base.dependency 'MeMeCustomPods/AnyImageKit'
      base.dependency 'TOCropViewController'
      base.dependency 'MBProgressHUD'
      base.dependency 'RxSwift'
      base.dependency 'Result'
      base.frameworks    = "Foundation", "Photos"
  end

  spec.subspec 'ShareAndPay' do |base|
      base.source_files = 'ShareAndPay/Source/**/*.{h,m,mm,swift}','ShareAndPay/*.{modulemap}','ShareAndPay/Modules/*.{h}'
      base.framework    = "Foundation"

      base.dependency 'UMCommon'
      base.dependency 'UMDevice'
      base.dependency 'UMCCommonLog'

      base.dependency 'UMShare/UI'
      base.dependency 'UMShare/Social/ReducedWeChat'
      base.dependency 'UMLink'
      
      base.dependency 'WechatOpenSDK'
      
      base.prefix_header_contents  =  '#import "WXApi.h"' , '#import <UMCommon/UMCommon.h>', '#import <UMCommonLog/UMCommonLogManager.h>'
#      base.public_header_files = 'ShareAndPay/Source/**/*.{h}'

#base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/path_to/CommonCrypto' }
#base.user_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/path_to/CommonCrypto' }

base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/ShareAndPay'] }


#      base.dependency 'MeMeKit'
      
  end

  spec.subspec 'JiGuang' do |base|
      base.source_files = 'JiGuang/Source/**/*.{h,m,mm,swift}','JiGuang/*.{modulemap}','JiGuang/Modules/*.{h}'
#      base.resource_bundles = {'JVerificationResource' => 'JiGuang/Resources/JVerificationResource/**/*'}
      base.resources = ['JiGuang/Resources/JVerificationResource.bundle']
      base.framework    = "Foundation"

      base.dependency 'JCore','4.2.1-noidfa'
      base.dependency 'JPush'
      base.dependency 'JVerification'
      
      base.dependency 'MeMeKit'

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/JiGuang'] }

  end

  spec.subspec 'Face' do |base|
      base.source_files = 'Face/Source/**/*.{h,m,mm,swift}','Face/*.{modulemap}','Face/Modules/*.{h}'
#      base.resource_bundles = {'MGFaceIDLiveCustomDetect' => 'Face/Sdk/resource/*.bundle'}
    base.resources = ['Face/Sdk/resource/MGFaceIDLiveCustomDetect.bundle']
      base.public_header_files = 'Face/Source/**/*.{h}'
      base.framework    = "UIKit","CoreMotion","MediaPlayer"
      
#      base.prefix_header_contents  = '@import MeMeKit;'
      
      base.dependency 'MeMeKit'

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/Face'] }

      base.vendored_frameworks    = "Face/Sdk/framework/**/*.framework"
  end

  spec.subspec 'Beauty' do |base|
      base.source_files = 'Beauty/Source/**/*.{h,m,mm,swift}','Beauty/*.{modulemap}','Beauty/Modules/*.{h}'
      base.resource_bundles = {
        'TiUIIcon' => ['Beauty/Sdk/TiUI/TiUIIcon/*'],
        'TiSDKResource' => ['Beauty/Sdk/TiSDKResource.bundle/*']}
#      base.resources = ['Beauty/Sdk/TiSDKResource.bundle']
      base.public_header_files = 'Beauty/Source/**/*.{h}'
      base.framework    = "Foundation"
      
#      base.prefix_header_contents  = '@import MeMeKit;'
      
      base.dependency 'MeMeKit'

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/Beauty'] }

      base.vendored_frameworks    = "Beauty/Sdk/*.framework"
  end

  spec.subspec 'Login' do |base|
      base.source_files = 'Login/Source/**/*.{h,m,mm,swift}','Login/*.{modulemap}','Login/Modules/*.{h}'
      base.public_header_files = 'Login/Source/**/*.{h}'
      base.framework    = "Foundation", "AuthenticationServices"

#      base.prefix_header_contents  = '@import MeMeKit;'


      base.dependency 'MeMeKit'
      base.dependency 'MeMeComponents/Base'

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/Login'] }

      base.vendored_frameworks    = "Login/Sdk/*.framework"
  end
  
  spec.subspec 'LTScrollview' do |base|
      base.source_files = 'LTScrollview/Source/**/*.{h,m,mm,swift}','LTScrollview/*.{modulemap}','LTScrollview/Modules/*.{h}'
      base.public_header_files = 'LTScrollview/Source/**/*.{h}'
      base.framework    = "UIKit"

#      base.prefix_header_contents  = '@import MeMeKit;'

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/LTScrollview'] }

      base.vendored_frameworks    = "LTScrollview/Sdk/*.framework"
  end

  spec.subspec 'MainPush' do |base|
      base.source_files = 'MainPush/Source/**/*.{h,m,mm,swift}','MainPush/*.{modulemap}','MainPush/Modules/*.{h}'
      base.public_header_files = 'MainPush/Source/**/*.{h}'
      base.framework    = "UIKit"

#      base.prefix_header_contents  = '@import MeMeKit;'

      base.dependency 'MeMeKit'

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/MainPush'] }

      base.vendored_frameworks    = "MainPush/Sdk/*.framework"
  end

  spec.subspec 'Netty' do |base|
      base.source_files = 'Netty/Source/**/*.{h,m,mm,swift}','Netty/*.{modulemap}','Netty/Modules/*.{h}'
      base.public_header_files = 'Netty/Source/**/*.{h}'
      base.framework    = "UIKit"

#      base.prefix_header_contents  = '@import MeMeKit;'

      base.dependency 'CocoaAsyncSocket'
      base.dependency 'Result'
      base.dependency 'ObjectMapper'
      base.dependency 'MeMeKit/MeMeBaseKit'
      base.dependency 'Alamofire'

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/Netty'] }

      base.vendored_frameworks    = "Netty/Sdk/*.framework"
  end
  
  spec.subspec 'MeMePlugin' do |base|
      base.source_files = 'MeMePlugin/Source/**/*.{h,m,mm,swift}','MeMePlugin/*.{modulemap}','MeMePlugin/Modules/*.{h}'
      base.public_header_files = 'MeMePlugin/Source/**/*.{h}'
      base.framework    = "UIKit"

#      base.prefix_header_contents  = '@import MeMeKit;'

      base.dependency 'MeMeKit/MeMeBaseKit'
      base.dependency 'RxSwift'

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/MeMePlugin'] }

      base.vendored_frameworks    = "MeMePlugin/Sdk/*.framework"
  end
  
  spec.subspec 'PushPull' do |base|
      base.source_files = 'PushPull/Source/**/*.{h,m,mm,swift}','PushPull/*.{modulemap}','PushPull/Modules/*.{h}'
      base.public_header_files = 'PushPull/Source/**/*.{h}'
      base.framework    = "UIKit"

#      base.prefix_header_contents  = '@import MeMeKit;'

      base.dependency 'MeMeKit/MeMeBaseKit'
      base.dependency 'RxSwift'
      
      base.dependency 'AgoraRtcEngine_iOS', '3.6.1.4'
#      base.dependency 'ZegoExpressEngine'
      base.dependency 'SwiftyJSON'

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/PushPull'] }

      base.vendored_frameworks    = "PushPull/Sdk/*.framework"
  end
  
  spec.subspec 'MeMePay' do |base|
      base.source_files = 'MeMePay/Source/**/*.{h,m,mm,swift}','MeMePay/*.{modulemap}','MeMePay/Modules/*.{h}'
      base.public_header_files = 'MeMePay/Source/**/*.{h}'
      base.framework    = "UIKit"

#      base.prefix_header_contents  = '@import MeMeKit;'

      base.dependency 'MeMeKit/MeMeBaseKit'
      base.dependency 'MeMeCustomPods/Base'
      base.dependency 'MeMeCustomPods/MeMePayData'
      base.dependency 'RxSwift'
      base.dependency 'SwiftyJSON'
      base.dependency 'ObjectMapper'
      base.dependency 'Result'
      base.dependency 'Cartography'
      base.dependency 'YYModel'
      
      

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/MeMePay'] }

      base.vendored_frameworks    = "MeMePay/Sdk/*.framework"
  end
  
  spec.subspec 'MeMePayData' do |base|
      base.source_files = 'MeMePayData/Source/**/*.{h,m,mm,swift}','MeMePayData/*.{modulemap}','MeMePayData/Modules/*.{h}'
      base.public_header_files = 'MeMePayData/Source/**/*.{h}'
      base.framework    = "Foundation","StoreKit"

#      base.prefix_header_contents  = '@import MeMeKit;'

      base.dependency 'MeMeKit/MeMeBaseKit'
      base.dependency 'SwiftyUserDefaults'
      base.dependency 'ObjectMapper'
      
      

      base.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => ['$(PODS_TARGET_SRCROOT)/MeMePayData'] }

      base.vendored_frameworks    = "MeMePayData/Sdk/*.framework"
  end

end
