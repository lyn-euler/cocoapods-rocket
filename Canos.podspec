#
# Be sure to run `pod lib lint Canos.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Canos'
  s.version          = '0.1.1'
  s.summary          = 'A config manager lib for caicai.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  A config manager lib for caicai.
  Support local remote cache & remote options
                       DESC

  s.homepage         = 'https://github.com/asynclog/Canos'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'asynclog' => 'asynclog@163.com' }
  s.source           = { :git => 'https://github.com/asynclog/Canos.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  #s.repos = ['git@git.caicaivip.com:frontend/ios/dlb-cocoapods-spec.git']
  s.ios.deployment_target = '8.0'

  
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |core|
    core.source_files = 'Canos/Classes/*.h', 'Canos/Classes/Core/*.{h,m}'
    core.dependency 'YYKit'
  end
  
  s.subspec 'CCHosts' do |hosts|
    hosts.source_files = 'Canos/Classes/CCHosts/*.{h,m}'
    hosts.dependency 'Canos/Core'
#    hosts.dependency 'CCHttpClient'
  end

  # s.resource_bundles = {
  #   'Canos' => ['Canos/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  
end
