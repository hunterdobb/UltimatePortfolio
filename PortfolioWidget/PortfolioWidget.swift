//
//  PortfolioWidget.swift
//  PortfolioWidget
//
//  Created by Hunter Dobbelmann on 3/30/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(date: .now, issue: [.example])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
		let entry = SimpleEntry(date: .now, issue: loadIssues())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
		let entry = SimpleEntry(date: .now, issue: loadIssues())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

	func loadIssues() -> [Issue] {
		let dataController = DataController()
		let request = dataController.fetchRequestForTopIssues(count: 1)
		return dataController.results(for: request)
	}
}

struct SimpleEntry: TimelineEntry {
    let date: Date
	let issue: [Issue]
}

struct PortfolioWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
		VStack(alignment: .leading) {
			Text("\(Image(systemName: "exclamationmark.circle")) Issues")
				.font(.headline)

			Spacer()

			Text("Up Next...")
				.font(.title2)
				.bold()

			if let issue = entry.issue.first {
				Text(issue.issueTitle)
			} else {
				Text("Nothing!")
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PortfolioWidget: Widget {
    let kind: String = "PortfolioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                PortfolioWidgetEntryView(entry: entry)
					.containerBackground(.blue.gradient.opacity(0.6), for: .widget)
            } else {
                PortfolioWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview("Small", as: .systemSmall) {
	PortfolioWidget()
} timeline: {
	SimpleEntry(date: .now, issue: [.example])
	SimpleEntry(date: .now, issue: [.example])
}

#Preview("Medium", as: .systemMedium) {
    PortfolioWidget()
} timeline: {
	SimpleEntry(date: .now, issue: [.example])
	SimpleEntry(date: .now, issue: [.example])
}
