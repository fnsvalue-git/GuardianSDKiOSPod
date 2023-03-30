# Uncomment the next line to define a global platform for your project
 platform :ios, '13.0'

target 'GuardianSDKiOS' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for GuardianSDKiOS
  pod 'Alamofire', '~> 5.5'
  pod 'CryptoSwift', '1.3.2'
  pod 'SwiftyJSON'
  pod 'StompClientLib'
  pod 'DeviceKit'
  pod 'SwiftOTP', '2.0.2'


end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end