//
//  Structure.swift
//  Plexus
//
//  Created by matt on 5/13/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData

class Structure: NodeLink {

    @NSManaged var dataset: Dataset
    @NSManaged var entry: NSSet

}
