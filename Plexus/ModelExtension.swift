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
    
    func addAChildObject(_ value:Model) {
        let items = self.mutableSetValue(forKey: "children");
        items.add(value)
    }

    func addABNNodeObject(_ value:BNNode) {
        let items = self.mutableSetValue(forKey: "bnnode");
        items.add(value)
    }
    
    func addABNNodeInterObject(_ value:BNNodeInter) {
        let items = self.mutableSetValue(forKey: "bnnodeinter");
        items.add(value)
    }
    
    func addAnEntryObject(_ value:Entry) {
        let items = self.mutableSetValue(forKey: "entry");
        items.add(value)
    }
    
    func removeAnEntryObject(_ value:Entry) {
        let items = self.mutableOrderedSetValue(forKey: "entry");
        items.remove(value)
    }
    
    
    func copySelf(moc: NSManagedObjectContext?) -> Model {
        
//        let newModel : Model = Model(entity: NSEntityDescription.entity(forEntityName: "Model", in: moc)!, insertInto: nil)
        
        let newModel : Model = Model(entity: Model.entity(), insertInto: moc)

        
        newModel.setValue(burnins, forKey: "burnins")
        newModel.setValue(false, forKey: "complete")
        newModel.setValue(Date(), forKey: "dateCreated")
        newModel.setValue(Date(), forKey: "dateModded")
        newModel.setValue(self.hillchains, forKey: "hillchains")
        newModel.setValue(self.name, forKey: "name")
        newModel.setValue(self.runsper, forKey: "runsper")
        newModel.setValue(self.runstarts, forKey: "runstarts")
        newModel.setValue(self.runstot, forKey: "runstot")
        newModel.setValue(0, forKey: "score")
        newModel.setValue(self.thin, forKey: "thin")

        
        let theEntries  = self.entry
        for theEntry in theEntries {
            let curEntry = theEntry as! Entry
            newModel.addAnEntryObject(curEntry)
        }
        
        var tempNodeArray = [BNNode]()
        let curNodes  = self.bnnode.allObjects as! [BNNode]
        for curNode : BNNode in curNodes {
            let newNode : BNNode = BNNode(entity: BNNode.entity(), insertInto: moc)
            
            
            newNode.setValue(curNode.cptArray, forKey: "cptArray")
            newNode.setValue(curNode.cptReady, forKey: "cptReady")
            newNode.setValue(curNode.name, forKey: "name")
            newNode.setValue(curNode.numericData, forKey: "numericData")
            newNode.setValue(curNode.priorDistType, forKey: "priorDistType")
            newNode.setValue(curNode.priorDistType, forKey: "priorDistType")
            newNode.setValue(curNode.priorV1, forKey: "priorV1")
            newNode.setValue(curNode.priorV2, forKey: "priorV2")
            newNode.setValue(curNode.savedX, forKey: "savedX")
            newNode.setValue(curNode.savedY, forKey: "savedY")
            newNode.setValue(curNode.tolerance, forKey: "tolerance")
            newNode.setValue(curNode.value, forKey: "value")
            
        
            
            
            let blankCount = [Int]()
            let blankArray = [Float]()
            newNode.postCount = blankCount
            newNode.postArray = blankArray
            newNode.priorCount = blankCount
            newNode.priorArray = blankArray
            
            
            
            
            
            newNode.setValue(newModel, forKey: "model")
            newModel.addABNNodeObject(newNode)
            
            tempNodeArray.append(newNode)
            
            
            
        }
        
        var infstwod = [[Int]]()
        
        
        //Copy Influences
        for curNode : BNNode in curNodes {
            var infsoned = [Int]()
            let infs : [BNNode] = curNode.infs(self)
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
                let newInter = tempNodeArray[i].addAnInfluencesObject(infBy: tempNodeArray[thisinf], moc : moc)
                self.addABNNodeInterObject(newInter)
                newInter.model = self
                _ = tempNodeArray[thisinf].addAnInfluencedByObject(inf: tempNodeArray[i], moc : moc)
            }
            i += 1
        }
        
    
        
        return newModel
        //end copyself
    }
  

}
