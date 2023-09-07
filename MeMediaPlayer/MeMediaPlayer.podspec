#
#  Be sure to run `pod spec lint MeMeBaseKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "MeMediaPlayer"
  spec.version      = "1.0.0"
  spec.summary      = "MeMediaPlayer Modules"

  spec.description  = <<-DESC
                   MeMediaPlayer Modules,contain,
                   1.MeMediaPlayer
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

  spec.source_files  = "MeMediaPlayerKit/*.{h,m,swift}"
  spec.public_header_files = 'MeMediaPlayerKit/*.{h}'
#  spec.frameworks = "MeMediaPlayer"
  spec.vendored_frameworks    = "MeMediaPlayer.framework"
  # spec.vendored_libraries = 'IJKPlayerKit_Oc/Frameworks/IJKMediaFramework.framework/libIJKMediaFramework.a'
end
