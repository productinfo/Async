#
# Be sure to run `pod lib lint Async.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SwiftAsync"
  s.version          = "0.2.0"
  s.summary          = "Async, await control flow for Swift."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                       Async, await control flow for Swift, similar to co.js/vo.js/ES7 async function.
                       DESC

  s.homepage         = "https://github.com/zhxnlai/Async"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Zhixuan Lai" => "zhxnlai@gmail.com" }
  s.source           = { :git => "https://github.com/zhxnlai/Async.git", :tag => s.version.to_s }
  s.social_media_url   = "http://twitter.com/ZhixuanLai"

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'Async' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
