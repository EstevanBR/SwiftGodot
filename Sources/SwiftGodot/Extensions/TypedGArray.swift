//
//  TypedGArray.swift
//
//
//  Created by Estevan Hernandez on 11/24/23.
//

public struct TypedGArray<T: VariantRepresentable> {
	private let empty: GArray

	public var gArray: GArray

	private var _array: [T]
	public var array: [T] {
		mutating get {
			_array = gArray.compactMap {
				T($0)
			}
			return _array
		}

		mutating set {
			_array = newValue
			let empty = GArray.empty(T.self)
			gArray = _array.reduce(into: empty) {
				$0.append(value: Variant($1))
			}
		}
	}

	public init(_ array: inout [T]) {
		self.empty = GArray.empty(T.self)
		self.gArray = array.reduce(into: empty) {
			$0.append(value: Variant($1))
		}
		self._array = array
	}
}

public extension GArray {
	static func empty<T: VariantRepresentable>(_ type: T.Type = T.self) -> GArray {
		GArray( base: GArray(), type: Int32(T.godotType.rawValue), className: StringName("\(T.self)"), script: Variant())
	}
}
