Pod::Spec.new do |s|
  s.name         = "Zhugeio"
  s.version      = "2.0.0"
  s.summary      = "iOS tracking library for Zhugeio Analytics"
  s.homepage     = "http://zhugeio.com"
  s.license      = "MIT"
  s.author       = { "Zhugeio,Inc" => "info@zhugeio.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/zhugesdk/zhuge-ios.git", :tag => s.version }
  s.frameworks   = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'Accelerate', 'CoreGraphics', 'QuartzCore', 'Security','CoreMotion'
  s.libraries = 'icucore','z'
  s.source_files = "Classes", "Zhuge/**/*.{h,m,json}"
  s.requires_arc = true
end