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

    @NSManaged var burnins: NSNumber
    @NSManaged var complete: Bool
    @NSManaged var dateCreated: Date
    @NSManaged var dateModded: Date
    @NSManaged var hillchains: NSNumber
    @NSManaged var name: String
    @NSManaged var runlog: String
    @NSManaged var chain: NSNumber
    @NSManaged var runstarts: NSNumber
    @NSManaged var runstot: NSNumber
    @NSManaged var score: NSNumber
    @NSManaged var thin: NSNumber
    

    @NSManaged var bnnode: NSSet
    @NSManaged var children: NSOrderedSet
    @NSManaged var entry: NSSet
    @NSManaged var parent: NSSet
   

}
