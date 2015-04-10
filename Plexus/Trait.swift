//
//  Trait.swift
//  Plexus
//
//  Created by matt on 10/17/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData

class Trait: NodeLink {


    @NSManaged var traitValue: String
    @NSManaged var entry: Entry

}
