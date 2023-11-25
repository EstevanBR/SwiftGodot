//
//  TypedGArray.swift
//
//
//  Created by Estevan Hernandez on 11/24/23.
//

public struct TypedGArray<T: VariantRepresentable> {
	public var gArray: GArray

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

public extension GArray {
	static func empty<T: VariantRepresentable>(_ type: T.Type = T.self) -> GArray {
		GArray( base: GArray(), type: Int32(T.godotType.rawValue), className: StringName("\(T.self)"), script: Variant())
	}
	
	static func make<T: VariantRepresentable>(_ array: [T]) -> GArray {
		array.reduce(into: empty(T.self)) {
			$0.append(value: Variant($1))
		}
	}
	
	func asArray<T: VariantRepresentable>(_ type: T.Type = T.self) -> [T] {
		compactMap { T($0) }
	}
}
