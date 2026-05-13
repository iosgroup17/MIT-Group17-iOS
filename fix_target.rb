require 'xcodeproj'

project_path = 'HandleApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

ui_test_target = project.targets.find { |t| t.name == 'HandleAppUITests' }
ui_test_target.build_configuration_list.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  config.build_settings['EXECUTABLE_NAME'] = '$(EXECUTABLE_NAME)'
  config.build_settings['TEST_TARGET_NAME'] = 'HandleApp'
end

project.save
puts "Fixed PRODUCT_NAME for HandleAppUITests."
