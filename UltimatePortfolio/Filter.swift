//
//  Filter.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import Foundation

// Conforms to Hashable so we can select it inside a list
struct Filter: Identifiable, Hashable {
	var id: UUID
	var name: String
	var icon: String
	var minModificationDate = Date.distantPast
	var tag: Tag?

	/// Returns the total number of issues for the current tag.
	var activeIssuesCount: Int {
		tag?.tagActiveIssues.count ?? 0
	}

	static var all = Filter(id: UUID(), name: "All Issues", icon: "tray")
	// (86_400 * -7) => 7 days ago
	static var recent = Filter(id: UUID(), name: "Recent Issues", icon: "clock", minModificationDate: .now.addingTimeInterval(86_400 * -7))

	func hash(into hasher: inout Hasher) {
		// When we calculate the hash value of this Filter struct, only calculate the id's hash,
		// not all the other types too. This prevents bugs
		hasher.combine(id)
	}

	// Only compare the equality of the id's when checking if two Filter objects are equal
	static func ==(lhs: Filter, rhs: Filter) -> Bool {
		lhs.id == rhs.id
	}
}
