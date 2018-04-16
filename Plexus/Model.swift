//
//  Model.swift
//  Plexus
//
//  Created by matt on 10/17/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData

class Model: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var children: NSOrderedSet
    @NSManaged var parent: NSSet
    @NSManaged var bnnode: NSSet
    @NSManaged var burnins: NSNumber
    @NSManaged var runsper: NSNumber
    @NSManaged var runstot: NSNumber
    @NSManaged var complete: Bool
    @NSManaged var dateModded: Date
    @NSManaged var dateCreated: Date
    @NSManaged var scope: NodeLink
    @NSManaged var score: NSNumber
    @NSManaged var runstarts: NSNumber
    @NSManaged var hillchains: NSNumber
    @NSManaged var thin: NSNumber
    
    

}
