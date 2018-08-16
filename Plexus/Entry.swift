//
//  Entry.swift
//  Plexus
//
//  Created by matt on 10/17/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData


class Entry: NSManagedObject  {

    @NSManaged var name: String
    @NSManaged var notes: Data?

    @NSManaged var trait: NSSet
    @NSManaged var model: NSSet
    
}
