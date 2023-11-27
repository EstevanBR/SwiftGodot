//
//  MacroGodotTests.swift
//  
//
//  Created by Padraig O Cinneide on 2023-09-28.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftGodotMacroLibrary

// Note when editing: Xcode loves to change all indentation to be consistent as either tabs or spaces, but the macro expansion produces a mix.
// I had to set Settings->Text Editing->Tab Key to "Inserts a Tab Character" in order to resolve this.
// "Paste and Preserve Formatting" was also helpful.

final class MacroGodotTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Godot": GodotMacro.self,
		"Callable": GodotCallable.self,
		"Export": GodotExport.self,
        "signal": SignalMacro.self
    ]
    
    func testGodotMacro() {
        assertMacroExpansion(
            """
            @Godot class Hi: Node {
            }
            """,
            expandedSource: """
            class Hi: Node {
            
                override open class var classInitializer: Void {
                    let _ = super.classInitializer
                    return _initializeClass
                }
            
                private static var _initializeClass: Void = {
                    let className = StringName("Hi")
                    let classInfo = ClassInfo<Hi> (name: className)
                } ()
            }
            """,
            macros: testMacros
        )
    }

    func testGodotMacroWithFinalClass() {
        assertMacroExpansion(
            """
            @Godot final class Hi: Node {
                override func _hasPoint(_ point: Vector2) -> Bool { false }
            }
            """,
            expandedSource: """
            final class Hi: Node {
                override func _hasPoint(_ point: Vector2) -> Bool { false }

                override public class var classInitializer: Void {
                    let _ = super.classInitializer
                    return _initializeClass
                }

                private static var _initializeClass: Void = {
                    let className = StringName("Hi")
                    let classInfo = ClassInfo<Hi> (name: className)
                } ()

                override public class func implementedOverrides() -> [StringName] {
                    super.implementedOverrides() + [
                    	StringName("_has_point"),
                    ]
                }
            }
            """,
            macros: testMacros
        )
    }

    func testGodotVirtualMethodsMacro() {
        assertMacroExpansion(
            """
            @Godot class Hi: Control {
                override func _hasPoint(_ point: Vector2) -> Bool { false }
            }
            """,
            expandedSource: """
            class Hi: Control {
                override func _hasPoint(_ point: Vector2) -> Bool { false }
            
                override open class var classInitializer: Void {
                    let _ = super.classInitializer
                    return _initializeClass
                }
            
                private static var _initializeClass: Void = {
                    let className = StringName("Hi")
                    let classInfo = ClassInfo<Hi> (name: className)
                } ()
            
                override open class func implementedOverrides() -> [StringName] {
                    super.implementedOverrides() + [
                    	StringName("_has_point"),
                    ]
                }
            }
            """,
            macros: testMacros
        )
    }
	
	func testGodotMacroWithNonCallableFunc() {
		// Note when editing: Xcode loves to change all indentation to be consistent as either tabs or spaces, but the macro expansion produces a mix.
		// I had to set Settings->Text Editing->Tab Key to "Inserts a Tab Character" in order to resolve this.
		assertMacroExpansion(
			"""
			@Godot class Hi: Node {
				func hi() {
				}
			}
			""",
            expandedSource: """
            class Hi: Node {
            	func hi() {
            	}
            
                override open class var classInitializer: Void {
                    let _ = super.classInitializer
                    return _initializeClass
                }
            
                private static var _initializeClass: Void = {
                    let className = StringName("Hi")
                    let classInfo = ClassInfo<Hi> (name: className)
                } ()
            }
            """,
			macros: testMacros
		)
	}
    func testGodotMacroStaticSignal() {
        // Note when editing: Xcode loves to change all indentation to be consistent as either tabs or spaces, but the macro expansion produces a mix.
        // I had to set Settings->Text Editing->Tab Key to "Inserts a Tab Character" in order to resolve this.
        assertMacroExpansion(
            """
            @Godot class Hi: Node {
                #signal("picked_up_item", arguments: ["kind": String.self])
                #signal("scored")
                #signal("different_init", arguments: [:])
                #signal("different_init2", arguments: .init())
            }
            """,
            expandedSource: """
            class Hi: Node {
                static let pickedUpItem = SignalWith1Argument<String>("picked_up_item", argument1Name: "kind")
                static let scored = SignalWithNoArguments("scored")
                static let differentInit = SignalWithNoArguments("different_init")
                static let differentInit2 = SignalWithNoArguments("different_init2")

                override open class var classInitializer: Void {
                    let _ = super.classInitializer
                    return _initializeClass
                }
            
                private static var _initializeClass: Void = {
                    let className = StringName("Hi")
                    let classInfo = ClassInfo<Hi> (name: className)
                    classInfo.registerSignal(name: Hi.pickedUpItem.name, arguments: Hi.pickedUpItem.arguments)
                    classInfo.registerSignal(name: Hi.scored.name, arguments: Hi.scored.arguments)
                    classInfo.registerSignal(name: Hi.differentInit.name, arguments: Hi.differentInit.arguments)
                    classInfo.registerSignal(name: Hi.differentInit2.name, arguments: Hi.differentInit2.arguments)
                } ()
            }
            """,
            macros: testMacros
        )
    }
	
	func testGodotMacroWithCallableFunc() {
		// Note when editing: Xcode loves to change all indentation to be consistent as either tabs or spaces, but the macro expansion produces a mix.
		// I had to set Settings->Text Editing->Tab Key to "Inserts a Tab Character" in order to resolve this.
		assertMacroExpansion(
            """
            @Godot class Castro: Node {
                @Callable func deleteEpisode() {}
                @Callable func subscribe(podcast: Podcast) {}
                @Callable func removeSilences(from: Variant) {}
            }
            """,
            expandedSource: """
            class Castro: Node {
                func deleteEpisode() {}
            
                func _mproxy_deleteEpisode (args: [Variant]) -> Variant? {
                	deleteEpisode ()
                	return nil
                }
                func subscribe(podcast: Podcast) {}
            
                func _mproxy_subscribe (args: [Variant]) -> Variant? {
                	subscribe (podcast: Podcast.makeOrUnwrap (args [0])!)
                	return nil
                }
                func removeSilences(from: Variant) {}
            
                func _mproxy_removeSilences (args: [Variant]) -> Variant? {
                	removeSilences (from: args [0])
                	return nil
                }
            
                override open class var classInitializer: Void {
                    let _ = super.classInitializer
                    return _initializeClass
                }
            
                private static var _initializeClass: Void = {
                    let className = StringName("Castro")
                    let classInfo = ClassInfo<Castro> (name: className)
                	classInfo.registerMethod(name: StringName("deleteEpisode"), flags: .default, returnValue: nil, arguments: [], function: Castro._mproxy_deleteEpisode)
                    let prop_0 = PropInfo (propertyType: .object, propertyName: "Podcast", className: className, hint: .none, hintStr: "", usage: .default)
                	let subscribeArgs = [
                		prop_0,
                	]
                	classInfo.registerMethod(name: StringName("subscribe"), flags: .default, returnValue: nil, arguments: subscribeArgs, function: Castro._mproxy_subscribe)
                    let prop_1 = PropInfo (propertyType: .object, propertyName: "Variant", className: className, hint: .none, hintStr: "", usage: .default)
                	let removeSilencesArgs = [
                		prop_1,
                	]
                	classInfo.registerMethod(name: StringName("removeSilences"), flags: .default, returnValue: nil, arguments: removeSilencesArgs, function: Castro._mproxy_removeSilences)
                } ()
            }
            """,
			macros: testMacros
		)
	}
	
	func testExportGodotMacro() {
		assertMacroExpansion(
			"""
			@Godot class Hi: Node {
				@Export var goodName: String = "Supertop"
			}
			""",
			expandedSource:
            """
            class Hi: Node {
            	var goodName: String = "Supertop"
            
            	func _mproxy_set_goodName (args: [Variant]) -> Variant? {
            		goodName = String (args [0])!
            		return nil
            	}
            
            	func _mproxy_get_goodName (args: [Variant]) -> Variant? {
            	    return Variant (goodName)
            	}
            
                override open class var classInitializer: Void {
                    let _ = super.classInitializer
                    return _initializeClass
                }
            
                private static var _initializeClass: Void = {
                    let className = StringName("Hi")
                    let classInfo = ClassInfo<Hi> (name: className)
                    let _pgoodName = PropInfo (
                        propertyType: .string,
                        propertyName: "goodName",
                        className: className,
                        hint: .none,
                        hintStr: "",
                        usage: .default)
                	classInfo.registerMethod (name: "_mproxy_get_goodName", flags: .default, returnValue: _pgoodName, arguments: [], function: Hi._mproxy_get_goodName)
                	classInfo.registerMethod (name: "_mproxy_set_goodName", flags: .default, returnValue: nil, arguments: [_pgoodName], function: Hi._mproxy_set_goodName)
                	classInfo.registerProperty (_pgoodName, getter: "_mproxy_get_goodName", setter: "_mproxy_set_goodName")
                } ()
            }
            """,
			macros: testMacros
		)
	}
	
	func testExportArrayStringGodotMacroFails() {
		assertMacroExpansion(
			"""
			@Godot
			class SomeNode: Node {
				@Export
				var greetings: [String]
			}
			""",
		expandedSource:
			"""

			class SomeNode: Node {
				var greetings: [String]
			}
			""",
			diagnostics: [
				.init(message: "@Export can not be applied to Array, use VariantCollection instead", line: 3, column: 2),
				.init(message: "@Export can not be applied to Array, use VariantCollection instead", line: 1, column: 1)
			],
			macros: testMacros
		)
	}
	
	func testExportArrayStringMacroFails() {
		assertMacroExpansion(
			"""
			@Export
			var greetings: [String]
			""",
		expandedSource:
			"""

			var greetings: [String]
			""",
			diagnostics: [
				.init(message: "@Export can not be applied to Array, use VariantCollection instead", line: 1, column: 1)
			],
			macros: testMacros
		)
	}

	func testExportGenericArrayStringGodotMacro() {
		assertMacroExpansion(
"""
@Godot
class SomeNode: Node {
	@Export
	var greetings: VariantCollection<String> = []
}
""",
			expandedSource:
"""


class SomeNode: Node {
	var greetings: VariantCollection<String> = []

	func _mproxy_get_greetings(args: [Variant]) -> Variant? {
		return Variant(greetings.array)
	}

	func _mproxy_set_greetings(args: [Variant]) -> Variant? {
		guard let arg = args.first,
			  let gArray = GArray(arg),
			  gArray.isTyped(),
			  gArray.isSameTyped(array: GArray(String.self)),
			  let variantCollection = VariantCollection<String>(Variant(gArray)) else {
			return nil
		}
		greetings = variantCollection
		return nil
	}

    override open class var classInitializer: Void {
        let _ = super.classInitializer
        return _initializeClass
    }

    private static var _initializeClass: Void = {
        let className = StringName("SomeNode")
        let classInfo = ClassInfo<SomeNode> (name: className)
        let _pgreetings = PropInfo (
            propertyType: .array,
            propertyName: "greetings",
            className: StringName("Array[String]"),
            hint: .none,
            hintStr: "Array of String",
            usage: .default)
    	classInfo.registerMethod (name: "get_greetings", flags: .default, returnValue: _pgreetings, arguments: [], function: SomeNode._mproxy_get_greetings)
    	classInfo.registerMethod (name: "set_greetings", flags: .default, returnValue: nil, arguments: [_pgreetings], function: SomeNode._mproxy_set_greetings)
    	classInfo.registerProperty (_pgreetings, getter: "get_greetings", setter: "set_greetings")
    } ()
}
""",
			macros: testMacros
		)
	}
	
	func testExportArrayStringMacro() {
		assertMacroExpansion(
"""
@Export
var greetings: [String] = []
""",
			expandedSource:
"""

var greetings: [String] = []

private lazy var _greetings_GArray: GArray = .make(greetings) {
	didSet {
		greetings = _greetings_GArray.compactMap(String.makeOrUnwrap)
	}
}

func _mproxy_get_greetings(args: [Variant]) -> Variant? {
	greetings = _greetings_GArray.compactMap(String.makeOrUnwrap)
	return Variant(_greetings_GArray)
}

func _mproxy_set_greetings(args: [Variant]) -> Variant? {
	guard let arg = args.first,
		  let gArray = GArray(arg),
		  gArray.allSatisfy({
	        String($0) != nil
	    }) else {
		greetings = []
		return Variant(GArray.empty(String.self))
	}
	_greetings_GArray = gArray
	return nil
}
""",
			macros: testMacros
		)
	}
	
	func testExportGenericArrayStringMacro() {
		assertMacroExpansion(
"""
@Export
var greetings: Array<String> = []
""",
			expandedSource:
"""

var greetings: Array<String> = []

private lazy var _greetings_GArray: GArray = .make(greetings) {
	didSet {
		greetings = _greetings_GArray.compactMap(String.makeOrUnwrap)
	}
}

func _mproxy_get_greetings(args: [Variant]) -> Variant? {
	greetings = _greetings_GArray.compactMap(String.makeOrUnwrap)
	return Variant(_greetings_GArray)
}

func _mproxy_set_greetings(args: [Variant]) -> Variant? {
	guard let arg = args.first,
		  let gArray = GArray(arg),
		  gArray.allSatisfy({
	        String($0) != nil
	    }) else {
		greetings = []
		return Variant(GArray.empty(String.self))
	}
	_greetings_GArray = gArray
	return nil
}
""",
			macros: testMacros
		)
	}
	
	func testExportArrayIntGodotMacro() {
		assertMacroExpansion(
"""
@Godot
class SomeNode: Node {
	@Export
	var someNumbers: [Int] = []
}
""",
			expandedSource:
"""
class SomeNode: Node {
	var someNumbers: [Int] = []

	private lazy var _someNumbers_GArray: GArray = .make(someNumbers) {
		didSet {
			someNumbers = _someNumbers_GArray.compactMap(Int.makeOrUnwrap)
		}
	}

	func _mproxy_get_someNumbers(args: [Variant]) -> Variant? {
		someNumbers = _someNumbers_GArray.compactMap(Int.makeOrUnwrap)
		return Variant(_someNumbers_GArray)
	}

	func _mproxy_set_someNumbers(args: [Variant]) -> Variant? {
		guard let arg = args.first,
			  let gArray = GArray(arg),
			  gArray.allSatisfy({
		        Int($0) != nil
		    }) else {
			someNumbers = []
			return Variant(GArray.empty(Int.self))
		}
		_someNumbers_GArray = gArray
		return nil
	}

    override open class var classInitializer: Void {
        let _ = super.classInitializer
        return _initializeClass
    }

    private static var _initializeClass: Void = {
        let className = StringName("SomeNode")
        let classInfo = ClassInfo<SomeNode> (name: className)
        let _psomeNumbers = PropInfo (
            propertyType: .array,
            propertyName: "someNumbers",
            className: StringName("Array[int]"),
            hint: .none,
            hintStr: "Array of Int",
            usage: .default)
    	classInfo.registerMethod (name: "get_some_numbers", flags: .default, returnValue: _psomeNumbers, arguments: [], function: SomeNode._mproxy_get_someNumbers)
    	classInfo.registerMethod (name: "set_some_numbers", flags: .default, returnValue: nil, arguments: [_psomeNumbers], function: SomeNode._mproxy_set_someNumbers)
    	classInfo.registerProperty (_psomeNumbers, getter: "get_some_numbers", setter: "set_some_numbers")
    } ()
}
""",
			macros: testMacros
		)
	}

	func testExportArraysIntGodotMacro() throws {
		assertMacroExpansion(
"""
@Godot
class SomeNode: Node {
	@Export
	var someNumbers: [Int] = []
 	@Export
 	var someOtherNumbers: [Int] = []
}
""",
			expandedSource:
"""
class SomeNode: Node {
	var someNumbers: [Int] = []

	private lazy var _someNumbers_GArray: GArray = .make(someNumbers) {
		didSet {
			someNumbers = _someNumbers_GArray.compactMap(Int.makeOrUnwrap)
		}
	}

	func _mproxy_get_someNumbers(args: [Variant]) -> Variant? {
		someNumbers = _someNumbers_GArray.compactMap(Int.makeOrUnwrap)
		return Variant(_someNumbers_GArray)
	}

	func _mproxy_set_someNumbers(args: [Variant]) -> Variant? {
		guard let arg = args.first,
			  let gArray = GArray(arg),
			  gArray.allSatisfy({
		        Int($0) != nil
		    }) else {
			someNumbers = []
			return Variant(GArray.empty(Int.self))
		}
		_someNumbers_GArray = gArray
		return nil
	}
 	var someOtherNumbers: [Int] = []

 	private lazy var _someOtherNumbers_GArray: GArray = .make(someOtherNumbers) {
 		didSet {
 			someOtherNumbers = _someOtherNumbers_GArray.compactMap(Int.makeOrUnwrap)
 		}
 	}

 	func _mproxy_get_someOtherNumbers(args: [Variant]) -> Variant? {
 		someOtherNumbers = _someOtherNumbers_GArray.compactMap(Int.makeOrUnwrap)
 		return Variant(_someOtherNumbers_GArray)
 	}

 	func _mproxy_set_someOtherNumbers(args: [Variant]) -> Variant? {
 		guard let arg = args.first,
 			  let gArray = GArray(arg),
 			  gArray.allSatisfy({
 		        Int($0) != nil
 		    }) else {
 			someOtherNumbers = []
 			return Variant(GArray.empty(Int.self))
 		}
 		_someOtherNumbers_GArray = gArray
 		return nil
 	}

    override open class var classInitializer: Void {
        let _ = super.classInitializer
        return _initializeClass
    }

    private static var _initializeClass: Void = {
        let className = StringName("SomeNode")
        let classInfo = ClassInfo<SomeNode> (name: className)
        let _psomeNumbers = PropInfo (
            propertyType: .array,
            propertyName: "someNumbers",
            className: StringName("Array[int]"),
            hint: .none,
            hintStr: "Array of Int",
            usage: .default)
    	classInfo.registerMethod (name: "get_some_numbers", flags: .default, returnValue: _psomeNumbers, arguments: [], function: SomeNode._mproxy_get_someNumbers)
    	classInfo.registerMethod (name: "set_some_numbers", flags: .default, returnValue: nil, arguments: [_psomeNumbers], function: SomeNode._mproxy_set_someNumbers)
    	classInfo.registerProperty (_psomeNumbers, getter: "get_some_numbers", setter: "set_some_numbers")
        let _psomeOtherNumbers = PropInfo (
            propertyType: .array,
            propertyName: "someOtherNumbers",
            className: StringName("Array[int]"),
            hint: .none,
            hintStr: "Array of Int",
            usage: .default)
    	classInfo.registerMethod (name: "get_some_other_numbers", flags: .default, returnValue: _psomeOtherNumbers, arguments: [], function: SomeNode._mproxy_get_someOtherNumbers)
    	classInfo.registerMethod (name: "set_some_other_numbers", flags: .default, returnValue: nil, arguments: [_psomeOtherNumbers], function: SomeNode._mproxy_set_someOtherNumbers)
    	classInfo.registerProperty (_psomeOtherNumbers, getter: "get_some_other_numbers", setter: "set_some_other_numbers")
    } ()
}
""",
			macros: testMacros
		)
	}
	
	func testGodotExportTwoStringArrays() throws {
		assertMacroExpansion(
"""
import SwiftGodot

@Godot
class ArrayTest: Node {
   @Export var firstNames: [String] = ["Thelonius"]
   @Export var lastNames: [String] = ["Monk"]
}
"""
		, expandedSource:
"""
import SwiftGodot
class ArrayTest: Node {
   var firstNames: [String] = ["Thelonius"]

   private lazy var _firstNames_GArray: GArray = .make(firstNames) {
   	didSet {
   		firstNames = _firstNames_GArray.compactMap(String.makeOrUnwrap)
   	}
   }

   func _mproxy_get_firstNames(args: [Variant]) -> Variant? {
   	firstNames = _firstNames_GArray.compactMap(String.makeOrUnwrap)
   	return Variant(_firstNames_GArray)
   }

   func _mproxy_set_firstNames(args: [Variant]) -> Variant? {
   	guard let arg = args.first,
   		  let gArray = GArray(arg),
   		  gArray.allSatisfy({
   	        String($0) != nil
   	    }) else {
   		firstNames = []
   		return Variant(GArray.empty(String.self))
   	}
   	_firstNames_GArray = gArray
   	return nil
   }
   var lastNames: [String] = ["Monk"]

   private lazy var _lastNames_GArray: GArray = .make(lastNames) {
   	didSet {
   		lastNames = _lastNames_GArray.compactMap(String.makeOrUnwrap)
   	}
   }

   func _mproxy_get_lastNames(args: [Variant]) -> Variant? {
   	lastNames = _lastNames_GArray.compactMap(String.makeOrUnwrap)
   	return Variant(_lastNames_GArray)
   }

   func _mproxy_set_lastNames(args: [Variant]) -> Variant? {
   	guard let arg = args.first,
   		  let gArray = GArray(arg),
   		  gArray.allSatisfy({
   	        String($0) != nil
   	    }) else {
   		lastNames = []
   		return Variant(GArray.empty(String.self))
   	}
   	_lastNames_GArray = gArray
   	return nil
   }

    override open class var classInitializer: Void {
        let _ = super.classInitializer
        return _initializeClass
    }

    private static var _initializeClass: Void = {
        let className = StringName("ArrayTest")
        let classInfo = ClassInfo<ArrayTest> (name: className)
        let _pfirstNames = PropInfo (
            propertyType: .array,
            propertyName: "firstNames",
            className: StringName("Array[String]"),
            hint: .none,
            hintStr: "Array of String",
            usage: .default)
    	classInfo.registerMethod (name: "get_first_names", flags: .default, returnValue: _pfirstNames, arguments: [], function: ArrayTest._mproxy_get_firstNames)
    	classInfo.registerMethod (name: "set_first_names", flags: .default, returnValue: nil, arguments: [_pfirstNames], function: ArrayTest._mproxy_set_firstNames)
    	classInfo.registerProperty (_pfirstNames, getter: "get_first_names", setter: "set_first_names")
        let _plastNames = PropInfo (
            propertyType: .array,
            propertyName: "lastNames",
            className: StringName("Array[String]"),
            hint: .none,
            hintStr: "Array of String",
            usage: .default)
    	classInfo.registerMethod (name: "get_last_names", flags: .default, returnValue: _plastNames, arguments: [], function: ArrayTest._mproxy_get_lastNames)
    	classInfo.registerMethod (name: "set_last_names", flags: .default, returnValue: nil, arguments: [_plastNames], function: ArrayTest._mproxy_set_lastNames)
    	classInfo.registerProperty (_plastNames, getter: "get_last_names", setter: "set_last_names")
    } ()
}
"""
		, macros: testMacros
		)
	}
}
