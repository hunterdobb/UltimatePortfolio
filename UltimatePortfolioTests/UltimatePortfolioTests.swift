//
//  UltimatePortfolioTests.swift
//  UltimatePortfolioTests
//
//  Created by Hunter Dobbelmann on 6/17/23.
//

import CoreData
import XCTest

// Using @testable makes things that aren't marked public available for us to use.
// However, we still can't use things that are private.
@testable import UltimatePortfolio

// Creating this so we can make the Core Data setup here and subclass it when we need it later.
class BaseTestCase: XCTestCase {
	var dataController: DataController!
	var managedObjectContext: NSManagedObjectContext!

	override func setUpWithError() throws {
		dataController = DataController(inMemory: true)
		managedObjectContext = dataController.container.viewContext
	}
}
