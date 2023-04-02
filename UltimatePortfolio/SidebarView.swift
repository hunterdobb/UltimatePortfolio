//
//  SidebarView.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import SwiftUI

struct SidebarView: View {
	@EnvironmentObject var dataController: DataController
	let smartFilters: [Filter] = [.all, .recent]

	// Load all the tags sorting them by their name
	// Using the @FetchRequest property wrapper ensures SwiftUI updates the tag list automatically
	// as tags are added or removed
	@FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var tags: FetchedResults<Tag>

	// Used
	@State private var tagToRename: Tag?
	@State private var renamingTag = false
	@State private var tagName = ""

	// Convert Tag type from fetch request to Filter type to show in list
	var tagFilters: [Filter] {
		tags.map { tag in
			Filter(id: tag.tagID, name: tag.tagName, icon: "tag", tag: tag)
		}
	}

    var body: some View {
		List(selection: $dataController.selectedFilter) {
			Section("Smart Filters") {
				ForEach(smartFilters) { filter in
					NavigationLink(value: filter) {
						Label(filter.name, systemImage: filter.icon)
					}
				}
			}

			Section("Tags") {
				ForEach(tagFilters) { filter in
					NavigationLink(value: filter) {
						Label(filter.name, systemImage: filter.icon)
							.badge(filter.tag?.tagActiveIssues.count ?? 0)
							.contextMenu {
								Button {
									rename(filter)
								} label: {
									Label("Rename", systemImage: "pencil")
								}
							}
					}
				}
				.onDelete(perform: delete)
			}
		}
		.navigationTitle("Issues")
		.toolbar {
			Button(action: dataController.newTag) {
				Label("Add tag", systemImage: "plus")
			}

			#if DEBUG
			Button {
				dataController.deleteAll()
				dataController.createSampleData()
			} label: {
				Label("ADD SAMPLES", systemImage: "flame")
			}
			#endif
		}
		.alert("Rename tag", isPresented: $renamingTag) {
			Button("Ok", action: completeRename)
			Button("Cancel", role: .cancel) { }
			TextField("New name", text: $tagName)
		}
    }

	func delete(_ offsets: IndexSet) {
		for offset in offsets {
			let item = tags[offset]
			dataController.delete(item)
		}
	}

	func rename(_ filter: Filter) {
		tagToRename = filter.tag
		tagName = filter.name
		renamingTag = true
	}

	func completeRename() {
		tagToRename?.name = tagName
		dataController.save()
	}
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
			.environmentObject(DataController.preview)
    }
}
