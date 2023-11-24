//
//  TypedGArray.swift
//
//
//  Created by Estevan Hernandez on 11/24/23.
//

public struct TypedGArray<T: VariantRepresentable> {
	private let gType: Variant.GType
	private let className: StringName
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
			let empty = GArray( base: GArray(), type: Int32(gType.rawValue), className: className, script: Variant())
			gArray = _array.reduce(into: empty) {
				$0.append(value: Variant($1))
			}
		}
	}

	public init(gType: Variant.GType, _ _array: inout [T]) {
		self.className = StringName("\\(T.self)")
		self.gType = gType
		self.empty = GArray( base: GArray(), type: Int32(gType.rawValue), className: className, script: Variant())
		self.gArray = _array.reduce(into: empty) {
			$0.append(value: Variant($1))
		}
		self._array = _array
	}
}
