//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 4/8/23.
//

@_implementationOnly import GDExtension

public enum ArrayError {
    case outOfRange
}
extension GArray: Collection {
    public func index(after i: Int) -> Int {
        return i+1
    }
    
    public var startIndex: Int {
        return 0
    }
    
    /// The collection’s “past the end” position—that is, the position one greater than the last valid subscript argument.
    public var endIndex: Int {
        return Int (size())
    }
    
    public subscript (index: Int) -> Variant {
        get {
            guard let ret = gi.array_operator_index (&content, Int64 (index)) else {
                return Variant()
            }
            let ptr = ret.assumingMemoryBound(to: Variant.ContentType.self)
            return Variant(fromContent: ptr.pointee)
        }
        set {
            guard let ret = gi.array_operator_index (&content, Int64 (index)) else {
                return
            }
            let ptr = ret.assumingMemoryBound(to: Variant.ContentType.self)
            ptr.pointee = newValue.content
        }
    }
}

extension GArray {
	public convenience init<T: VariantRepresentable>(_ type: T.Type = T.self) {
		self.init(
			base: GArray(),
			type: Int32(T.godotType.rawValue),
			className: T.godotType == .object ? StringName("\(T.self)") : StringName(),
			script: Variant()
		)
	}
	
	public convenience init<T: VariantRepresentable>(_ array: [T]) {
		self.init(T.self)
		GD.printDebug("array: \(array)")
		array.forEach { append(value: Variant($0)) }
		GD.printDebug("count: \(count)")
	}
	
	public func asArray<T: VariantRepresentable>(_ type: T.Type = T.self) -> [T] {
		GD.printDebug("count: \(count)")
		let result: [T] = compactMap { T.makeOrUnwrap($0) }
		GD.printDebug("result.count: \(result.count) [\(result)]")
		return result
	}
}
