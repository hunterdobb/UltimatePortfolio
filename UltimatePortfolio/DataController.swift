//
//  DataController.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import CoreData
import StoreKit
import SwiftUI

enum SortType: String {
	// the rawValue strings are the attribute names from Core Data
	case dateCreated = "creationDate"
	case dateModified = "modificationDate"
}

enum Status {
	case all, open, closed
}

/// An environment singleton responsible for managing our Core Data stack, including handling saving,
/// counting fetch requests, tracking orders, and dealing with sample data.
class DataController: ObservableObject {
	/// The lone CloudKit container used to store all our data
	let container: NSPersistentCloudKitContainer

	var spotlightDelegate: NSCoreDataCoreSpotlightDelegate?

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
	private var storeTask: Task<Void, Never>?

	/// The UserDefaults suite where we're saving user data
	let defaults: UserDefaults

	/// The StoreKit products we've loaded for the store.
	@Published var products = [Product]()

	static var preview: DataController = {
		let dataController = DataController(inMemory: true)
		dataController.createSampleData()
		return dataController
	}()

	// We implemented this singleton to fix an error that randomly happens when running tests.
	// The problem before was our 'BaseTestCase' class created a new DataController and since we import UltimatePortfolio
	// with '@testable import UltimatePortfolio' our 'UltimatePortfolioApp: App' struct would be created also.
	// This means two DataControllers were being created and the system would sometimes get Issues and Tags confused
	// between the two controllers.
	// By creating the NSManagedObjectModel as a static member of our class, we can ensure it's only created once. We then
	// pass it in below when creating our NSPersistentCloudKitContainer.
	static private let model: NSManagedObjectModel = {
		guard let url = Bundle.main.url(forResource: "Main", withExtension: "momd") else {
			fatalError("Failed to locate model file.")
		}

		guard let managedObjectModel = NSManagedObjectModel(contentsOf: url) else {
			fatalError("Failed to load model file.")
		}

		return managedObjectModel
	}()

	/// Initializes a data controller, either in memory (for testing use such as previewing),
	/// or in permanent storage (for use in regular app runs.)
	///
	/// Defaults to permanent storage.
	/// - Parameter inMemory: Wether to store this data in temporary memory or not.
	/// - Parameter defaults: The UserDefaults suite where user data should be stored
	init(inMemory: Bool = false, defaults: UserDefaults = .standard) {
		self.defaults = defaults
		container = NSPersistentCloudKitContainer(name: "Main", managedObjectModel: Self.model)

		storeTask = Task {
			await monitorTransaction()
		}

		// For testing and previewing purposes, we create a temporary, in-memory database
		// by writing to /dev/null so our data is destroyed after the app finishes running
		if inMemory {
			container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
		}

		// Automatically apply to our viewContext (memory) any changes that happen to the
		// persistent store (SQLite database on disk). This is so these two stay in sync automatically.
		container.viewContext.automaticallyMergesChangesFromParent = true

		// How to handle merging local and remote data
		// NSMergePolicy.mergeByPropertyObjectTrump means in-memory changes take precedence over remote changes
		container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

		// When working across multiple devices, to ensure our syncing works properly, we want to be notified
		// when any writes to our persistent store happen, so we can update our UI.
		// For example, if CloudKit makes a change to our data, we want to be told about that so
		// we can update our UI. To do this, we us the two lines below
		// 1.
		// * Tell our main persistent store about any writes to the store (disk) happens
		// * Make an announcement when changes happen
		container.persistentStoreDescriptions.first?.setOption(
			true as NSNumber,
			forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
		)
		// 2.
		// * Watch for the announcement we setup above and call our method remoteStoreChanged(_: Notification)
		// * 'object: Any?' parameter is where the change will happen
		NotificationCenter.default.addObserver(
			forName: .NSPersistentStoreRemoteChange,
			object: container.persistentStoreCoordinator,
			queue: .main,
			using: remoteStoreChanged
		)

		// loads our data model, if it's not there already, so it's ready for us to query and work with
		container.loadPersistentStores { [weak self] _, error in
			if let error {
				fatalError("Fatal error loading store: \(error.localizedDescription)")
			}

			// Find description on disk
			if let description = self?.container.persistentStoreDescriptions.first {
				// Enable change tracking over time
				description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

				// Make our indexer (spotlightDelegate) attach to the data and the store behind the scenes
				// (Connects spotlight to Core Data)
				if let coordinator = self?.container.persistentStoreCoordinator {
					self?.spotlightDelegate = NSCoreDataCoreSpotlightDelegate(forStoreWith: description, coordinator: coordinator)
				}

				// Tell indexer to start working
				self?.spotlightDelegate?.startSpotlightIndexing()
			}

			#if DEBUG
			if CommandLine.arguments.contains("enable-testing") {
				self?.deleteAll()
				UIView.setAnimationsEnabled(false)
			}
			#endif
		}
	}

	func remoteStoreChanged(_ notification: Notification) {
		// Announce a change so our SwiftUI views will reload
		objectWillChange.send()
	}

	func createSampleData() {
		// viewContext is the "pool of data" that has been loaded from disk. It's whats live right now
		// We've already loaded and created our persistent storage (the database on disk) exists in long-term storage
		//
		// viewContext holds active objects in memory, only writes them back to persistent storage when we do .save()
		let viewContext = container.viewContext

		for tagCounter in 1...5 {
			let tag = Tag(context: viewContext)
			tag.id = UUID()
			tag.name = "Tag \(tagCounter)"

			for issueCounter in 1...10 {
				let issue = Issue(context: viewContext)
				issue.title = "Issue \(tagCounter)-\(issueCounter)"
				issue.content = "Description goes here"
				issue.creationDate = .now
				issue.completed = Bool.random()
				issue.priority = Int16.random(in: 0...2)
				tag.addToIssues(issue)
			}
		}

		try? viewContext.save()
	}

	/// Saves our Core Data context iff there are changes. This silently ignores
	/// any errors caused by saving, but this should be fine because all
	/// our attributes are optional.
	///
	/// Calling save on the viewContext saves the changes from memory into persistent storage
	func save() {
		// Clear any queued saves since we are about to save now
		saveTask?.cancel()

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
		// ^ this is so we keep our Core Data work on the main thread to be safer.
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

	/// Pass in an issue and get back an array of tags that don't belong to it. This is used for tag selection on a
	/// particular issue, so we can differentiate selected tags and non-selected tags.
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

	/// Creates a new blank tag.
	func newTag() -> Bool {
		var shouldCreate = fullVersionUnlocked

		if shouldCreate == false {
			shouldCreate = count(for: Tag.fetchRequest()) < 3
		}

		guard shouldCreate else { return false }

		let tag = Tag(context: container.viewContext)
		tag.id = UUID()
		tag.name = NSLocalizedString("New tag", comment: "Create a new tag")
		save()
		return true
	}

	/// Creates a new blank issue for the selected tag and give it a medium priority.
	func newIssue() {
		let issue = Issue(context: container.viewContext)
		issue.title = NSLocalizedString("New issue", comment: "Create a new issue")
		issue.creationDate = .now
		// priority is 0 by default, content is nil by default, completed is false by default,
		// modificationDate takes care of itself
		issue.priority = 1 // give new issues a medium priority

		// Add the new issue to the tag the user is viewing, if any
		if let tag = selectedFilter?.tag {
			issue.addToTags(tag)
		}

		save()

		// Set selectedIssue to the new issue so the user can immediately edit
		selectedIssue = issue
	}

	/// A helper method that returns the number of items in a fetch request.
	/// If the value is nil, we return 0.
	func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
		(try? container.viewContext.count(for: fetchRequest)) ?? 0
	}

	/// Determines if an award has been earned and returns true if it has, or false otherwise.
	func hasEarned(award: Award) -> Bool {
		switch award.criterion {
		case "issues":
			// return true if they added a certain number of issues
			let fetchRequest = Issue.fetchRequest()
			let awardCount = count(for: fetchRequest)
			return awardCount >= award.value

		case "closed":
			// return true if they closed a certain number of issues
			let fetchRequest = Issue.fetchRequest()
			fetchRequest.predicate = NSPredicate(format: "completed = true")
			let awardCount = count(for: fetchRequest)
			return awardCount >= award.value

		case "tags":
			// return true if they created a certain number of tags
			let fetchRequest = Tag.fetchRequest()
			let awardCount = count(for: fetchRequest)
			return awardCount >= award.value

		case "unlock":
			return fullVersionUnlocked

		default:
			// an unknown award criterion; this should never be allowed
			// fatalError("Unknown award criterion: \(award.criterion)")
			return false
		}
	}

	/// Used for finding an issue using its uniqueIdentifier
	///
	/// We use this for opening an issue from Spotlight
	func issue(with uniqueIdentifier: String) -> Issue? {
		guard let url = URL(string: uniqueIdentifier) else { return nil }

		guard let id = container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else {
			return nil
		}

		return try? container.viewContext.existingObject(with: id) as? Issue
	}
}
