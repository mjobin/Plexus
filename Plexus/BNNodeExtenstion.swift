//
//  BNNodeExtenstion.swift
//  Plexus
//
//  Created by matt on 1/9/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData



extension BNNode {
    
    func addInfluencesObject(value:BNNode) {
        var influences = self.mutableSetValueForKey("influences");
        influences.addObject(value)
    }
    
    func addInfluencedByObject(value:BNNode) {
        var influencedBy = self.mutableSetValueForKey("influencedBy");
        influencedBy.addObject(value)
    }
    
}