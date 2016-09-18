//
//  PlexusIconTransformer.swift
//  Plexus
//
//  Created by matt on 10/28/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusIconTransformer: ValueTransformer {
    

    override class func transformedValueClass() -> AnyClass {
        return NSImage.self
    }
    
    override func transformedValue(_ value: Any!) -> (Any) {
        
      //  println("pit value \(value)")
        
        if(value == nil) {
            return NSImage(named: "PlexusTest")
        }
        
        
        switch value as! NSString {
            

            
            case "Site":
                return NSImage(named: "NSUser")
            
            case "Person":
                return NSImage(named: "NSUser")
            
            case "Entry":
                    return NSImage(named: "PlexusTest")
                
            case "Structure":
                return NSImage(named: "PlexusImportCSV")
                
            case "Trait":
                return NSImage(named: "PlexusAddChild")

            default:
                return NSImage(named: "PlexusEntry")
        }
        

    }


}
