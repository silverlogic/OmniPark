# Uncomment the next line to define a global platform for your project
# platform :ios, '11.0'

target 'OminPark' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for OminPark
  pod 'Alamofire', '~> 4.5.1'
  pod 'SwiftyJSON', '~> 4.0.0-alpha.1'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.2'
        end
    end
end
end

target 'watchapp' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for watchapp

end

target 'watchapp Extension' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for watchapp Extension

end
