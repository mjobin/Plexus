//
//  StructureExtension.swift
//  Plexus
//
//  Created by matt on 5/14/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData


extension Structure {
    func addEntryObject(_ value:Entry) {
        let items = self.mutableSetValue(forKey: "entry");
        items.add(value)
    }
    
    
    
    func collectTraits(_ traitsArray:[Trait], traitName:String) -> [Trait] {
        var tmpTraits = traitsArray
        for thisEntry in self.entry{
            let tmpEntry = thisEntry as! Entry
            tmpTraits += tmpEntry.collectTraits(tmpTraits, traitName: traitName)
        }
        return tmpTraits
    }
    
    func collectvalues(_ traitsArray:[String], traitName:String) -> [String] {
        var tmpTraits = traitsArray
        for thisEntry in self.entry{
            let tmpEntry = thisEntry as! Entry
            tmpTraits += tmpEntry.collectvalues(tmpTraits, traitName: traitName)
        }
        return tmpTraits
    }
}
