//
//  IssueView.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/24/23.
//

import SwiftUI

/// A view that displays a single issue for editing
///
/// This view is initialized in ``DetailView``.
struct IssueView: View {
	@EnvironmentObject var dataController: DataController
	@ObservedObject var issue: Issue

    var body: some View {
		Form {
			Section {
				VStack(alignment: .leading) {
					TextField("Title", text: $issue.issueTitle, prompt: Text("Enter the issue title here"))
						.font(.title)

					Text("**Modified:** \(issue.issueModificationDate.formatted(date: .long, time: .shortened))")
						.foregroundStyle(.secondary)

					Text("**Status:** \(issue.issueStatus)")
						.foregroundStyle(.secondary)
				}

				Picker("Priority", selection: $issue.priority) {
					Text("Low").tag(Int16(0))
					Text("Medium").tag(Int16(1))
					Text("High").tag(Int16(2))
				}

				TagsMenuView(issue: issue)
				
			}

			Section {
				VStack(alignment: .leading) {
					Text("Basic Information")
						.font(.title2)
						.foregroundStyle(.secondary)

					TextField("Description", text: $issue.issueContent, prompt: Text("Enter the issue description here"), axis: .vertical)
				}
			}
		}
		.disabled(issue.isDeleted)
		// • The reason we don't use '.onChange(of: issue)' is because it won't fire.
		// 		This is because the actual 'issue' instance is not changing, only the
		// 		values within 'issue' are changing.
		// • Using '.onReceive(of: issue)' watches for the issue to announce changes
		// 		using @Published
		// Our Issue object conforms to 'ObservableObject' automatically from Core Data
		// because 'NSManagedObject' subclasses 'ObservableObject'
		.onReceive(issue.objectWillChange) { _ in
			dataController.queueSave()
		}
		// Immediately save when the user submits a TextField instead of waiting for the queueSave
		.onSubmit(dataController.save)
		.toolbar { IssueViewToolbar(issue: issue) }
    }
}

struct IssueView_Previews: PreviewProvider {
    static var previews: some View {
		IssueView(issue: .example)
			.environmentObject(DataController.preview)
    }
}
