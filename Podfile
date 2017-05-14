#Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'caravan-ios' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for caravan-ios
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'Mapbox-iOS-SDK', '~> 3.5'
  pod 'MapboxGeocoder.swift', '~> 0.6'
  pod 'MapboxDirections.swift', '0.8.1’
  pod 'MapboxNavigation', '~> 0.2'
  pod 'MapboxCoreNavigation', '~> 0.2'
  #pod 'OSRMTextInstructions', :git => 'https://github.com/Project-OSRM/osrm-text-instructions.swift.git'

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
