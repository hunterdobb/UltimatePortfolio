//
//  DataController-StoreKit.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 12/18/23.
//

import Foundation
import StoreKit

extension DataController {
	/// The product ID for our premium unlock.
	static let unlockPremiumProductID = "com.hunterdobbapps.UltimatePortfolio.premiumUnlock"
	static let testProductID = "com.hunterdobbapps.UltimatePortfolio.testProduct"

	/// Loads and saves wether our premium unlock has been purchased
	var fullVersionUnlocked: Bool {
		get {
			defaults.bool(forKey: "fullVersionUnlocked")
		}

		set {
			defaults.set(newValue, forKey: "fullVersionUnlocked")
		}
	}

	/// Tracks and finalizes users currentEntitlements
	/// Should automatically handle restoring purchases
	func monitorTransaction() async {
		// Check for previous purchases
		for await entitlement in Transaction.currentEntitlements {
			// Same as saying 'if case .verified(let transaction) = entitlement {}'
			// It's reading an enum case and reading the value 'transaction' out of it
			// The 'if case let' syntax that Swift uses allows us to read a value inside an enum case
			if case let .verified(transaction) = entitlement {
				await finalize(transaction)
			}
		}

		// Watch for future transactions coming in.
		for await update in Transaction.updates {
			if let transaction = try? update.payloadValue {
				await finalize(transaction)
			}
		}
	}

	func purchase(_ product: Product) async throws {
		let result = try await product.purchase()

		if case .success(let verificationResult) = result {
			try await finalize(verificationResult.payloadValue)
		}
	}

	@MainActor
	func finalize(_ transaction: Transaction) async {
		if transaction.productID == Self.unlockPremiumProductID {
			objectWillChange.send()
			// Ensure the transaction wasn't refunded or revoked from Family Sharing.
			fullVersionUnlocked = (transaction.revocationDate == nil)
			await transaction.finish()
		}
	}

	@MainActor
	func loadProducts() async throws {
		guard products.isEmpty else { return }

		try await Task.sleep(for: .seconds(0.2))
		products = try await Product.products(
			for: [
				Self.unlockPremiumProductID
//				Self.testProductID
			]
		)
	}
}
