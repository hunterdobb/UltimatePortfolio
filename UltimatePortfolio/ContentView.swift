//
//  ContentView.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var dataController: DataController

	// Get the issues for the selected filter
	// If it's tag use that, otherwise do a regular fetch request to fetch all objects
	var issues: [Issue] {
		let filter = dataController.selectedFilter ?? .all
		var allIssues: [Issue]

		if let tag = filter.tag {
			// '.allObjects' returns [Any], so we need to type case to [Issue]
			allIssues = tag.issues?.allObjects as? [Issue] ?? []
		} else {
			// The '.fetchRequest()' func is auto generated in Issue+CoreDataProperties
			let request = Issue.fetchRequest()
			// 'as NSDate' is needed because Core Data uses NSDate
			request.predicate = NSPredicate(format: "modificationDate > %@", filter.minModificationDate as NSDate)
			allIssues = (try? dataController.container.viewContext.fetch(request)) ?? []
		}

		return allIssues.sorted()
	}

    var body: some View {
		List {
			ForEach(issues) { issue in
				IssueRow(issue: issue)
			}
			.onDelete(perform: delete)
		}
		.listStyle(.insetGrouped)
		.navigationTitle("Issues")
    }

	func delete(_ offsets: IndexSet) {
		for offset in offsets {
			let item = issues[offset]
			dataController.delete(item)
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
			.environmentObject(DataController())
    }
}
