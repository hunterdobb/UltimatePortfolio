//
//  DataController.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import CoreData

class DataController: ObservableObject {
	let container: NSPersistentCloudKitContainer

	// These are used for list selection
	@Published var selectedFilter: Filter? = .all
	@Published var selectedIssue: Issue?

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

		// Automatically apply to our viewContext (memory) any changes that happen to the
		// persistent store (SQLite database on disk). This is so these two stay in sync automatically.
		container.viewContext.automaticallyMergesChangesFromParent = true
		// How to handle merging local and remote data
		// NSMergePolicy.mergeByPropertyObjectTrump => In-memory changes take precedence over remote changes
		container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump


		// When working across multiple devices, to ensure our syncing works properly, we want to be notified
		// when any writes to our persistent store happen, so we can update our UI.
		// For example, if CloudKit makes a change to our data, we want to be told about that so
		// we can update our UI. To do this, we us the two lines below
		// 1.
		// Tell our main persistent store about any writes to the store (disk) happens
		// Make an announcement when changes happen
		container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
															   forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
		// 2.
		// * Watch for the announcement we setup above and call our method remoteStoreChanged(_: Notification)
		// * 'object: Any?' parameter is where the change will happen
		NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange,
											   object: container.persistentStoreCoordinator,
											   queue: .main,
											   using: remoteStoreChanged)

		// loads our data model, if it's not there already, so it's ready for us to query and work with
		container.loadPersistentStores { storeDescription, error in
			if let error {
				fatalError("Fatal error loading store: \(error.localizedDescription)")
			}
		}
	}


	func remoteStoreChanged(_ notification: Notification) {
		// Announce a change so our SwiftUI views will reload
		objectWillChange.send()
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
				issue.title = "Issue \(i)-\(j)"
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
		objectWillChange.send()
		container.viewContext.delete(object)
		save()
	}

	// Delete using a fetch request:	1. Find all issues or tags or whatever object
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

	func missingTags(from issue: Issue) -> [Tag] {
		let request = Tag.fetchRequest()
		let allTags = (try? container.viewContext.fetch(request)) ?? []

		let allTagsSet = Set(allTags)
		// Get the tags that are not a part of the issues tags
		let difference = allTagsSet.symmetricDifference(issue.issueTags)

		return difference.sorted()
	}
}
