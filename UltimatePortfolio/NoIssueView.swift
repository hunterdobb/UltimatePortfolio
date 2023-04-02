//
//  NoIssueView.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/24/23.
//

import SwiftUI

struct NoIssueView: View {
	@EnvironmentObject var dataController: DataController

    var body: some View {
        Text("No Issue Selected")
			.font(.title)
			.foregroundStyle(.secondary)

		Button("New Issue", action: dataController.newIssue)
    }
}

struct NoIssueView_Previews: PreviewProvider {
    static var previews: some View {
        NoIssueView()
			.environmentObject(DataController.preview)
    }
}
