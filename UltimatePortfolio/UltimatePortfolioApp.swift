//
//  UltimatePortfolioApp.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import SwiftUI

@main
struct UltimatePortfolioApp: App {
	/*
	 - We are using @State as opposed to @StateObject because we want this App struct to create and own this
	 DataController, but we don't have a point for it at this time to say observe it for changes as well.

	 - @State says create it and hold it, @StateObject will reload the entire App struct every time it changes the
	 dataController, which is not necessary at this time

	 @State = make it, hold it, don't keep it alive
	 */
	@State var dataController = DataController()

    var body: some Scene {
        WindowGroup {
			NavigationSplitView {
				SidebarView()
			} content: {
				ContentView()
			} detail: {
				DetailView()
			}
			// Inject the viewContext from the dataController into the SwiftUI environment
			// This is because every time SwiftUI wants to make a query with Core Data, it has to know
			// where to look for the data.
			.environment(\.managedObjectContext, dataController.container.viewContext)
			// Inject the entire dataController into the environment as-well.
			.environmentObject(dataController)
        }
    }
}
