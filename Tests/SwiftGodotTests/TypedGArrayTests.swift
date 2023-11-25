//
//  TypedGArrayTests.swift
//  SwiftGodotTests
//
//  Created by Estevan Hernandez on 11/24/23.
//

import XCTest
import SwiftGodotTestability
@testable import SwiftGodot

final class TypedGArrayTests: GodotTestCase {
	func testTypedGArrayHasElementAfterAppendingToArray() {
		let sut = makeSUT(Int.self)
		
		sut.array.append(0)
		
		XCTAssertEqual(sut.array, [0])
		XCTAssertEqual(sut.gArray.asArray(Int.self), [0])
	}
	
	func testTypedGArrayHasElementsAfterSettingArray() {
		let sut = makeSUT(Int.self)
		
		sut.array = [1, 2, 3]
		
		XCTAssertEqual(sut.array, [1, 2, 3])
		XCTAssertEqual(sut.gArray.asArray(Int.self), [1, 2, 3])
	}
	
	func testTypedGArrayHasElementAfterAppendingToGArray() {
		let sut = makeSUT(Int.self)
		
		sut.gArray.append(value: Variant(0))
		
		XCTAssertEqual(sut.array, [0])
		XCTAssertEqual(sut.gArray.asArray(Int.self), [0])
	}
	
	func testTypedGArrayHasElementsAfterSettingGArray() {
		let sut = makeSUT(Int.self)
		
		sut.gArray = [1, 2, 3].gArray
		
		XCTAssertEqual(sut.array, [1, 2, 3])
		XCTAssertEqual(sut.gArray.asArray(Int.self), [1, 2, 3])
	}
	
	func testGArrayExtensions() {
		XCTAssertEqual(GArray.make([123]).asArray(), [123])
		XCTAssertEqual(GArray.empty(Int.self).asArray(), [Int]())
		XCTAssertEqual([321].gArray.asArray(Int.self), [321])
	}
	
	private func makeSUT<T: VariantRepresentable>(_ type: T.Type = T.self) -> TypedGArray<T> {
		.init()
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
		compactMap { .makeOrUnwrap($0) }
	}
}
