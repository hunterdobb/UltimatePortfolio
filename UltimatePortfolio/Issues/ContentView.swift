//
//  ContentView.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import SwiftUI

struct ContentView: View {
	@Environment(\.requestReview) var requestReview
	@StateObject var viewModel: ViewModel

	private let newIssueActivity = "com.hunterdobbapps.UltimatePortfolio.newIssue"

    var body: some View {
		List(selection: $viewModel.selectedIssue) {
			ForEach(viewModel.dataController.issuesForSelectedFilter()) { issue in
				IssueRow(issue: issue)
			}
			.onDelete(perform: viewModel.delete)
		}
//		#if !os(macOS) // I added this
//		.listStyle(.insetGrouped)
//		#endif
		.navigationTitle(viewModel.navTitle)
		.searchable(
			text: $viewModel.filterText,
			tokens: $viewModel.filterTokens,
			suggestedTokens: .constant(viewModel.suggestedFilterTokens),
			prompt: "Filter issues, or type # to add tags"
		) { tag in
			Text(tag.tagName)
		}
		.toolbar(content: ContentViewToolbar.init)
//		.onAppear(perform: askForReview)
		.onOpenURL(perform: openURL)
		.userActivity(newIssueActivity) { activity in
			activity.isEligibleForPrediction = true
			activity.title = "New Issue"
		}
		.onContinueUserActivity(newIssueActivity, perform: resumeActivity)
	}

	init(dataController: DataController) {
		let viewModel = ViewModel(dataController: dataController)
		_viewModel = StateObject(wrappedValue: viewModel)
	}

	func askForReview() {
		if viewModel.shouldRequestReview {
			requestReview()
		}
	}

	func openURL(_ url: URL) {
		if url.absoluteString.contains("newIssue") {
			viewModel.newIssue()
		}
	}

	func resumeActivity(_ userActivity: NSUserActivity) {
		viewModel.newIssue()
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView(dataController: .preview)
//			.environmentObject(DataController.preview)
    }
}
