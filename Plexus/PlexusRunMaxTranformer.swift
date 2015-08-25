//
//  PlexusRunMaxTranformer.swift
//  Plexus
//
//  Created by matt on 5/6/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusRunMaxTransformer: NSValueTransformer {
    
    
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override func  transformedValue(value: AnyObject?) -> AnyObject? {
        
        
        if(value == nil){
            return NSNumber(int: 1)
        }
        
        
        
        let outVal : NSNumber = value as! NSNumber
        
        if(outVal.integerValue < 1) {
            return 1
        }
            
            
        else {
            return (outVal.integerValue-1)
        }
        
        
        
        
    }
    
    
}
