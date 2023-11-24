//
//  TypedGArray.swift
//
//
//  Created by Estevan Hernandez on 11/24/23.
//

public struct TypedGArray<T: VariantRepresentable> {
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
			let empty = TypedGArray.empty()
			gArray = _array.reduce(into: empty) {
				$0.append(value: Variant($1))
			}
		}
	}

	public init(gType: Variant.GType, _ _array: inout [T]) {
		self.className = StringName("\(T.self)")
		self.empty = TypedGArray.empty()
		self.gArray = _array.reduce(into: empty) {
			$0.append(value: Variant($1))
		}
		self._array = _array
	}
}

private extension TypedGArray {
	static func empty() -> GArray {
		GArray( base: GArray(), type: Int32(T.godotType.rawValue), className: StringName("\(T.self)"), script: Variant())
	}
}
