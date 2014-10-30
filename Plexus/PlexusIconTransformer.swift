//
//  PlexusIconTransformer.swift
//  Plexus
//
//  Created by matt on 10/28/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusIconTransformer: NSValueTransformer {
    

    override class func transformedValueClass() -> AnyClass {
        return NSImage.self
    }
    
    override func transformedValue(value: AnyObject!) -> (AnyObject!) {
        
        
        if(value == nil) {
            return NSImage(named: "PlexusTest")
        }
        
        
        switch value as NSString {
            
            case "PlexusTest":
                return NSImage(named: "PlexusTest")


        default:
            return NSImage(named: "PlexusEntry")         }
        

    }


}
