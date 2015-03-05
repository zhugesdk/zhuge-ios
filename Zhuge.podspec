Pod::Spec.new do |s|
  s.name         = "Zhuge"
  s.version      = "1.3.5"
  s.summary      = "iOS tracking library for Zhuge Analytics"
  s.homepage     = "http://zhuge.io"
  s.license      = "MIT"
  s.author       = { "37degree,Inc" => "support@37degree.com" }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/zhugesdk/zhuge-ios.git", :tag => "1.3.5" }
  s.source_files = "Classes", "Zhuge/**/*.{h,m}"
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'Accelerate', 'CoreGraphics', 'QuartzCore'
  non_arc_files = 'Zhuge/ZG_OpenUDID.m',
  s.subspec 'no-arc' do |sna|
  s.requires_arc = true
  sna.requires_arc = false
  sna.source_files = non_arc_files
end
