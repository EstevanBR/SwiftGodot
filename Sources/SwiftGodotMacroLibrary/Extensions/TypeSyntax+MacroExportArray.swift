//
//  TypeSyntax+MacroExportArray.swift
//  
//
//  Created by Estevan Hernandez on 11/22/23.
//

import SwiftSyntax

extension TypeSyntax {
	/// Returns `true` if type is either `[Element]` or `Array<Element>`
	var isArray: Bool {
		isSquareArray || isGenericArray
	}
	/// Returns `"Element"` if type is `[Element]` or `Array<Element>`
	var arrayElementTypeName: String? {
		if isGenericArray {
			return getGenericArrayElementTypeName()
		} else if isSquareArray {
			return getArrayElementTypeName()
		}
		return nil
	}
}

private extension TypeSyntax {
	// [String] for example
	var isSquareArray: Bool {
		self.is(ArrayTypeSyntax.self)
	}
	
	// Array<String> for example
	var isGenericArray: Bool {
		self.as(IdentifierTypeSyntax.self)?.name.text == "Array"
	}
	
	func getArrayElementTypeName() -> String? {
		guard let arrayDecl = self.as(ArrayTypeSyntax.self),
			  let elementTypeName = arrayDecl
			.element
			.as(IdentifierTypeSyntax.self)?
			.name
			.text else {
			return nil
		}
		
		return elementTypeName
	}
	
	func getGenericArrayElementTypeName() -> String? {
		guard let identifier = self.as(IdentifierTypeSyntax.self),
			  identifier.name.text == "Array",
			  let elementTypeName = identifier.genericArgumentClause?
			.arguments
			.first?
			.argument
			.as(IdentifierTypeSyntax.self)?
			.name
			.text else {
			return nil
		}
		
		return elementTypeName
	}
}
