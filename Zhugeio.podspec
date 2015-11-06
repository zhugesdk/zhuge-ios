Pod::Spec.new do |s|
  s.name         = "Zhugeio"
  s.version      = "2.0.1"
  s.summary      = "iOS tracking library for Zhugeio Analytics"
  s.homepage     = "http://zhugeio.com"
  s.license      = "MIT"
  s.author       = { "Zhugeio,Inc" => "info@zhugeio.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/zhugesdk/zhuge-ios.git", :tag => s.version }
  s.requires_arc = true
  s.default_subspec = 'Zhugeio'

  
  s.subspec 'Zhugeio' do |ss|
    ss.source_files  = 'Zhuge/**/*.{m,h}'
    ss.resources   = ['Zhuge/**/*.json']
    ss.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'Accelerate', 'CoreGraphics', 'QuartzCore', 'Security','CoreMotion'
    ss.libraries = 'icucore','z'
  end

  s.subspec 'AppExtension' do |ss|
    ss.source_files  = ['Zhuge/Zhuge.{m,h}', 'Zhuge/ZGLog.h', 'Zhuge/*.{m,h}' ]
    ss.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) ZHUGE_APP_EXTENSION'}
    ss.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'Accelerate', 'CoreGraphics', 'QuartzCore', 'Security','CoreMotion'
    ss.libraries = 'icucore','z'
  end
end