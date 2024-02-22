//
//  DataController-Notifications.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 10/16/23.
//

import Foundation
import UserNotifications

extension DataController {
	func addReminders(for issue: Issue) async -> Bool {
		do {
			let center = UNUserNotificationCenter.current()
			let settings = await center.notificationSettings()

			switch settings.authorizationStatus {
			case .notDetermined:
				let success = try await requestNotifications()

				if success {
					try await placeReminders(for: issue)
				} else {
					return false
				}

			case .authorized:
				try await placeReminders(for: issue)

			default:
				return false
			}

			return true
		} catch {
			return false
		}
	}

	func removeReminders(for issue: Issue) {
		let center = UNUserNotificationCenter.current()
		let id = issue.objectID.uriRepresentation().absoluteString
		center.removePendingNotificationRequests(withIdentifiers: [id])
	}

	private func requestNotifications() async throws -> Bool {
		let center = UNUserNotificationCenter.current()
		return try await center.requestAuthorization(options: [.alert, .sound])
	}

	private func placeReminders(for issue: Issue) async throws {
		let content = UNMutableNotificationContent()
		content.title = issue.issueTitle
		content.sound = .default

		if let issueContent = issue.content {
			content.subtitle = issueContent
		}

		let components = Calendar.current.dateComponents([.hour, .minute], from: issue.issueReminderTime)
		let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
		// Used for testing
//		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

		let id = issue.objectID.uriRepresentation().absoluteString
		let request = UNNotificationRequest(
			identifier: id,
			content: content,
			trigger: trigger
		)

		return try await UNUserNotificationCenter.current().add(request)
	}
}
