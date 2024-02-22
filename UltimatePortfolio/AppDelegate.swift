//
//  AppDelegate.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 2/22/24.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(
		_ application: UIApplication,
		configurationForConnecting connectingSceneSession: UISceneSession,
		options: UIScene.ConnectionOptions
	) -> UISceneConfiguration {
		let sceneConfiguration = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
		sceneConfiguration.delegateClass = SceneDelegate.self
		return sceneConfiguration
	}
}
