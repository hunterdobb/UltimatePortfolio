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
	@ObservedObject var issue: Issue

    var body: some View {
		NavigationLink(value: issue) {
			HStack {
				Image(systemName: "exclamationmark.circle")
					.imageScale(.large)
					.opacity((issue.priority == 2) ? 1 : 0)

				VStack(alignment: .leading) {
					Text(issue.issueTitle)
						.font(.headline)
						.lineLimit(1)

					Text("No tags")
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}

				Spacer()

				VStack(alignment: .trailing) {
					Text(issue.issueCreationDate.formatted(date: .numeric, time: .omitted))
						.font(.subheadline)

					if issue.completed {
						Text("CLOSED")
							.font(.body.smallCaps())
					}
				}
				.foregroundStyle(.secondary)
			}
		}
    }
}

struct IssueRow_Previews: PreviewProvider {
    static var previews: some View {
		IssueRow(issue: .example)
			.environmentObject(DataController())
    }
}
