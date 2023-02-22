//
//  DataController.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import CoreData

class DataController: ObservableObject {
	let container: NSPersistentCloudKitContainer

	@Published var selectedFilter: Filter? = Filter.all

	static var preview: DataController = {
		let dataController = DataController(inMemory: true)
		dataController.createSampleData()
		return dataController
	}()

	init(inMemory: Bool = false) {
		container = NSPersistentCloudKitContainer(name: "Main")

		if inMemory {
			container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
		}

		// loads our data model, if it's not there already, so it's ready for us to query and work with
		container.loadPersistentStores { storeDescription, error in
			if let error {
				fatalError("Fatal error loading store: \(error.localizedDescription)")
			}
		}
	}

	// Sample data
	func createSampleData() {
		// viewContext is the "pool of data" that has been loaded from disk. It's whats live right now
		// We've already loaded and created our persistent storage (the database on disk) exists in long-term storage
		//
		// viewContext holds active objects in memory, only writes them back to persistent storage when we do .save()
		let viewContext = container.viewContext

		for i in 1...5 {
			let tag = Tag(context: viewContext)
			tag.id = UUID()
			tag.name = "Tag \(i)"

			for j in 1...10 {
				let issue = Issue(context: viewContext)
				issue.title = "Issue \(j)"
				issue.content = "Description goes here"
				issue.creationDate = .now
				issue.completed = Bool.random()
				issue.priority = Int16.random(in: 0...2)
				tag.addToIssues(issue)
			}
		}

		try? viewContext.save()
	}

	func save() {
		if container.viewContext.hasChanges {
			try? container.viewContext.save()
		}
	}

	func delete(_ object: NSManagedObject) {
		container.viewContext.delete(object)
		save()
	}
	//									1. Find all issues or tags or whatever object
	private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
		// 2. Convert that to be a batch delete for that thing (issue, tag, etc.)
		let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
		// 3. When the things are deleted, send back an array of the unique identifiers for the things that got deleted
		batchDeleteRequest.resultType = .resultTypeObjectIDs

		// 4. Execute the request here
		if let delete = try? container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
			// 5. put the array of id's to be deleted into dictionary of type [NSDeletedObjectsKey : [NSManagedObjectID]]
			// Note: 'delete.result' is of type 'Any?' but we know it will be of type '[NSManagedObjectID]'
			// 		because in step 3 we set 'batchDeleteRequest.resultType = .resultTypeObjectIDs'
			//		(This is just an old api so it's not very modern.)
			let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
			// 6. Merge the array of changes into our live viewContext, so our live viewContext matches
			// the changes we made in the persistent store
			NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
		}
	}

	func deleteAll() {
		let tagsRequest: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
		delete(tagsRequest)

		let issuesRequest: NSFetchRequest<NSFetchRequestResult> = Issue.fetchRequest()
		delete(issuesRequest)

		save()
	}
}
