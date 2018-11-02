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
    
    
    @NSManaged var influencedBy: BNNode
    @NSManaged var influences: BNNode

}
