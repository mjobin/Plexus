//
//  PlexusRunMaxTranformer.swift
//  Plexus
//
//  Created by matt on 5/6/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

import Cocoa

class PlexusRunMaxTransformer: ValueTransformer {
    
    
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override func  transformedValue(_ value: Any?) -> Any? {
        
        
        if(value == nil){
            return NSNumber(value: 1 as Int32)
        }
        
        
        
        let outVal : NSNumber = value as! NSNumber
        
        if(outVal.intValue < 1) {
            return 1
        }
            
            
        else {
            return (outVal.intValue-1)
        }
        
        
        
        
    }
    
    
}
