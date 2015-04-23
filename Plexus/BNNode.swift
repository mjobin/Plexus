//
//  BNNode.swift
//  Plexus
//
//  Created by matt on 11/10/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData

class BNNode: Node {

   
    @NSManaged var priorDistType: NSNumber
    @NSManaged var priorV1: NSNumber
    @NSManaged var priorV2: NSNumber
    @NSManaged var model: Model
    @NSManaged var nodeLink: NodeLink
    @NSManaged var influences: NSSet
    @NSManaged var influencedBy: NSSet
    @NSManaged var postCount: NSData?
    @NSManaged var postArray: NSData?
    @NSManaged var dataScope: NSNumber
    @NSManaged var dataOp: NSNumber
    @NSManaged var dataName: String
    @NSManaged var numericData: NSNumber
}
