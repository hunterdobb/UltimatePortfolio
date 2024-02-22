//
//  DataController-FilterAndSort.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 10/19/23.
//

import Foundation

extension DataController {
	/// Used for filtering tags based on tokens. To filter by tags the user types a '#' then the tag they want to filter by
	var suggestedFilterTokens: [Tag] {
		guard filterText.starts(with: "#") else {
			return []
		}

		let trimmedFilterText = String(filterText.dropFirst()).trimmingCharacters(in: .whitespaces)
		let request = Tag.fetchRequest()

		if trimmedFilterText.isEmpty == false {
			request.predicate = NSPredicate(format: "name CONTAINS[c] %@", trimmedFilterText)
		}

		return (try? container.viewContext.fetch(request).sorted()) ?? []
	}

	/// Runs a fetch request with various predicates that filter the user's issues based on
	/// tag, title, content text, search tokens, priority, and completion status.
	///
	/// ❗️ We moved this from ContentView to DataController, which is a safe place for any
	/// Core Data code unless we have specific needs.
	/// - Returns: An array of all matching issues.
	func issuesForSelectedFilter() -> [Issue] {
		let filter = selectedFilter ?? .all
		var predicates = [NSPredicate]()

		if let tag = filter.tag {
			// If we have a tag attached to our filter, we filter on that
			// Does the tags relationship for our CD Issue object contain the tag chosen in the sidebar
			let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
			predicates.append(tagPredicate)
		} else {
			// If no tag is attached, we filter on the 'minModificationDate' either all or recent (past 7 days)
			let datePredicate = NSPredicate(format: "modificationDate > %@", filter.minModificationDate as NSDate)
			predicates.append(datePredicate)
		}

		let trimmedFilterText = filterText.trimmingCharacters(in: .whitespaces)

		if trimmedFilterText.isEmpty == false {
			// By default CONTAINS is case-sensitive, adding [c] makes it case-insensitive
			// Filters our Issue object based on the title and content properties
			let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", trimmedFilterText)
			let contentFilter = NSPredicate(format: "content CONTAINS[c] %@", trimmedFilterText)

			// We use 'orPredicateWithSubpredicates' so only one needs to be true to be included
			let combinedPredicate = NSCompoundPredicate(
				orPredicateWithSubpredicates: [titlePredicate, contentFilter]
			)

			predicates.append(combinedPredicate)
		}

		if filterTokens.isEmpty == false {
			for filterToken in filterTokens {
				let tokenPredicate = NSPredicate(format: "tags CONTAINS %@", filterToken)
				predicates.append(tokenPredicate)
			}
		}

		// We only want to add the filter predicates if the user enables filtering in the menu
		if filterEnabled {
			// i.e. only check if filterPriority is not -1. Where -1 means include all priorities
			if filterPriority >= 0 {
				let priorityFilter = NSPredicate(format: "priority = %d", filterPriority)
				predicates.append(priorityFilter)
			}

			if filterStatus != .all {
				let lookForClosed = filterStatus == .closed
				// We use 'NSNumber(value: lookForClosed)' to convert true/false to 1/0 since that is how NSPredicate reads it
				let statusFilter = NSPredicate(format: "completed = %@", NSNumber(value: lookForClosed))
				predicates.append(statusFilter)
			}
		}

		// The '.fetchRequest()' func is auto generated in Issue+CoreDataProperties
		let request = Issue.fetchRequest()
		// NSCompoundPredicate is a subclass of NSPredicate, so we can assign it to 'request.predicate'
		// which is of type 'NSPredicate?'
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
		// 'sortType.rawValue' maps to our Core Data attributes ('creationDate' and 'modificationDate')
		// We are using 'sortNewestFirst' to determine newest first or oldest first
		// So we are saying to either sort using 'creationDate' or 'modificationDate' from Core Data
		// I had to invert the value of sortNewestFirst to get it to sort correctly.
		request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue, ascending: !sortNewestFirst)]

		// Run the fetch request and return it. (We don't need to say '.sorted()' because we set the sortDescriptors above)
		let allIssues = (try? container.viewContext.fetch(request)) ?? []
//		return allIssues

		// I added this so results that ordered base on where the filter text appears in the title.
		return allIssues.sorted {
			guard let range1 = $0.issueTitle.range(of: filterText, options: [.caseInsensitive, .diacriticInsensitive, .numeric]),
				  let range2 = $1.issueTitle.range(of: filterText, options: [.caseInsensitive, .diacriticInsensitive, .numeric])
			else {
				return false
			}

			return range1.lowerBound < range2.lowerBound
		}
	}
}
