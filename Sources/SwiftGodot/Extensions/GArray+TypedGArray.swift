//
//  GArray+TypedGArray.swift
//
//
//  Created by Estevan Hernandez on 11/24/23.
//

import Foundation

public extension GArray {
	/// Creates an empty typed GArray whose elements conform to `VariantRepresentable`
	static func empty<T: VariantRepresentable>(_ type: T.Type = T.self) -> GArray {
		GArray( base: GArray(), type: Int32(T.godotType.rawValue), className: StringName("\(T.self)"), script: Variant())
	}
	
	/// Creates a GArray whose elements are from the passed array, and whose elements conform to `VariantRepresentable`
	static func make<T: VariantRepresentable>(_ array: [T]) -> GArray {
		array.reduce(into: empty(T.self)) {
			$0.append(value: Variant($1))
		}
	}
	
	/// Returns an array of elements that are of type `T: VariantRepresentable`
	func asArray<T: VariantRepresentable>(_ type: T.Type = T.self) -> [T] {
		compactMap { T($0) }
	}
}
