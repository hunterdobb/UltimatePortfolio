//
//  Award.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 4/9/23.
//

import Foundation

struct Award: Decodable, Identifiable {
	var id: String { name }
	let name: String
	let description: String
	let color: String
	let criterion: String
	let value: Int
	let image: String


	// static constants can access each other because they are created lazily.
	// For example, if Awards.example is called first, it will see it needs to create
	//   Awards.allAwards and do that first, then create example.
	static let allAwards: [Award] = Bundle.main.decode("Awards.json")
	static let example = allAwards.first!
}
