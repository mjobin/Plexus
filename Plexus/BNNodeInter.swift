//
//  BNNodeInter.swift
//  Plexus
//
//  Created by matt on 9/21/18.
//  Copyright © 2018 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData

class BNNodeInter: NSManagedObject {

    @NSManaged var ifthen: NSNumber
    @NSManaged var up: BNNode // Against direction of arrow
    @NSManaged var down: BNNode // Along direction of arrow

}
