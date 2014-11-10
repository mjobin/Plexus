//
//  Entry.swift
//  Plexus
//
//  Created by matt on 10/17/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData


class Entry: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var children: NSSet
    @NSManaged var dataset: Dataset
    @NSManaged var parent: NSSet
    @NSManaged var trait: NSSet

}