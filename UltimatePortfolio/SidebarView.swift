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

	// Convert Tag type from fetch request to Filter type to show in list
	var tagFilters: [Filter] {
		tags.map { tag in
			Filter(id: tag.id ?? UUID(), name: tag.name ?? "No name", icon: "tag", tag: tag)
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
					}
				}
			}
		}
		.toolbar {
			Button {
				dataController.deleteAll()
				dataController.createSampleData()
			} label: {
				Label("ADD SAMPLES", systemImage: "flame")
			}
		}
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
			.environmentObject(DataController.preview)
    }
}
