#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_facebook_login'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for allowing users to authenticate with native Android &amp; iOS Facebook login SDKs.'
  s.description      = <<-DESC
A Flutter plugin for allowing users to authenticate with native Android &amp; iOS Facebook login SDKs.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'FBSDKCoreKit', '4.38.0'
  s.dependency 'FBSDKLoginKit', '4.38.0'
  s.dependency 'FBSDKShareKit', '4.38.0'
    
  s.ios.deployment_target = '10.2'
end

