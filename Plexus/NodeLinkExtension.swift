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
        var items = self.mutableSetValueForKey("bnNode");
        items.addObject(value)
    }
    
    func writableTypesForPasteboard(pasteboard: NSPasteboard!) -> [AnyObject] {
        let kString : String = kUTTypeURL as String
        var registeredTypes:[String] = [kString]
        return registeredTypes
    }


    func pasteboardPropertyListForType(type: String!) -> AnyObject! {
        let kString : String = kUTTypeURL as String
        if(type == kString){
            var moURI : NSURL = self.objectID.URIRepresentation()
            return moURI.pasteboardPropertyListForType(kString)
        }
        return nil
    }

}