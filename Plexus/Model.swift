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
    @NSManaged var bnnode: NSSet
    @NSManaged var burnins: NSNumber
    @NSManaged var runsper: NSNumber
    @NSManaged var runstot: NSNumber
    @NSManaged var complete: NSNumber
    @NSManaged var dateModded: NSDate
    @NSManaged var dateCreated: NSDate
    @NSManaged var scope: NodeLink
    
    

}
