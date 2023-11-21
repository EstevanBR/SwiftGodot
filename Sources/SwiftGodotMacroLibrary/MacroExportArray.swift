import Foundation

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct GodotExportArray: PeerMacro {
    public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
		in context: some SwiftSyntaxMacros.MacroExpansionContext
	) throws -> [SwiftSyntax.DeclSyntax] {
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
			let classError = Diagnostic(node: declaration.root, message: GodotMacroError.requiresVar)
			context.diagnose(classError)
			return []
		}
		
		guard let first = varDecl.bindings.first else {
			throw GodotMacroError.noVariablesFound
		}
		
		guard let type = first.typeAnnotation?.type else {
			throw GodotMacroError.noTypeFound(varDecl)
		}
		
		guard let varName = first
			.pattern
			.as(IdentifierPatternSyntax.self)?
			.identifier
			.text
		else {
			let classError = Diagnostic(node: declaration.root, message: GodotMacroError.expectedIdentifier(first))
			context.diagnose(classError)
			return []
		}
		
		guard type.isArray,
			let elementTypeName = type.arrayElementTypeName else {
			let classError = Diagnostic(node: declaration.root, message: GodotMacroError.requiresArray)
			context.diagnose(classError)
			return []
        }
		
        return createResults(varName: varName, elementTypeName: elementTypeName)
    }
}

private extension GodotExportArray {
	static func createResults(varName: String, elementTypeName: String) -> [DeclSyntax] {
		var results: [DeclSyntax] = []
		results.append (DeclSyntax(stringLiteral: makeGArrayVar(varName: varName, elementTypeName: elementTypeName)))
		results.append (DeclSyntax(stringLiteral: makeGetAccessor(varName: varName)))
		results.append (DeclSyntax(stringLiteral: makeSetAccessor(varName: varName, elementTypeName: elementTypeName)))
		
        return results
	}
	
	static func emptyGArray(elementTypeName: String) -> String {
		"GArray(base: GArray(), type: Int32(Variant.GType\(godotVariants[elementTypeName] ?? ".object").rawValue), className: StringName(), script: Variant())"
	}
	
	static func makeGArrayVar(varName: String, elementTypeName: String) -> String {
		"private var _\(varName)GArray: GArray = \(GodotExportArray.emptyGArray(elementTypeName: elementTypeName))"
	}
	
	static func makeGetAccessor (varName: String) -> String {
		"""
		func _mproxy_get_\(varName)(args: [Variant]) -> Variant? {
			return Variant(_\(varName)GArray)
		}
		"""
	}
	
	static func makeSetAccessor (varName: String, elementTypeName: String) -> String {
		"""
		func _mproxy_set_\(varName)(args: [Variant]) -> Variant? {
			let empty = \(GodotExportArray.emptyGArray(elementTypeName: elementTypeName))
			guard args.count > 0,
				  let garray = GArray(args[0]),
				  garray.isTyped(),
				  garray.isSameTyped(array: empty) else {
				_\(varName)GArray = empty
				return Variant(empty)
			}
			_\(varName)GArray = garray
			return nil
		}
		"""
	}
}
