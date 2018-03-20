//
//  NodeLinkExtension.swift
//  Plexus
//
//  Created by matt on 3/2/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreServices

extension NodeLink {

    func addBNNodeObject(_ value:BNNode) {
        let items = self.mutableSetValue(forKey: "bnNode");
        items.add(value)
    }
    
    func addScopeObject(_ value:Model) {
        let items = self.mutableSetValue(forKey: "scope");
        items.add(value)
    }
    
    
    func writableTypesForPasteboard(_ pasteboard: NSPasteboard!) -> [AnyObject] {
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        return registeredTypes as [AnyObject]
    }


    func pasteboardPropertyListForType(_ type: String!) -> AnyObject! {
        let kString : String = kUTTypeURL as String
        if(type == kString){
            let moURI : NSURL = self.objectID.uriRepresentation() as NSURL
            return moURI.pasteboardPropertyList(forType: kString) as AnyObject!
        }
        return nil
    }

}
