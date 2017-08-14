Pod::Spec.new do |s|
  s.name         = "Zhugeio"
  s.version      = "3.1.3"
  s.summary      = "iOS tracking library for Zhugeio Analytics"
  s.homepage     = "http://zhugeio.com"
  s.license      = "MIT"
  s.author       = { "Zhugeio,Inc" => "info@zhugeio.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/zhugesdk/zhuge-ios.git", :tag => s.version }
  s.requires_arc = true
  s.default_subspec = 'Zhugeio'

  
  s.subspec 'Zhugeio' do |ss|
    ss.source_files  = 'HelloZhuge/HelloZhuge/Zhuge/*.{m,h}'
    ss.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration'
    ss.libraries = 'z'
  end
end