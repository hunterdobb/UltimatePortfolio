//
//  DevelopmentTests.swift
//  UltimatePortfolioTests
//
//  Created by Hunter Dobbelmann on 7/20/23.
//

import CoreData
import XCTest
@testable import UltimatePortfolio

final class DevelopmentTests: BaseTestCase {
	func testSampleDataCreationWorks() {
		dataController.createSampleData()

		XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), 5, "There should be 5 sample tags.")
		XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), 50, "There should be 50 sample issues.")
	}

	// delete all works
	// -- new tag has 0 issues upon creation
	// -- new issue has high priority upon creation

	func testDeleteAllWorks() {
		dataController.createSampleData()
		dataController.deleteAll()

		XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), 0, "deleteAll() should leave 0 sample tags.")
		XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), 0, "deleteAll() should leave 0 sample issues.")
	}

	func testExampleTagHasNoIssues() {
		let tag = Tag.example

		XCTAssertEqual(tag.issues?.count, 0, "The example tag should have 0 issues")
	}

	func testNewIssueHasHighPriority() {
		let issue = Issue.example

		XCTAssertEqual(issue.priority, 2, "The example issue should start with a high priority.")
	}
}
