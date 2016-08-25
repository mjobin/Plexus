//
//  NodeLinkExtension.swift
//  Plexus
//
//  Created by matt on 3/2/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Foundation
import CoreServices

extension NodeLink {

    func addBNNodeObject(value:BNNode) {
        let items = self.mutableSetValueForKey("bnNode");
        items.addObject(value)
    }
    
    func addScopeObject(value:Model) {
        let items = self.mutableSetValueForKey("scope");
        items.addObject(value)
    }
    
    
    func writableTypesForPasteboard(pasteboard: NSPasteboard!) -> [AnyObject] {
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        return registeredTypes
    }


    func pasteboardPropertyListForType(type: String!) -> AnyObject! {
        let kString : String = kUTTypeURL as String
        if(type == kString){
            let moURI : NSURL = self.objectID.URIRepresentation()
            return moURI.pasteboardPropertyListForType(kString)
        }
        return nil
    }

}