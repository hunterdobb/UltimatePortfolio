//
//  TagTests.swift
//  UltimatePortfolioTests
//
//  Created by Hunter Dobbelmann on 7/10/23.
//

import CoreData
import XCTest
@testable import UltimatePortfolio

// We subclass 'BaseTestCase' here to gain the initial setup
// 'BaseTestCase' is defined in 'UltimatePortfolioTests.swift'
final class TagTests: BaseTestCase {
	func testCreatingTagsAndIssues() {
		let targetCount = 10

		for _ in 0..<targetCount {
			let tag = Tag(context: managedObjectContext)

			for _ in 0..<targetCount {
				let issue = Issue(context: managedObjectContext)
				tag.addToIssues(issue)
			}
		}

		XCTAssertEqual(
			dataController.count(for: Tag.fetchRequest()), targetCount,
			"There should be \(targetCount) tags."
		)
		XCTAssertEqual(
			dataController.count(for: Issue.fetchRequest()), targetCount * targetCount,
			"There should be \(targetCount * targetCount) issues."
		)
	}

	// Ensure Delete rule is set to nullify
	func testDeletingTagDoesNotDeleteIssues() throws {
		dataController.createSampleData() // makes 5 tags with 10 issues each

//		let request = Tag.fetchRequest() //NSFetchRequest<Tag>(entityName: "Tag")
		let tags = try managedObjectContext.fetch(Tag.fetchRequest())
		dataController.delete(tags[0])

		XCTAssertEqual(
			dataController.count(for: Tag.fetchRequest()), 4,
			"There should be 4 tags after deleting 1 from our sample data."
		)
		XCTAssertEqual(
			dataController.count(for: Issue.fetchRequest()), 50,
			"There should still be 50 issues after deleting a tag from our sample data."
		)
	}
}
