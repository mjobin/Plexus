//
//  ModelExtension.swift
//  Plexus
//
//  Created by matt on 11/10/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData

extension Model {
    
    func addChildObject(value:Model) {
        var items = self.mutableSetValueForKey("children");
        items.addObject(value)
    }

    func addBNNodeObject(value:BNNode) {
        var items = self.mutableSetValueForKey("bnnode");
        items.addObject(value)
    }

}