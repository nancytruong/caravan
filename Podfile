#Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'caravan-ios' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for caravan-ios
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'Mapbox-iOS-SDK', '~> 3.4.1'
  pod 'MapboxDirections.swift', :git => 'https://github.com/mapbox/MapboxDirections.swift.git', :branch => 'swift3'
  pod 'MapboxNavigation.swift', :git => 'https://github.com/mapbox/MapboxNavigation.swift.git', :tag => 'v0.0.4'
  pod 'MapboxGeocoder.swift', :git => 'https://github.com/mapbox/MapboxGeocoder.swift.git', :branch => 'swift3'

  target 'caravan-iosTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'Firebase/Core'
  end

  target 'caravan-iosUITests' do
    inherit! :search_paths
    # Pods for testing
    pod 'Firebase/Core'
  end

end
