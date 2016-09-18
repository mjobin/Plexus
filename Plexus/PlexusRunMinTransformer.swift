//
//  PlexusRunMinTransformer.swift
//  Plexus
//
//  Created by matt on 5/4/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusRunMinTransformer: ValueTransformer {
    
    
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
        return (outVal.intValue+1)
        }
        
        
        

    }


}
