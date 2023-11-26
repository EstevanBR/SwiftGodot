//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 9/25/23.
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct GodotExport: PeerMacro {
    
    
    static func makeGetAccessor (varName: String, isOptional: Bool) -> String {
        let name = "_mproxy_get_\(varName)"
        if isOptional {
            return
    """
    func \(name) (args: [Variant]) -> Variant? {
        guard let result = \(varName) else { return nil }
        return Variant (result)
    }
    """
        } else {
            return
    """
    func \(name) (args: [Variant]) -> Variant? {
        return Variant (\(varName))
    }
    """
        }
    }
    
    static func makeSetAccessor (varName: String, typeName: String, isOptional: Bool) -> String {
        let name = "_mproxy_set_\(varName)"
        var body: String = ""

        if godotVariants [typeName] == nil {
            let optBody = isOptional ? " else { \(varName) = nil }" : ""
            body =
    """
    	let oldRef = \(varName) as? RefCounted
    	if let res: \(typeName) = args [0].asObject () {
    		(res as? RefCounted)?.reference()
    		\(varName) = res
    	}\(optBody)
    	oldRef?.unreference()
    """
        } else {
            if isOptional {
                body =
    """
    	\(varName) = \(typeName) (args [0])
    """
            } else {
                body =
    """
    	\(varName) = \(typeName) (args [0])!
    """
            }
        }
        return "func \(name) (args: [Variant]) -> Variant? {\n\(body)\n\treturn nil\n}"
    }

    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            let classError = Diagnostic(node: declaration.root, message: GodotMacroError.requiresVar)
            context.diagnose(classError)
            return []
        }
        var isOptional = false
        guard let last = varDecl.bindings.last else {
            throw GodotMacroError.noVariablesFound
        }
        guard var type = last.typeAnnotation?.type else {
            throw GodotMacroError.noTypeFound(varDecl)
        }
        if let optSyntax = type.as (OptionalTypeSyntax.self) {
            isOptional = true
            type = optSyntax.wrappedType
        }
		
		guard type.isArray || type.is(IdentifierTypeSyntax.self) else {
			throw GodotMacroError.unsupportedType(varDecl)
		}

        var results: [DeclSyntax] = []

        for singleVar in varDecl.bindings {
            guard let ips = singleVar.pattern.as(IdentifierPatternSyntax.self) else {
                throw GodotMacroError.expectedIdentifier(singleVar)
            }
            let varName = ips.identifier.text
            
            if let accessors = last.accessorBlock {
                if accessors.as (CodeBlockSyntax.self) != nil {
                    throw MacroError.propertyGetSet
                }
                if let block = accessors.as (AccessorBlockSyntax.self) {
                    var hasSet = false
                    var hasGet = false
                    switch block.accessors {
                    case .accessors(let list):
                        for accessor in list {
                            switch accessor.accessorSpecifier.tokenKind {
                            case .keyword(let val):
                                switch val {
                                case .didSet, .willSet:
                                    hasSet = true
                                    hasGet = true
                                case .set:
                                    hasSet = true
                                case .get:
                                    hasGet = true
                                default:
                                    break
                                }
                            default:
                                break
                            }
                        }
                    default:
                        throw MacroError.propertyGetSet
                    }
                    
                    if hasSet == false || hasGet == false {
                        throw MacroError.propertyGetSet
                    }
                }
            }
			
			if type.isArray, let elementTypeName = type.arrayElementTypeName {
				results.append(contentsOf: createArrayResults(varName: varName, elementTypeName: elementTypeName))
			} else if let typeName = type.as(IdentifierTypeSyntax.self)?.name.text {
				results.append (DeclSyntax(stringLiteral: makeSetAccessor(varName: varName, typeName: typeName, isOptional: isOptional)))
				results.append (DeclSyntax(stringLiteral: makeGetAccessor(varName: varName, isOptional: isOptional)))
			}
        }
		
        return results
    }
}

private extension GodotExport {
	struct ExportedArrayNames {
		let variable: String
		var gArray: String { "_\(variable)_GArray" }
		let element: String
	}
	
	static func createArrayResults(varName: String, elementTypeName: String) -> [DeclSyntax] {
		var results: [DeclSyntax] = []
		// for varName `"someNodes"` will produce `"_someNodes_GArray"`
		let exportedArrayNames = ExportedArrayNames(variable: varName, element: elementTypeName)
		results.append (DeclSyntax(stringLiteral: createEmptyGArray()))
		results.append (DeclSyntax(stringLiteral: createMakeGArray()))
		results.append (DeclSyntax(stringLiteral: makeGArrayVar(names: exportedArrayNames)))
		results.append (DeclSyntax(stringLiteral: makeGetProxyAccessor(names: exportedArrayNames)))
		results.append (DeclSyntax(stringLiteral: makeSetProxyAccessor(names: exportedArrayNames)))
		
		return results
	}
	
	static func createEmptyGArray() -> String {
		"""
		private func empty<T: VariantRepresentable>(_ type: T.Type = T.self) -> GArray {
			GArray(
				base: GArray(),
				type: Int32(T.godotType.rawValue),
				className: T.godotType == .object ? StringName("\\(T.self)") : StringName(),
				script: Variant()
			)
		}
		"""
	}
	
	static func createMakeGArray() -> String {
		"""
		private func make<T: VariantRepresentable>(_ array: [T]) -> GArray {
			array.reduce(into: empty(T.self)) {
				$0.append(value: Variant($1))
			}
		}
		"""
	}
	
	private static func makeGArrayVar(names: ExportedArrayNames) -> String {
		"""
		private lazy var \(names.gArray): GArray = \(names.variable).reduce(into: empty(\(names.element).self)) { $0.append(value: Variant($1)) } { {
			didSet {
				\(names.variable) = \(names.gArray).compactMap(\(names.element).makeOrUnwrap)
			}
		}
		"""
	}
	
	private static func makeGetProxyAccessor(names: ExportedArrayNames) -> String {
		"""
		func _mproxy_get_\(names.variable)(args: [Variant]) -> Variant? {
			\(names.variable) = \(names.gArray).compactMap(\(names.element).makeOrUnwrap)
			return Variant(\(names.gArray))
		}
		"""
	}
	
	private static func makeSetProxyAccessor(names: ExportedArrayNames) -> String {
		"""
		func _mproxy_set_\(names.variable)(args: [Variant]) -> Variant? {
			guard let arg = args.first,
				  let gArray = GArray(arg),
				  gArray.allSatisfy({ \(names.element)($0) != nil }) else {
				\(names.variable) = []
				return Variant(empty)
			}
			\(names.gArray) = gArray
			return nil
		}
		"""
	}
}

//extension GArray {
//	/// Creates an empty typed GArray whose elements conform to `VariantRepresentable`
//	static func empty<T: VariantRepresentable>(_ type: T.Type = T.self) -> GArray {
//		GArray(
//			base: GArray(),
//			type: Int32(T.godotType.rawValue),
//			className: T.godotType == .object ? StringName("\(T.self)") : StringName(),
//			script: Variant()
//		)
//	}
//
//	/// Creates a GArray whose elements are from the passed array, and whose elements conform to `VariantRepresentable`
//	static func make<T: VariantRepresentable>(_ array: [T]) -> GArray {
//		array.reduce(into: empty(T.self)) {
//			$0.append(value: Variant($1))
//		}
//	}
//}
//
//extension Array where Element: VariantRepresentable {
//	var gArray: GArray { self.reduce(into: .empty(Element.self)) { $0.append(value: Variant($1)) } }
//}
