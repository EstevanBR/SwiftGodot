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
	static func createArrayResults(varName: String, elementTypeName: String) -> [DeclSyntax] {
		var results: [DeclSyntax] = []
		results.append (DeclSyntax(stringLiteral: makeGArrayVar(varName: varName, elementTypeName: elementTypeName)))
		results.append (DeclSyntax(stringLiteral: makeTypedGArrayGenericStruct()))
		results.append (DeclSyntax(stringLiteral: makeGetAccessor(varName: varName)))
		results.append (DeclSyntax(stringLiteral: makeSetAccessor(varName: varName, elementTypeName: elementTypeName)))
		
		return results
	}
	
	private static func makeTypedGArrayGenericStruct() -> String {
		"""
		private struct TypedGArray<T: VariantRepresentable> {
			private let gType: Variant.GType
			private let className: StringName
			private let empty: GArray

			var gArray: GArray

			private var _array: [T]
			var array: [T] {
				mutating get {
					_array = gArray.compactMap { T($0) }
					return _array
				}

				mutating set {
					_array = newValue
					let empty = GArray( base: GArray(), type: Int32(gType.rawValue), className: className, script: Variant())
					gArray = _array.reduce(into: empty) { $0.append(value: Variant($1)) }
				}
			}

			init(gType: Variant.GType, _ _array: inout [T]) {
				self.className = StringName("\\(T.self)")
				self.gType = gType
				self.empty = GArray( base: GArray(), type: Int32(gType.rawValue), className: className, script: Variant())
				self.gArray = _array.reduce(into: empty) { $0.append(value: Variant($1)) }
				self._array = _array
			}
		}
		"""
	}
	
	private static func makeGArrayVar(varName: String, elementTypeName: String) -> String {
		"""
		private lazy var _\(varName)GArray = TypedGArray<\(elementTypeName)>(gType: \(godotVariants[elementTypeName] ?? ".object"), &\(varName))
		"""
	}
	
	private static func makeGetAccessor (varName: String) -> String {
		"""
		func _mproxy_get_\(varName)(args: [Variant]) -> Variant? {
			return Variant(_\(varName)GArray)
		}
		"""
	}
	
	private static func makeSetAccessor (varName: String, elementTypeName: String) -> String {
		"""
		func _mproxy_set_\(varName)(args: [Variant]) -> Variant? {
			guard let arg = args.first,
				  let garray = GArray(arg),
				  garray.isTyped(),
				  garray.isSameTyped(array: _\(varName)GArray),
				  garray.allSatisfy({ \(elementTypeName)($0) != nil }) else {
				\(varName) = []
				return Variant(_\(varName)GArray)
			}
			_\(varName)GArray = garray
			return nil
		}
		"""
	}
}
