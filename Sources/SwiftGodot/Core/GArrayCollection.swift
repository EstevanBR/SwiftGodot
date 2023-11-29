//
//  GArrayCollection.swift
//
//
//  Created by Estevan Hernandez on 11/28/23.
//

@_implementationOnly import GDExtension

protocol GArrayCollection: Collection {
	var array: GArray { set get }
}
