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

   
    @NSManaged var cptArray: [Float]
    @NSManaged var cptFreezeArray: [Float]
    @NSManaged var cptReady: NSNumber
    @NSManaged var hidden: Bool
    @NSManaged var name: String
    @NSManaged var numericData: Bool
    @NSManaged var postArray: [Float]
    @NSManaged var postCount: [Int]
    @NSManaged var postETLow: NSNumber
    @NSManaged var postETHigh: NSNumber
    @NSManaged var postHPDLow: NSNumber
    @NSManaged var postHPDHigh: NSNumber
    @NSManaged var postMean: NSNumber
    @NSManaged var postSSD: NSNumber
    @NSManaged var priorArray: [Float]
    @NSManaged var priorCount: [Int]
    @NSManaged var priorDistType: NSNumber
    @NSManaged var priorV1: NSNumber
    @NSManaged var priorV2: NSNumber
    @NSManaged var savedX: NSNumber
    @NSManaged var savedY: NSNumber
    @NSManaged var tolerance: NSNumber
    @NSManaged var value: String
    
    
    
    @NSManaged var influencedBy: NSOrderedSet
    @NSManaged var influences: NSOrderedSet
    @NSManaged var model: Model
    
}
