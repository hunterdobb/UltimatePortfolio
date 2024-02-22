//
//  ContentViewModel.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 10/10/23.
//

import Foundation

extension ContentView {
	// See 'IssueRowViewModel' for explanation of '@dynamicMemberLookup' attribute
	@dynamicMemberLookup
	class ViewModel: ObservableObject {
		var dataController: DataController

		var shouldRequestReview: Bool {
			dataController.count(for: Tag.fetchRequest()) >= 5
		}

		var navTitle: String {
			dataController.selectedFilter?.name ?? "Issues"
		}

		init(dataController: DataController) {
			self.dataController = dataController
		}

		// See 'IssueRowViewModel' for explanation
		subscript<Value>(dynamicMember keyPath: KeyPath<DataController, Value>) -> Value {
			dataController[keyPath: keyPath]
		}

		subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<DataController, Value>) -> Value {
			get { dataController[keyPath: keyPath] }
			set { dataController[keyPath: keyPath] = newValue }
		}

		func delete(_ offsets: IndexSet) {
			let issues = dataController.issuesForSelectedFilter()

			for offset in offsets {
				let item = issues[offset]
				dataController.delete(item)
			}
		}

		func newIssue() {
			dataController.newIssue()
		}
	}
}
