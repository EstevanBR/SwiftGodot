//
//  TypedGArray.swift
//
//
//  Created by Estevan Hernandez on 11/24/23.
//

/// This struct is primarily used to facilitate the `@Export` of `Array` types whose elements conform to `VariantRepresentable`
/// It acts as a wrapper for the Swift Array and manages an underlying `GArray`
/// `@Export exportedArray: Array<Node> = []`
public class TypedGArray<T: VariantRepresentable> {
	public var _gArray: GArray = .empty(T.self)
	private var _array: [T] = []
	
	public var gArray: GArray {
		get {
			_gArray
		}
		
		set {
			_gArray = newValue
			_array = newValue.asArray(T.self)
		}
	}
	
	public var array: [T] {
		get {
			_gArray.asArray(T.self)
		}

		set {
			_array = newValue
			_gArray = newValue.gArray
		}
	}
}

public extension Array where Element: VariantRepresentable {
	var gArray: GArray {
		self.reduce(into: .empty(Element.self)) {
			$0.append(value: Variant($1))
		}
	}
}

private extension GArray {
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

	/// Returns an array of elements that are of type `T: VariantRepresentable`
	func asArray<T: VariantRepresentable>(_ type: T.Type = T.self) -> [T] {
		compactMap {
			.makeOrUnwrap($0)
		}
	}
}
