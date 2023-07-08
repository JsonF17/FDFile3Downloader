#
# Be sure to run `pod lib lint FDFile3Downloader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FDFile3Downloader'
  s.version          = '0.1.0'
  s.summary          = 'A short description of FDFile3Downloader.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/JsonF17/FDFile3Downloader.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JsonF17' => 'fei122603@outlook.com' }
  s.source           = { :git => 'https://github.com/JsonF17/FDFile3Downloader.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'FDFile3Downloader/Classes/**/*.{h,m}'
  
  # s.resource_bundles = {
  #   'FDFile3Downloader' => ['FDFile3Downloader/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'SJDownloadDataTask'
  s.dependency 'SJMediaCacheServer/KTVCocoaHTTPServer'
  s.dependency 'SJUIKit/SQLite3'
end
