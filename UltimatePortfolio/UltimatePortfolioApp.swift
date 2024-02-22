//
//  UltimatePortfolioApp.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import CoreSpotlight
import SwiftUI

@main
struct UltimatePortfolioApp: App {
	/*
	 - We are using @State as opposed to @StateObject because we want this App struct to create and own this
	 DataController, but we don't have a point for it at this time to say observe it for changes as well.

	 - @State says create it and hold it, @StateObject will reload the entire App struct every time it changes the
	 dataController, which is not necessary at this time

	 @State = make it, hold it, don't keep it alive

	 *** TOLD TO CHANGE IT TO @StateObject IN "Showing, deleting, and synchronizing issues" ***
	 */
	@StateObject var dataController = DataController()

	// Watch for the phase of my scene
	@Environment(\.scenePhase) var scenePhase

	// Allows SwiftUI to use things from UIKit that are not yet in SwiftUI
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
			NavigationSplitView {
				SidebarView(dataController: dataController)
			} content: {
				ContentView(dataController: dataController)
			} detail: {
				DetailView()
			}
			// Inject the viewContext from the dataController into the SwiftUI environment
			// This is because every time SwiftUI wants to make a query with Core Data, it has to know
			// where to look for the data.
			.environment(\.managedObjectContext, dataController.container.viewContext)
			.environmentObject(dataController)
			.onChange(of: scenePhase) { _, newValue in
				backgroundSave(newValue)
			}
			.onContinueUserActivity(CSSearchableItemActionType, perform: loadSpotlightItem)
        }
    }

	/// Load and open the issue initiated by spotlight
	func loadSpotlightItem(_ userActivity: NSUserActivity) {
		// Read out the string identifier that CoreSpotlight sent to us
		if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
			dataController.selectedIssue = dataController.issue(with: uniqueIdentifier)
			dataController.selectedFilter = .all
		}
	}

	/// Save the view context when scenePhase is '.inactive' or '.background' (i.e. app enters background)
	func backgroundSave(_ scenePhase: ScenePhase) {
		if scenePhase != .active {
			dataController.save()
		}
	}
}
