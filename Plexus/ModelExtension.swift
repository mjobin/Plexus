//
//  ModelExtension.swift
//  Plexus
//
//  Created by matt on 11/10/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData

extension Model {
    
    func addChildObject(_ value:Model) {
        let items = self.mutableSetValue(forKey: "children");
        items.add(value)
    }

    func addBNNodeObject(_ value:BNNode) {
        let items = self.mutableSetValue(forKey: "bnnode");
        items.add(value)
    }
    
    
    func copySelf(_ moc: NSManagedObjectContext) -> Model {
        
        let newModel : Model = Model(entity: NSEntityDescription.entity(forEntityName: "Model", in: moc)!, insertInto: moc)
        

        let copyName : String = self.name
        newModel.setValue(copyName, forKey: "name")
        newModel.setValue(self.scope, forKey: "scope")
        
        var tempNodeArray = [BNNode]()
        
        let curNodes  = self.bnnode.allObjects as! [BNNode]
        for curNode : BNNode in curNodes {
            let newNode : BNNode = BNNode(entity: NSEntityDescription.entity(forEntityName: "BNNode", in: moc)!, insertInto: moc)
            
            
            newNode.setValue(curNode.priorDistType, forKey: "priorDistType")
            newNode.setValue(curNode.priorV1, forKey: "priorV1")
            newNode.setValue(curNode.priorV2, forKey: "priorV2")
            newNode.setValue(curNode.nodeLink, forKey: "nodeLink")
            newNode.setValue(curNode.numericData, forKey: "numericData")
            newNode.setValue(curNode.tolerance, forKey: "tolerance")
            newNode.setValue(curNode.cptArray, forKey: "cptArray")
            
        
            
            
            let blankArray = [NSNumber]()
            let blankData = NSKeyedArchiver.archivedData(withRootObject: blankArray)
            newNode.setValue(blankData, forKey: "postCount")
            newNode.setValue(blankData, forKey: "postArray")
            
            
            newNode.setValue(curNode.cptReady, forKey: "cptReady")
            
            
            newNode.setValue(newModel, forKey: "model")
            newModel.addBNNodeObject(newNode)
            
            tempNodeArray.append(newNode)
            
            
            
        }
        
        var infstwod = [[Int]]()
        
        
        //Copy Influences
        for curNode : BNNode in curNodes {
            var infsoned = [Int]()
            let infs : [BNNode] = curNode.influences.array as! [BNNode]
            for inf : BNNode in infs{
                var chk = 0
                for chkNode : BNNode in curNodes {
                    if (chkNode == inf){
                        infsoned.append(chk)
                    }
                    chk += 1
                }
                
            }
            infstwod.append(infsoned)
            
        }
        
        var i = 0
        for infsoned : [Int] in infstwod{
            for thisinf in infsoned{
                tempNodeArray[i].addInfluencesObject(tempNodeArray[thisinf])
                tempNodeArray[thisinf].addInfluencedByObject(tempNodeArray[i])
            }
            i += 1
        }
        
    
        
        return newModel
        //end copyself
    }
  

}
