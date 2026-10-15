require 'xcodeproj'

project_path = 'HandleApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find targets
app_target = project.targets.find { |t| t.name == 'HandleApp' }
ui_test_target = project.targets.find { |t| t.name == 'HandleAppUITests' }

# Create a new scheme
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.set_launch_target(app_target)

# Add Test target
test_action = Xcodeproj::XCScheme::TestAction.new
testable_ref = Xcodeproj::XCScheme::TestAction::TestableReference.new(ui_test_target)
test_action.add_testable(testable_ref)
scheme.test_action = test_action

# Save scheme
shared_data_dir = File.join(project_path, 'xcshareddata', 'xcschemes')
require 'fileutils'
FileUtils.mkdir_p(shared_data_dir)
scheme.save_as(project_path, 'HandleAppUITestsScheme', true)

puts "Scheme HandleAppUITestsScheme created."
