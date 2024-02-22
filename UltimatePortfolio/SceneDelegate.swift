//
//  SceneDelegate.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/24.
//

import SwiftUI

class SceneDelegate: NSObject, UIWindowSceneDelegate {
	// `performActionFor` only gets called when a scene is running, so if you use it 
	// while the app is closed, nothing will happen.
	func windowScene(
		_ windowScene: UIWindowScene,
		performActionFor shortcutItem: UIApplicationShortcutItem,
		completionHandler: @escaping (Bool) -> Void
	) {
		guard let url = URL(string: shortcutItem.type) else {
			completionHandler(false)
			return
		}

		windowScene.open(url, options: nil, completionHandler: completionHandler)
	}

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		if let shortcutItem = connectionOptions.shortcutItem {
			if let url = URL(string: shortcutItem.type) {
				scene.open(url, options: nil)
			}
		}
	}
}
