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
            
            // The use of the local function dynamicCast here is such that the compiler
            // can optimize this into a no-op, into the equivalent of "varName as? RefCounted"
            // but prevents the warnings that are being generated by the use of his macro.
            body =
    """
        func dynamicCast<T, U>(_ value: T, as type: U.Type) -> U? { value as? U }
        let oldRef = dynamicCast (\(varName), as: RefCounted.self)
        if let res: \(typeName) = args [0].asObject () {
            dynamicCast (res, as: RefCounted.self)?.reference()
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
        
        guard varDecl.isArray == false else {
            let classError = Diagnostic(node: declaration.root, message: GodotMacroError.requiresGArrayCollection)
            context.diagnose(classError)
            return []
        }
        
        guard type.is(IdentifierTypeSyntax.self) else {
            throw GodotMacroError.unsupportedType(varDecl)
        }
        
        guard (type.isGArrayCollection && isOptional) == false else {
            throw GodotMacroError.requiresNonOptionalGArrayCollection
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
            
            if let elementTypeName = varDecl.gArrayCollectionElementTypeName {
                results.append (DeclSyntax(stringLiteral: makeGArrayCollectionGetProxyAccessor(varName: varName, elementTypeName: elementTypeName)))
                results.append (DeclSyntax(stringLiteral: makeGArrayCollectionSetProxyAccessor(varName: varName, elementTypeName: elementTypeName)))
            } else if let typeName = type.as(IdentifierTypeSyntax.self)?.name.text {
                results.append (DeclSyntax(stringLiteral: makeSetAccessor(varName: varName, typeName: typeName, isOptional: isOptional)))
                results.append (DeclSyntax(stringLiteral: makeGetAccessor(varName: varName, isOptional: isOptional)))
            }
        }
        
        return results
    }
}

private extension GodotExport {
    private static func makeGArrayCollectionGetProxyAccessor(varName: String, elementTypeName: String) -> String {
		"""
		func _mproxy_get_\(varName)(args: [Variant]) -> Variant? {
			return Variant(\(varName).array)
		}
		"""
    }
    
    private static func makeGArrayCollectionSetProxyAccessor(varName: String, elementTypeName: String) -> String {
		"""
		func _mproxy_set_\(varName)(args: [Variant]) -> Variant? {
			guard let arg = args.first,
				  let gArray = GArray(arg),
				  gArray.isTyped(),
				  gArray.isSameTyped(array: GArray(\(elementTypeName).self)) else {
				return nil
			}
			\(varName).array = gArray
			return nil
		}
		"""
    }
}
