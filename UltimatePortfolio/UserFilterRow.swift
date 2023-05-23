//
//  UserFilterRow.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 5/23/23.
//

import SwiftUI

struct UserFilterRow: View {
	var filter: Filter
	var rename: (Filter) -> Void
	var delete: (Filter) -> Void

    var body: some View {
		NavigationLink(value: filter) {
			Label(filter.name, systemImage: filter.icon)
				.badge(filter.activeIssuesCount)
				.contextMenu {
					Button { rename(filter) } label: {
						Label("Rename", systemImage: "pencil")
					}

					Button(role: .destructive) {
						delete(filter)
					} label: {
						Label("Delete", systemImage: "trash")
					}
				}
				.accessibilityElement() // creates a new element (replaces existing) for us to edit
				.accessibilityLabel(filter.name)
			// "^[\(filter.activeIssuesCount) issue](inflect: true)" adds automatic inflection
			// However, it doesn't play nice with localization in most languages.
				.accessibilityHint("\(filter.activeIssuesCount) issues")
		}
    }
}

struct UserFilterRow_Previews: PreviewProvider {
    static var previews: some View {
		UserFilterRow(filter: .all, rename: { _ in }, delete: { _ in })
    }
}
