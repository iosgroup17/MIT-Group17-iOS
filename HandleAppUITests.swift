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
