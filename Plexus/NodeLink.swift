//
//  NodeLink.swift
//  Plexus
//
//  Created by matt on 3/2/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData

class NodeLink: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var bnNode: NSSet
    @NSManaged var scope: NSSet
    

}
