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
    
    
    func addAnEntryObject(_ value:Entry) {
        let items = self.mutableSetValue(forKey: "entry");
        items.add(value)
    }
    
    func removeAnEntryObject(_ value:Entry) {
        let items = self.mutableSetValue(forKey: "entry");
        items.remove(value)
    }
    
    func removeABNNodeObject(_ value:BNNode) {
        let items = self.mutableSetValue(forKey: "bnnode");
        items.remove(value)
    }
    
    
    func copySelf(moc: NSManagedObjectContext?, withEntries: Bool) -> Model {
        
        
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


        if withEntries == true {
            let theEntries  = self.entry
            for theEntry in theEntries {
                let curEntry = theEntry as! Entry
                newModel.addAnEntryObject(curEntry)
                curEntry.addAModelObject(newModel)
            }
        }

        
        var tempNodeArray = [BNNode]()
        var curNodeArray = [BNNode]()
        let curNodes  = self.bnnode.allObjects as! [BNNode]
        for curNode : BNNode in curNodes {
            let newNode : BNNode = BNNode(entity: BNNode.entity(), insertInto: moc)
            
            
            newNode.setValue(curNode.cptArray, forKey: "cptArray")
            newNode.setValue(curNode.cptReady, forKey: "cptReady")
            newNode.setValue(curNode.hidden, forKey: "hidden")
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
            curNodeArray.append(curNode)
            
            
            
        }
        
        
        var infstwod = [[Int]]()
        
        //Copy Influences
        for curNode : BNNode in curNodes {
            var infsoned = [Int]()
            let downNodes = curNode.downNodes(self)
            for downNode in downNodes {
                var chk = 0
                for chkNode : BNNode in curNodes {
                    if (chkNode == downNode){
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
                let newInter = tempNodeArray[i].addADownObject(downNode: tempNodeArray[thisinf], moc: moc)
                if let curInter = curNodeArray[i].getDownInterBetween(downNode: curNodeArray[thisinf]){
                    newInter.ifthen = curInter.ifthen
                }

            }
            i += 1
        }
        

    
        
        return newModel
        //end copyself
    }
    
    func genRandData(moc: NSManagedObjectContext?) {
        
        //Remove existing Entries
        for theEntry in self.entry.allObjects as! [Entry] {
            self.removeAnEntryObject(theEntry)
        }
        
        let allNodes = self.bnnode.allObjects as! [BNNode]
        
        var nodecounter = 1
        //Prepare the independnt nodes
        for thisNode in allNodes {
            thisNode.name = String(nodecounter)
            thisNode.value = "yes"
            let upNodes = thisNode.upNodes(self)
            if upNodes.count < 1 { //Independent nodes need to
                
                thisNode.priorDistType =  NSNumber.init(integerLiteral: Int.random(in: 0 ... 4))
                thisNode.priorV1 = NSNumber.init(floatLiteral: Double.random(in: 0.0 ... 1.0))
                thisNode.priorV2 = NSNumber.init(floatLiteral: Double.random(in: 0.0 ... 1.0))
                
            }
            else {
                for upNode in upNodes {
                    
                    if let thisInter = thisNode.getUpInterBetween(upNode: upNode){
                        thisInter.ifthen = NSNumber.init(floatLiteral: Double.random(in: 0.0 ... 1.0))
                    }
                }
            }
            
            nodecounter += 1
        }
        

        
        
        
        
    }
  

}
