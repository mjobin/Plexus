//
//  EntryExtension.swift
//  Plexus
//
//  Created by matt on 11/5/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData

extension Entry {
    func addAChildObject(_ value:Entry) {
        let items = self.mutableSetValue(forKey: "children");
        items.add(value)
    }
    
    func addATraitObject(_ value:Trait) {
        let items = self.mutableSetValue(forKey: "trait");
        items.add(value)
    }
    
    func addAModelObject(_ value:Model) {
        let items = self.mutableSetValue(forKey: "model");
        items.add(value)
    }

    func removeAModelObject(_ value:Model) {
        let items = self.mutableSetValue(forKey: "model");
        items.remove(value)
    }
    
    
 
        
  
    
}
