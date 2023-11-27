//
//  TypeSyntax+MacroExport.swift
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
	
	var isVariantCollection: Bool {
		self.as(IdentifierTypeSyntax.self)?.name.text == "VariantCollection"
	}
	
	var variantCollectionElementTypeName: String? {
		guard let identifier = self.as(IdentifierTypeSyntax.self),
			  identifier.name.text == "VariantCollection",
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

private extension TypeSyntax {
	// [String] for example
	var isSquareArray: Bool {
		self.is(ArrayTypeSyntax.self)
	}
	
	// Array<String> for example
	var isGenericArray: Bool {
		self.as(IdentifierTypeSyntax.self)?.name.text == "Array"
	}
	
	var variantCollectionGenericElementTypeName: String? {
		guard let identifier = self.as(IdentifierTypeSyntax.self),
			  identifier.name.text == "VariantCollection",
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
	
	var variantCollectionInitializerElementTypeName: String? {
		guard let identifier = self.as(IdentifierTypeSyntax.self),
			  identifier.name.text == "VariantCollection",
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
