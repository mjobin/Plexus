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
        var items = self.mutableSetValueForKey("children");
        items.addObject(value)
    }
    
    func addTraitObject(value:Trait) {
        var items = self.mutableSetValueForKey("trait");
        items.addObject(value)
    }
    
}