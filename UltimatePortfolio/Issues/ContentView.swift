//
//  ContentView.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var dataController: DataController

    var body: some View {
		List(selection: $dataController.selectedIssue) {
			ForEach(dataController.issuesForSelectedFilter()) { issue in
				IssueRow(issue: issue)
			}
			.onDelete(perform: delete)
		}
		#if !os(macOS) // I added this
		.listStyle(.insetGrouped)
		#endif
		.navigationTitle("Issues")
		.toolbar(content: ContentViewToolbar.init)
		.searchable(
			text: $dataController.filterText,
			tokens: $dataController.filterTokens,
			suggestedTokens: .constant(dataController.suggestedFilterTokens),
			prompt: "Filter issues, or type # to add tags"
		) { tag in
			Text(tag.tagName)
		}
	}

	func delete(_ offsets: IndexSet) {
		let issues = dataController.issuesForSelectedFilter()

		for offset in offsets {
			let item = issues[offset]
			dataController.delete(item)
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
			.environmentObject(DataController.preview)
    }
}
