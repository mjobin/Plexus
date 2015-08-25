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
    
}