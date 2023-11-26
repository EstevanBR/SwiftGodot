//
//  GArray+Utils.swift
//
//
//  Created by Estevan Hernandez on 11/26/23.
//

public extension GArray {
	/// Creates an empty typed GArray whose elements conform to `VariantRepresentable`
	static func empty<T: VariantRepresentable>(_ type: T.Type = T.self) -> GArray {
		GArray(
			base: GArray(),
			type: Int32(T.godotType.rawValue),
			className: T.godotType == .object ? StringName("\(T.self)") : StringName(),
			script: Variant()
		)
	}

	/// Creates a GArray whose elements are from the passed array, and whose elements conform to `VariantRepresentable`
	static func make<T: VariantRepresentable>(_ array: [T]) -> GArray {
		array.reduce(into: empty(T.self)) {
			$0.append(value: Variant($1))
		}
	}
}

public extension Array where Element: VariantRepresentable {
	var gArray: GArray { self.reduce(into: .empty(Element.self)) { $0.append(value: Variant($1)) } }
}
