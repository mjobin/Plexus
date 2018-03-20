//
//  BNNode.swift
//  Plexus
//
//  Created by matt on 11/10/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData

class BNNode: NSManagedObject {

   
    @NSManaged var priorDistType: NSNumber
    @NSManaged var priorV1: NSNumber
    @NSManaged var priorV2: NSNumber
    @NSManaged var model: Model
    @NSManaged var nodeLink: NodeLink
    @NSManaged var influences: NSOrderedSet
    @NSManaged var influencedBy: NSOrderedSet
    @NSManaged var priorCount: Data?
    @NSManaged var priorArray: Data?
    @NSManaged var postCount: Data?
    @NSManaged var postArray: Data?
    @NSManaged var numericData: NSNumber

    @NSManaged var tolerance: NSNumber
    @NSManaged var cptArray: Data?
    @NSManaged var postMean: NSNumber
    @NSManaged var postSSD: NSNumber
    @NSManaged var postETLow: NSNumber
    @NSManaged var postETHigh: NSNumber
    @NSManaged var postHPDLow: NSNumber
    @NSManaged var postHPDHigh: NSNumber
    @NSManaged var cptReady: NSNumber
    @NSManaged var savedX: NSNumber
    @NSManaged var savedY: NSNumber

}
