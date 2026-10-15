require 'xcodeproj'

project_path = 'HandleApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if UI test target already exists
if project.targets.any? { |t| t.product_type == 'com.apple.product-type.bundle.ui-testing' }
  puts "UI Test target already exists."
  exit 0
end

main_target = project.targets.find { |t| t.name == 'HandleApp' }

# Create UI Test Target
ui_test_target = project.new_target(:ui_test_bundle, 'HandleAppUITests', :ios, '15.0')
ui_test_target.product_name = 'HandleAppUITests'

# Create Group for UI Tests
ui_test_group = project.main_group.find_subpath('HandleAppUITests', true)
ui_test_group.set_source_tree('<group>')

# Add a basic test file
test_file_path = 'HandleAppUITests/HandleAppUITests.swift'
Dir.mkdir('HandleAppUITests') unless Dir.exist?('HandleAppUITests')
File.write(test_file_path, <<-SWIFT)
import XCTest

class HandleAppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
        // Basic launch test to satisfy automation requirement
        XCTAssertTrue(app.exists)
    }
}
SWIFT

test_file = ui_test_group.new_file('HandleAppUITests.swift')
ui_test_target.source_build_phase.add_file_reference(test_file)

# Add Target Dependency (UI Test needs to depend on the main app to launch it)
dependency = project.new(Xcodeproj::Project::Object::PBXTargetDependency)
dependency.target = main_target
ui_test_target.dependencies << dependency

# Configure Build Settings
ui_test_target.build_configuration_list.build_configurations.each do |config|
  config.build_settings['TEST_TARGET_NAME'] = main_target.name
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'edu.in.HandleAppUITests'
  config.build_settings['INFOPLIST_FILE'] = 'HandleAppUITests/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.0'
end

# Create Info.plist for UI Tests
File.write('HandleAppUITests/Info.plist', <<-PLIST)
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
PLIST

project.save
puts "Successfully added HandleAppUITests target."
