//
//  StructureExtension.swift
//  Plexus
//
//  Created by matt on 5/14/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData


extension Structure {
    func addEntryObject(value:Entry) {
        let items = self.mutableSetValueForKey("entry");
        items.addObject(value)
    }
    
    
    
    func collectTraits(traitsArray:[Trait], traitName:String) -> [Trait] {
        var tmpTraits = traitsArray
        for thisEntry in self.entry{
            let tmpEntry = thisEntry as! Entry
            tmpTraits += tmpEntry.collectTraits(tmpTraits, traitName: traitName)
        }
        return tmpTraits
    }
    
    func collectTraitValues(traitsArray:[String], traitName:String) -> [String] {
        var tmpTraits = traitsArray
        for thisEntry in self.entry{
            let tmpEntry = thisEntry as! Entry
            tmpTraits += tmpEntry.collectTraitValues(tmpTraits, traitName: traitName)
        }
        return tmpTraits
    }
}
