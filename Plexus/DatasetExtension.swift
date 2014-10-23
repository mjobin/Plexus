//
//  DatasetExtension.swift
//  Plexus
//
//  Created by matt on 10/21/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData


extension Dataset {
    func addEntryObject(value:Entry) {
        var items = self.mutableSetValueForKey("entry");
        items.addObject(value)
    }
    
    func addModelObject(value:Model) {
        var items = self.mutableSetValueForKey("model");
        items.addObject(value)
    }
}