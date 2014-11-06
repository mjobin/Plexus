//
//  Plexus.swift
//  Plexus
//
//  Created by matt on 10/21/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData

class Dataset: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var locked: NSNumber
    @NSManaged var dateCreated: NSDate
    @NSManaged var dateModified: NSDate
    @NSManaged var entry: NSSet
    @NSManaged var model: NSSet

}
