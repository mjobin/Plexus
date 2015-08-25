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
    
}
