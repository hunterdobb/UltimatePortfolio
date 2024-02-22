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

	// Core Data uses NSSet, so we are converting it to an array and sorting it
	// to make it easier to work with
	var issueTags: [Tag] {
		let result = tags?.allObjects as? [Tag] ?? []
		return result.sorted()
	}

	var issueTagsList: String {
		let noTags = String(localized: "No tags", comment: "The user has not created any tags yet.")
		guard let tags else { return noTags }

		if tags.count == 0 {
			return noTags
		} else {
			return issueTags.map(\.tagName).formatted()
		}
	}

	var issueStatus: String {
		if completed {
			return String(localized: "Closed", comment: "This issue has been resolved by the user.")
		} else {
			return String(localized: "Open", comment: "This issue is currently unresolved by the user.")
		}
	}

	var issueReminderTime: Date {
		get { reminderTime ?? .now }
		set { reminderTime = newValue }
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
