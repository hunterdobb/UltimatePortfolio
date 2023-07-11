//
//  AssetTests.swift
//  UltimatePortfolioTests
//
//  Created by Hunter Dobbelmann on 6/17/23.
//

import XCTest
@testable import UltimatePortfolio

final class AssetTests: XCTestCase {
	func testColorsExist() {
		let allColors = [
			"App Dark Blue", "App Dark Gray", "App Gold", "App Gray", "App Green", "App Light Blue",
			"App Midnight", "App Orange", "App Pink", "App Purple", "App Red", "App Teal"
		]

		for color in allColors {
			XCTAssertNotNil(UIColor(named: color), "Failed to load color '\(color)' from asset catalog.")
		}
	}

	func testAwardsLoadCorrectly() {
		XCTAssertTrue(Award.allAwards.isEmpty == false, "Failed to load awards from JSON.")
	}
}
