//
//  UltimatePortfolioUITests.swift
//  UltimatePortfolioUITests
//
//  Created by Hunter Dobbelmann on 12/18/23.
//

import XCTest

extension XCUIElement {
	func clear() {
		guard let stringValue = self.value as? String else {
			XCTFail("Failed to clear text in XCUIElement")
			return
		}

		let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
		typeText(deleteString)
	}
}

final class UltimatePortfolioUITests: XCTestCase {
	var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

		app = XCUIApplication()
		app.launchArguments = ["enable-testing"]
		app.launch()
    }

    func testAppStartsWithNavigationBar() throws {
		XCTAssertTrue(app.navigationBars.element.exists, "There should be a navigation bar when the app launches.")
    }

	func testAppHasBasicButtonsOnLaunch() throws {
		XCTAssertTrue(app.navigationBars.buttons["Filters"].exists, "There should be a Filters (back) button on launch.")
		XCTAssertTrue(app.navigationBars.buttons["Filter"].exists, "There should be a Filter button on launch.")
		XCTAssertTrue(app.navigationBars.buttons["New Issue"].exists, "There should be a New Issue button on launch.")
	}

	func testNoIssuesAtStart() {
		XCTAssertEqual(app.cells.count, 0, "There should be 0 list rows initially.")
	}

	func testCreatingAndDeletingIssues() {
		for tapCount in 1...5 {
			app.buttons["New Issue"].tap()
			app.buttons["All Issues"].tap()

			XCTAssertEqual(app.cells.count, tapCount, "There should be \(tapCount) rows in the list.")
		}

		for tapCount in (0...4).reversed() {
			app.cells.firstMatch.swipeLeft()
			app.buttons["Delete"].tap()

			XCTAssertEqual(app.cells.count, tapCount, "There should be \(tapCount) rows in the list.")
		}
	}

	func testEditingIssueTitleUpdatesCorrectly() {
		XCTAssertEqual(app.cells.count, 0, "There should be no rows initially.")

		app.buttons["New Issue"].tap()

		app.textFields["Enter the issue title here"].tap()
		app.textFields["Enter the issue title here"].clear()
		app.typeText("My New Issue")

		app.buttons["All Issues"].tap()
		XCTAssertTrue(app.buttons["My New Issue"].exists, "A My New Issue cell should now exist.")
	}

	func testEditingIssuePriorityShowsIcon() {
		app.buttons["New Issue"].tap()
		app.buttons["Priority, Medium"].tap()
		app.buttons["High"].tap()
		app.buttons["All Issues"].tap()

		let identifier = "New issue High Priority"
		XCTAssert(app.images[identifier].exists, "A high-priority issue needs an icon next to it.")
	}

	func testAllAwardsShowLockedAlert() {
		app.buttons["Filters"].tap()
		app.buttons["Show awards"].tap()

		for award in app.scrollViews.buttons.allElementsBoundByIndex {
			// Originally had app.windows.element, but that failed due to having many windows.
			if app.windows.firstMatch.frame.contains(award.frame) == false {
				app.swipeUp()
			}

			award.tap()
			XCTAssertTrue(app.alerts["Locked"].exists, "There should be a Locked alert showing for this award.")
			app.buttons["OK"].tap()
		}
	}
}
