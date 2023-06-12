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
      base.source_files = 'Source/Base/**/*.{h,m,swift}'
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

  spec.subspec 'ShareAndPay' do |base|
      base.source_files = 'ShareAndPay/Source/**/*.{h,m,swift}','ShareAndPay/**/*.{modulemap}'
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
end
