//
//  Bundle-Decodable.swift
//  UltimatePortfolio
//
//  Created by Hunter Dobbelmann on 4/9/23.
//

import Foundation

extension Bundle {

	/// Decode a JSON file in your apps bundle.
	/// - Parameters:
	///   - file: The file name of the file to decode in your apps bundle.
	///   - type: The type to decode to. Defaults to the generic type.
	///   'T.self' is referencing a general instance of type T.
	///   'T.Type' is saying something is of type T. Ex. using Int: (type: Int = Int()) - I think
	///   - dateDecodingStrategy: Defaults to .deferredToDate.
	///   - keyDecodingStrategy: Defaults to .useDefaultKeys as opposed to .convertFromSnakeCase.
	/// - Returns: The type provided
	func decode<T: Decodable>(
		_ file: String,
		as type: T.Type = T.self,
		dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
		keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
	) -> T {
		// Attempt to locate file in bundle.
		guard let url = self.url(forResource: file, withExtension: nil) else {
			fatalError("Unable to locate \(file) in bundle.")
		}

		// Attempt to create a Data instance using the url from above.
		guard let data = try? Data(contentsOf: url) else {
			fatalError("Failed to load file from bundle.")
		}

		// Configure a JSONDecoder with the settings passed into the function.
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = dateDecodingStrategy
		decoder.keyDecodingStrategy = keyDecodingStrategy

		do {
			return try decoder.decode(T.self, from: data)
		} catch DecodingError.keyNotFound(let key, let context) {
			fatalError("Failed to decode \(file) from bundle due to missing key '\(key.stringValue)' - \(context.debugDescription)")
		} catch DecodingError.typeMismatch(_, let context) {
			fatalError("Failed to decode \(file) from bundle due to type mismatch - \(context.debugDescription)")
		} catch DecodingError.valueNotFound(let type, let context) {
			fatalError("Failed to decode \(file) from bundle due to missing \(type) value - \(context.debugDescription)")
		} catch DecodingError.dataCorrupted(_) {
			fatalError("Failed to decode \(file) from bundle because it appears to be invalid JSON.")
		} catch {
			fatalError("Failed to decode \(file) from bundle: \(error.localizedDescription)")
		}
	}
}
