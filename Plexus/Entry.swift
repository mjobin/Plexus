//
//  Entry.swift
//  Plexus
//
//  Created by matt on 10/17/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData


class Entry: NodeLink  {

    @NSManaged var children: NSSet
    @NSManaged var dataset: Dataset
    @NSManaged var parent: NSSet
    @NSManaged var trait: NSSet
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var structure: NSSet

}
