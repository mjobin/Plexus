//
//  Model.swift
//  Plexus
//
//  Created by matt on 10/17/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData

class Model: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var children: NSOrderedSet
    @NSManaged var dataset: Dataset
    @NSManaged var parent: NSSet

}
