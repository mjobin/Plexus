//
//  EntryExtension.swift
//  Plexus
//
//  Created by matt on 11/5/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData

extension Entry {
    func addChildObject(value:Entry) {
        let items = self.mutableSetValueForKey("children");
        items.addObject(value)
    }
    
    func addTraitObject(value:Trait) {
        let items = self.mutableSetValueForKey("trait");
        items.addObject(value)
    }
    
    func addStructureObject(value:Structure) {
        let items = self.mutableSetValueForKey("structure");
        items.addObject(value)
    }
    
    
    func collectChildren(entriesArray:[Entry]) -> [Entry] {
        var tmpEntries = entriesArray
        
        for childEntry in self.children {
            tmpEntries.append(childEntry as! Entry)
            childEntry.collectChildren(tmpEntries)
        }
        return tmpEntries
    }
    
    func collectTraits(traitsArray:[Trait], traitName:String) -> [Trait] {
        var tmpTraits = traitsArray
        
        
        for thisTrait in self.trait{
            let tmpTrait = thisTrait as! Trait
            if(tmpTrait.name == traitName){
                tmpTraits.append(tmpTrait)
            }
            
        }
        
        for thisChild in self.children {
            thisChild.collectTraits(tmpTraits, traitName: traitName)
        }
        return tmpTraits
    }
    
    func collectTraitValues(traitsArray:[String], traitName:String) -> [String] {
        var tmpTraits = traitsArray
        

        for thisTrait in self.trait{
            let tmpTrait = thisTrait as! Trait
            if(tmpTrait.name == traitName){
                tmpTraits.append(tmpTrait.traitValue)
            }
            
        }
        
        
        
        for thisChild in self.children {
            thisChild.collectTraitValues(tmpTraits, traitName: traitName)
        }
       return tmpTraits
    }
    
}