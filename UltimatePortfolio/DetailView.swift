//
//  DetailView.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/23.
//

import SwiftUI

struct DetailView: View {
	@EnvironmentObject var dataController: DataController

    var body: some View {
		VStack {
			if let issue = dataController.selectedIssue {
				IssueView(issue: issue)
			} else {
				NoIssueView()
			}
		}
		.navigationTitle("Details")
		#if !os(macOS) // I added this
		.navigationBarTitleDisplayMode(.inline)
		#endif
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView()
			.environmentObject(DataController(inMemory: true))
    }
}
