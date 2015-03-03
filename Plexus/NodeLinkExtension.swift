//
//  NodeLinkExtension.swift
//  Plexus
//
//  Created by matt on 3/2/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Foundation



extension NodeLink {

    func writableTypesForPasteboard(pasteboard: NSPasteboard!) -> [AnyObject] {
        println("writable types")
        var registeredTypes:[String] = [kUTTypeURL]
        return registeredTypes
    }


    func pasteboardPropertyListForType(type: String!) -> AnyObject! {
        println("paste poretylist")
        if(type == kUTTypeURL){
            var moURI : NSURL = self.objectID.URIRepresentation()
            return moURI.pasteboardPropertyListForType(kUTTypeURL)
        }
        return nil
    }

}