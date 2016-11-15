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
    func addChildObject(_ value:Entry) {
        let items = self.mutableSetValue(forKey: "children");
        items.add(value)
    }
    
    func addTraitObject(_ value:Trait) {
        let items = self.mutableSetValue(forKey: "trait");
        items.add(value)
    }
    
    func addStructureObject(_ value:Structure) {
        let items = self.mutableSetValue(forKey: "structure");
        items.add(value)
    }
    
    
    func collectChildren(_ entriesArray:[Entry]) -> [Entry] {
        var tmpEntries = entriesArray        
        for childEntry in self.children {
            tmpEntries.append(childEntry as! Entry)
            (childEntry as AnyObject).collectChildren(tmpEntries)
        }
        return tmpEntries
    }
    
    func collectTraits(_ traitsArray:[Trait], traitName:String) -> [Trait] {
        var tmpTraits = traitsArray
        
        
        for thisTrait in self.trait{
            let tmpTrait = thisTrait as! Trait
            if(tmpTrait.name == traitName){
                tmpTraits.append(tmpTrait)
            }
            
        }
        
        for thisChild in self.children {
            (thisChild as AnyObject).collectTraits(tmpTraits, traitName: traitName)
        }
        return tmpTraits
    }
    
    func collectTraitValues(_ traitsArray:[String], traitName:String) -> [String] {
        var tmpTraits = traitsArray
        

        for thisTrait in self.trait{
            let tmpTrait = thisTrait as! Trait
            if(tmpTrait.name == traitName){
                tmpTraits.append(tmpTrait.traitValue)
            }
            
        }
        
        
        
        for thisChild in self.children {
            (thisChild as AnyObject).collectTraitValues(tmpTraits, traitName: traitName)
        }
       return tmpTraits
    }
    
}
