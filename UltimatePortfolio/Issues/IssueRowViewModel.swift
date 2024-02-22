//
//  IssueRowViewModel.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 10/10/23.
//

import Foundation

extension IssueRow {
	// This attribute along with the subscript below, tells Swift that all properties in issue can be
	// made to look like they exist on the viewModel (they don't actually.)
	@dynamicMemberLookup
	class ViewModel: ObservableObject {
		let issue: Issue

		var priorityIconOpacity: Double {
			(issue.priority == 2) ? 1 : 0
		}

		var priorityIconIdentifier: String {
			issue.priority == 2 ? "\(issue.issueTitle) High Priority" : ""
		}

		var accessibilityHint: String {
			issue.priority == 2 ? "High priority" : ""
		}

		var accessibilityCreationDate: String {
			issue.issueCreationDate.formatted(date: .abbreviated, time: .omitted)
		}

		// Added here to help with localization
		var creationDate: String {
			issue.issueCreationDate.formatted(date: .numeric, time: .omitted)
		}

		init(issue: Issue) {
			self.issue = issue
		}

		// Allows us to access properties from the internal issue directly on the viewModel
		// For example, in our view 'viewModel.issue.issueTitle' becomes 'viewModel.issueTitle'
		subscript<Value>(dynamicMember keyPath: KeyPath<Issue, Value>) -> Value {
			// This finds what we're looking for on the issue and sends its value back
			issue[keyPath: keyPath]
		}
	}
}
