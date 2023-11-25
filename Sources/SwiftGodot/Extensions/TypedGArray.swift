//
//  TypedGArray.swift
//
//
//  Created by Estevan Hernandez on 11/24/23.
//

/// This struct is primarily used to facilitate the `@Export` of `Array` types whose elements conform to `VariantRepresentable`
/// It acts as a wrapper for the Swift Array and manages an underlying `GArray`
/// `@Export exportedArray: Array<Node> = []`
public struct TypedGArray<T: VariantRepresentable> {
	public private(set) var gArray: GArray

	private var _array: [T]
	public var array: [T] {
		mutating get {
			_array = gArray.asArray()
			return _array
		}

		mutating set {
			_array = newValue
			gArray = GArray.make(newValue)
		}
	}

	public init(_ array: inout [T]) {
		self.gArray = GArray.make(array)
		self._array = array
	}
}
