//
//  BNNodeInterExtension.swift
//  Plexus
//
//  Created by matt on 9/21/18.
//  Copyright © 2018  Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData


extension BNNodeInter {
    
    
    func isInfNode(_ sender:AnyObject) -> Bool {
        for bnnode in self.model.bnnode{
            let curbnnode = bnnode as! BNNode
            if self.influences == curbnnode {
                return true
            }
            
        }
        return false
    }
    
    func isInfByNode(_ sender:AnyObject) -> Bool {
        for bnnode in self.model.bnnode{
            let curbnnode = bnnode as! BNNode
            if self.influencedBy == curbnnode {
                return true
            }
            
        }
        return false
    }
    
    

}
