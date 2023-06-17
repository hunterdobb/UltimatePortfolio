//
//  Issue-CoreDataHelpers.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import Foundation

extension Issue {
	var issueTitle: String {
		get { title ?? "" }
		set { title = newValue }
	}

	var issueContent: String {
		get { content ?? "" }
		set { content = newValue }
	}

	var issueCreationDate: Date {
		creationDate ?? .now
	}

	var issueModificationDate: Date {
		modificationDate ?? .now
	}

	// Core Data uses NSSet, here we are converting it to an array and sorting it
	// to make it easier to work with
	var issueTags: [Tag] {
		let result = tags?.allObjects as? [Tag] ?? []
		return result.sorted()
	}

	var issueTagsList: String {
		guard let tags else { return "No tags" }

		if tags.count == 0 {
			return "No tags"
		} else {
			return issueTags.map(\.tagName).formatted()
		}
	}

	var issueStatus: String {
		if completed {
			return "Closed"
		} else {
			return "Open"
		}
	}

	// Added here to help with localization
	var issueFormattedCreationDate: String {
		issueCreationDate.formatted(date: .numeric, time: .omitted)
	}

	static var example: Issue {
		let controller = DataController(inMemory: true)
		let viewContext = controller.container.viewContext

		let issue = Issue(context: viewContext)
		issue.title = "Example Issue"
		issue.content = "This is an example issue for previewing purposes"
		issue.priority = 2
		issue.creationDate = .now
		return issue
	}
}

extension Issue: Comparable {
	// Used for sorting issues
	public static func < (lhs: Issue, rhs: Issue) -> Bool {
		let left = lhs.issueTitle.localizedLowercase
		let right = rhs.issueTitle.localizedLowercase

		if left == right {
			// If names are the same, sort by creation date
			return lhs.issueCreationDate < rhs.issueCreationDate
		} else {
			return left < right
		}
	}
}
