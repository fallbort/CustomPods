#
#  Be sure to run `pod spec lint AnyImageKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "AnyImageKit"
  spec.version      = "1.0.0"
  spec.summary      = "AnyImageKit Modules"

  spec.description  = <<-DESC
                   AnyImageKit Modules,contain,
                   1.AnyImageKit
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
      base.source_files = 'Sources/AnyImageKit/Core/**/*.swift','Sources/AnyImageKit/Picker/**/*.swift','Sources/AnyImageKit/Editor/**/*.swift','Sources/AnyImageKit/Capture/**/*.{swift,metal}'
      base.resource_bundles = {'AnyImageKit_Core' => 'Sources/AnyImageKit/Resources/Core/**/*', 'AnyImageKit_Picker' => 'Sources/AnyImageKit/Resources/Picker/**/*', 'AnyImageKit_Editor' => 'Sources/AnyImageKit/Resources/Editor/**/*', 'AnyImageKit_Capture' => 'Sources/AnyImageKit/Resources/Capture/**/*'}
      base.framework    = "UIKit","Foundation"
      base.dependency 'MeMeKit'
      base.dependency 'SnapKit'
      base.dependency 'Kingfisher'
      # base.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'ANYIMAGEKIT_ENABLE_PICKER' }
      # base.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'ANYIMAGEKIT_ENABLE_EDITOR' }
      # base.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'ANYIMAGEKIT_ENABLE_CAPTURE' }
  end

end
