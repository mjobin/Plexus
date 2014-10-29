//
//  PlexusIconTransformer.swift
//  Plexus
//
//  Created by matt on 10/28/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusIconTransformer: NSValueTransformer {
    

    
    
    override func transformedValue(value: AnyObject!) -> (AnyObject!) {
        
        var rPath = NSBundle.mainBundle().resourcePath
        println(rPath)
        println(value)
        
       // let urImage = NSImage(named: value)
        
        switch value {
            /*
            case "PlexusTest":
            println("sdjkhdjskhkdsjhfds Plexus test")
            case "PlexusEntry":
            println("sdjkhdjskhkdsjhfds Plexus enrty")
            */
        default:
            println("deeefault")
            return NSImage(named: "PlexusEntry")
        }
        
        return rPath
    }


}
