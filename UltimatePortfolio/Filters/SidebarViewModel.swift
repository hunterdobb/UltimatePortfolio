//
//  SidebarViewModel.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 9/23/23.
//

import CoreData
import Foundation

// Using extension here for name spacing
extension SidebarView {
	class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
		var dataController: DataController

		// CANNOT BE USED OUTSIDE OF SWIFTUI VIEW!
		// Therefore, in the init we implement NSFetchedResultsController which takes a bit more work
		// Load all the tags sorting them by their name
		// Using the @FetchRequest property wrapper ensures SwiftUI updates the tag list automatically
		// as tags are added or removed
//		@FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var tags: FetchedResults<Tag>

		// Fetches Tags
		private let tagsController: NSFetchedResultsController<Tag>
		@Published var tags = [Tag]()

		// Used for renaming a tag
		@Published var tagToRename: Tag?
		@Published var renamingTag = false
		@Published var tagName = ""

		// Convert Tag type from fetch request to Filter type to show in list
		var tagFilters: [Filter] {
			tags.map { tag in
				Filter(id: tag.tagID, name: tag.tagName, icon: "tag", tag: tag)
			}
		}

		init(dataController: DataController) {
			self.dataController = dataController

			let request = Tag.fetchRequest()
			request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]

			// Get the fetch request up and running
			tagsController = NSFetchedResultsController(
				fetchRequest: request,
				managedObjectContext: dataController.container.viewContext,
				sectionNameKeyPath: nil,
				cacheName: nil
			)

			// NSObject requirement
			super.init()

			tagsController.delegate = self

			do {
				try tagsController.performFetch()
				tags = tagsController.fetchedObjects ?? []
			} catch {
				print("Failed to fetch tags")
			}
		}

		func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
			if let newTags = controller.fetchedObjects as? [Tag] {
				print("Did change")
				tags = newTags
			}
		}

		// Used for swipe to delete
		func delete(_ offsets: IndexSet) {
			for offset in offsets {
				let item = tags[offset]
				dataController.delete(item)
			}
		}

		// Used for contextMenu delete
		func delete(_ filter: Filter) {
			guard let tag = filter.tag else { return }
			dataController.delete(tag)
			dataController.save()
		}

		func rename(_ filter: Filter) {
			tagToRename = filter.tag
			tagName = filter.name
			renamingTag = true
		}

		func completeRename() {
			tagToRename?.name = tagName
			try? tagsController.performFetch()
			tags = tagsController.fetchedObjects ?? []
			dataController.save()
		}
	}
}
