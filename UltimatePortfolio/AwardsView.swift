//
//  AwardsView.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 4/9/23.
//

import SwiftUI

struct AwardsView: View {
	@EnvironmentObject var dataController: DataController

	// 'Award.example' is used as a place holder, so we don't have an optional Award type.
	// It will be set before it's used, so this is okay.
	@State private var selectedAward = Award.example
	@State private var showingAwardDetails = false

	var columns: [GridItem] {
		[GridItem(.adaptive(minimum: 100, maximum: 100))]
	}

    var body: some View {
		NavigationStack {
			ScrollView {
				LazyVGrid(columns: columns) {
					ForEach(Award.allAwards) { award in
						Button {
							selectedAward = award
							showingAwardDetails = true
						} label: {
							Image(systemName: award.image)
								.resizable()
								.scaledToFit()
								.padding()
								.frame(width: 100, height: 100)
								.foregroundColor(color(for: award))
						}
						.accessibilityLabel(label(for: award))
						.accessibilityHint(award.description)
					}
				}
			}
			.navigationTitle("Awards")
		}
		.alert(awardsTitle, isPresented: $showingAwardDetails) {
		} message: { Text(selectedAward.description) }
    }

	var awardsTitle: String {
		if dataController.hasEarned(award: selectedAward) {
			return "Unlocked: \(selectedAward.name)"
		} else {
			return "Locked"
		}
	}

	func color(for award: Award) -> Color {
		dataController.hasEarned(award: award) ? Color(award.color) : .secondary.opacity(0.5)
	}

	func label(for award: Award) -> LocalizedStringKey {
		dataController.hasEarned(award: award) ? "Unlocked: \(award.name)" : "Locked"
	}
}

struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView()
			.environmentObject(DataController.preview)
    }
}
