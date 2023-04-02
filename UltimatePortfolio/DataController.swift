//
//  DataController.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import CoreData

enum SortType: String {
	// the rawValue strings are the attribute names from Core Data
	case dateCreated = "creationDate"
	case dateModified = "modificationDate"
}

enum Status {
	case all, open, closed
}

class DataController: ObservableObject {
	let container: NSPersistentCloudKitContainer

	// These are used for list selection
	@Published var selectedFilter: Filter? = .all
	@Published var selectedIssue: Issue?

	@Published var filterText = ""
	@Published var filterTokens = [Tag]()

	@Published var filterEnabled = false
	@Published var filterPriority = -1 // 0 low, 1 medium, 2 high, -1 any
	@Published var filterStatus = Status.all // open, closed, all
	@Published var sortType = SortType.dateCreated
	@Published var sortNewestFirst = true

	// We define this here so we can cancel it if another change is made.
	// We use it in the 'queueSave()' function below
	private var saveTask: Task<Void, Error>?

	static var preview: DataController = {
		let dataController = DataController(inMemory: true)
		dataController.createSampleData()
		return dataController
	}()

	/// Used for filtering tags based on tokens. To filter by tags the user types a '#' then the tag they want to filter by
	var suggestedFilterTokens: [Tag] {
		guard filterText.starts(with: "#") else {
			return []
		}

		let trimmedFilterText = String(filterText.dropFirst()).trimmingCharacters(in: .whitespaces)
		let request = Tag.fetchRequest()

		if trimmedFilterText.isEmpty == false {
			request.predicate = NSPredicate(format: "name CONTAINS[c] %@", trimmedFilterText)
		}

		return (try? container.viewContext.fetch(request).sorted()) ?? []
	}

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

	// Calling save on the viewContext saves the changes from memory into persistent storage
	func save() {
		if container.viewContext.hasChanges {
			try? container.viewContext.save()
			print("Saved!")
		}
	}

	/// Wait 3 seconds before saving when a change is made. Restart the 3 second
	/// delay if another change is made before 3 seconds is up.
	func queueSave() {
		saveTask?.cancel()
		// 'saveTask' is defined near top of class
		// '@MainActor' tells the Task it must run its body on the main actor (thread)
		// ^ this is so we keep out Core Data work on the main thread to be safer.
		saveTask = Task { @MainActor in
			// When this is canceled it throws an error. We don't need to handle it
			// because we're just using it to prevent 'save()' from being run too often
			print("Queuing save")
			try await Task.sleep(for: .seconds(3))
			save()
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

	/// Used when generating preview data
	func deleteAll() {
		let tagsRequest: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
		delete(tagsRequest)

		let issuesRequest: NSFetchRequest<NSFetchRequestResult> = Issue.fetchRequest()
		delete(issuesRequest)

		save()
	}

	/// Pass in an issue and get back an array of tags that don't belong to it. This is used for tag selection on a particular
	/// issue, so we can differentiate selected tags and non-selected tags.
	/// - Parameter issue: The issue we wish to get the missing tags for
	/// - Returns: An array of tags that are not a part of the issue passed in
	func missingTags(from issue: Issue) -> [Tag] {
		let request = Tag.fetchRequest()
		let allTags = (try? container.viewContext.fetch(request)) ?? []

		let allTagsSet = Set(allTags)
		// Get the tags that are not a part of the issues tags
		let difference = allTagsSet.symmetricDifference(issue.issueTags)

		return difference.sorted()
	}

	// (!) We moved this from ContentView to DataController, which is a safe place for any
	// Core Data code unless we have specific needs. (!)
	/// Gets the issues for the selected filter. If it's a tag use that, otherwise do a regular fetch request to fetch all objects
	func issuesForSelectedFilter() -> [Issue] {
		let filter = selectedFilter ?? .all
		var predicates = [NSPredicate]()

		if let tag = filter.tag {
			// If we have a tag attached to our filter, we filter on that
			// Does the tags relationship for our CD Issue object contain the tag chosen in the sidebar
			let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
			predicates.append(tagPredicate)
		} else {
			// If no tag is attached, we filter on the 'minModificationDate' either all or recent (past 7 days)
			let datePredicate = NSPredicate(format: "modificationDate > %@", filter.minModificationDate as NSDate)
			predicates.append(datePredicate)
		}

		let trimmedFilterText = filterText.trimmingCharacters(in: .whitespaces)

		if trimmedFilterText.isEmpty == false {
			// By default CONTAINS is case-sensitive, adding [c] makes it case-insensitive
			// Filters our Issue object based on the title and content properties
			let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", trimmedFilterText)
			let contentFilter = NSPredicate(format: "content CONTAINS[c] %@", trimmedFilterText)
			// We use 'orPredicateWithSubpredicates' so only one needs to be true to be included
			let combinedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentFilter])
			predicates.append(combinedPredicate)
		}

		if filterTokens.isEmpty == false {
			for filterToken in filterTokens {
				let tokenPredicate = NSPredicate(format: "tags CONTAINS %@", filterToken)
				predicates.append(tokenPredicate)
			}
		}

		// We only want to add the filter predicates if the user enables filtering in the menu
		if filterEnabled {
			// i.e. only check if filterPriority is not -1. Where -1 means include all priorities
			if filterPriority >= 0 {
				let priorityFilter = NSPredicate(format: "priority = %d", filterPriority)
				predicates.append(priorityFilter)
			}

			if filterStatus != .all {
				let lookForClosed = filterStatus == .closed
				// We use 'NSNumber(value: lookForClosed)' to convert true/false to 1/0 since that is how NSPredicate reads it
				let statusFilter = NSPredicate(format: "completed = %@", NSNumber(value: lookForClosed))
				predicates.append(statusFilter)
			}
		}

		// The '.fetchRequest()' func is auto generated in Issue+CoreDataProperties
		let request = Issue.fetchRequest()
		// NSCompoundPredicate is a subclass of NSPredicate, so we can assign it to 'request.predicate'
		// which is of type 'NSPredicate?'
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
		// 'sortType.rawValue' maps to our Core Data attributes ('creationDate' and 'modificationDate')
		// We are using 'sortNewestFirst' to determine newest first or oldest first
		// So we are saying to either sort using 'creationDate' or 'modificationDate' from Core Data
		request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue, ascending: sortNewestFirst)]

		// Run the fetch request and return it sorted
		let allIssues = (try? container.viewContext.fetch(request)) ?? []
		return allIssues.sorted()
	}

	func newTag() {
		let tag = Tag(context: container.viewContext)
		tag.id = UUID()
		tag.name = "New Tag"
		save()
	}

	func newIssue() {
		let issue = Issue(context: container.viewContext)
		issue.title = "New Issue"
		issue.creationDate = .now
		// priority is 0 by default, content is nil by default, completed is false by default,
		// modificationDate takes care of itself
		issue.priority = 1 // give new issues a medium priority

		// Add the new issue to the tag the user is viewing
		if let tag = selectedFilter?.tag {
			issue.addToTags(tag)
		}

		save()

		// Set selectedIssue to the new issue so the user can immediately edit
		selectedIssue = issue
	}
}
