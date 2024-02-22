//
//  IssueRow.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/24/23.
//

import SwiftUI

struct IssueRow: View {
	// We're watching this for announcement of changes coming in, usually remote changes from iCloud
	@EnvironmentObject var dataController: DataController
	// We're watching this for local changes to our issue happening right now
//	@ObservedObject var issue: Issue
	@StateObject var viewModel: ViewModel

    var body: some View {
		NavigationLink(value: viewModel.issue) {
			HStack {
				Image(systemName: "exclamationmark.circle")
					.imageScale(.large)
					.opacity(viewModel.priorityIconOpacity)
					.accessibilityIdentifier(viewModel.priorityIconIdentifier)

				VStack(alignment: .leading) {
					HStack(alignment: .firstTextBaseline) {
						Text(viewModel.issueTitle)
							.font(.headline)
							.lineLimit(1)

						if viewModel.reminderEnabled {
							Image(systemName: "bell")
						}
					}

					Text(viewModel.issueTagsList)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}

				Spacer()

				VStack(alignment: .trailing) {
					Text(viewModel.creationDate)
						.accessibilityLabel(viewModel.accessibilityCreationDate)
						.font(.subheadline)

					if viewModel.completed {
						Text("CLOSED")
							.font(.body.smallCaps())
					}
				}
				.foregroundStyle(.secondary)
			}
		}
		.accessibilityHint(viewModel.accessibilityHint)
		.accessibilityIdentifier(viewModel.issueTitle)
    }

	init(issue: Issue) {
		let viewModel = ViewModel(issue: issue)
		_viewModel = StateObject(wrappedValue: viewModel)
	}
}

struct IssueRow_Previews: PreviewProvider {
    static var previews: some View {
		IssueRow(issue: .example)
			.environmentObject(DataController.preview)
    }
}
