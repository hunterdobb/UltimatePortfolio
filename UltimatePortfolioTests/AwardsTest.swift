//
//  AwardsTest.swift
//  UltimatePortfolioTests
//
//  Created by Hunter Dobbelmann on 7/10/23.
//

import CoreData
import XCTest
@testable import UltimatePortfolio

final class AwardsTest: BaseTestCase {
	let awards = Award.allAwards

	func testAwardIDMatchesName() {
		for award in awards {
			XCTAssertEqual(
				award.id, award.name,
				"The award ID should be the same as its name."
			)
		}
	}

	func testNewUserHasEarnedNoAwards() {
		for award in awards {
			XCTAssertFalse(
				dataController.hasEarned(award: award),
				"New users should have no earned awards."
			)
		}
	}

	func testCreatingIssuesEarnsAwards() {
		let values = [1, 10, 20, 50, 100, 250, 500, 1_000]

		for (count, value) in values.enumerated() {
			var issues = [Issue]()

			for _ in 0..<value {
				let issue = Issue(context: managedObjectContext)
				issues.append(issue)
			}

			let issueAwardsEarned = awards.filter { award in
				(award.criterion == "issues") && (dataController.hasEarned(award: award))
			}

			XCTAssertEqual(
				issueAwardsEarned.count, count + 1,
				"Creating \(value) issues should unlock \(count + 1) awards."
			)
			dataController.deleteAll()
		}
	}

	func testClosingIssuesEarnsAwards() {
		let values = [1, 10, 20, 50, 100, 250, 500, 1_000]

		for (count, value) in values.enumerated() {
			var issues = [Issue]()

			for _ in 0..<value {
				let issue = Issue(context: managedObjectContext)
				issue.completed = true
				issues.append(issue)
			}

			let issuesClosedAwardsEarned = awards.filter { award in
				(award.criterion == "closed") && (dataController.hasEarned(award: award))
			}

			XCTAssertEqual(
				issuesClosedAwardsEarned.count, count + 1,
				"Completing \(value) issues should unlock \(count + 1) awards."
			)
			dataController.deleteAll()
		}
	}
}
