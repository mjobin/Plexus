//
//  BNNodeExtension.swift
//  Plexus
//
//  Created by matt on 1/9/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

import Foundation
import CoreData


extension BNNode {
    //Down is along the path of an arrow. Up is against the path of a arrow.
    
    
    /**
     Gets BNNodeInters downstream of this BNNode.
     
     - Parameters:
     - sender: Calling object.
     
     - Returns: Array of BNNodeInters.
     */
    func downInters (sender : AnyObject) -> [BNNodeInter] {
        return self.down.array as! [BNNodeInter]
    }
    
    
    /**
     Gets BNNodeInters upstream of this BNNode.
     
     - Parameters:
     - sender: Calling object.
     
     - Returns: Array of BNNodeInters.
     */
    func upInters (sender : AnyObject) -> [BNNodeInter] {
        return self.up.array as! [BNNodeInter]
    }
    
    /**
     Gets BNNodes downstream of this BNNode.
     
     - Parameters:
     - sender: Calling object.
     
     - Returns: Array of BNNodes.
     */
    func downNodes(_ sender:AnyObject) -> [BNNode] {
        var targets = [BNNode]()
//        print("downNodes for \(self.name) downinters \(self.downInters(sender: self).count)")
        for thisDownInter in self.downInters(sender: self) {
//            print("in downNodes \(thisDownInter.up.name) -> \(thisDownInter.down.name)")
            targets.append(thisDownInter.down)
        }
        return targets
    }
    
    /**
     Gets BNNodes downstream of this BNNode.
     
     - Parameters:
     - sender: Calling object.
     
     - Returns: Array of BNNodes.
     */
    func upNodes(_ sender:AnyObject) -> [BNNode] {
        var targets = [BNNode]()
        for thisUpInter in self.upInters(sender: self) {
            targets.append(thisUpInter.up)
        }
        return targets
    }
    
    
    /**
     Gets BNNodeInter between this node and a specified downstream node.
     
     - Parameters:
    - downNode: The downstream node sought.
     
     - Returns: The found node, else nil.
     */
    func getDownInterBetween(downNode:BNNode) -> BNNodeInter? {
        //self is the upstream node, downNode is the node pointed at by the arrow
//        print("get down for \(self.name) downinters \(self.downInters(sender: self).count)")
        
        for thisDownInter in self.downInters(sender: self) {
            if thisDownInter.up == self && thisDownInter.down == downNode {
                return thisDownInter
            }
        }
        return nil
    }
    

    /**
     Gets BNNodeInter between this node and a specified upstream node.
     
     - Parameters:
     - upNode: The upstream node sought.
     
     - Returns: The found node, else nil.
     */
    func getUpInterBetween(upNode:BNNode) -> BNNodeInter? {
        //upNode is the upstream node, self is the node pointed at by the arrow
        for thisUpInter in self.upInters(sender: self) {
            if thisUpInter.down == self && thisUpInter.up == upNode {
                return thisUpInter
            }
        }
        return nil
    }
    
    
    /**
     Checks if a BNNodeInter already exists between this node and a downstream node. Creates one if not.
     
     - Parameters:
     - downNode: The downstream node to be connected.
     - moc: Managed object context where new BNNodeInter should be inserted.
     
     - Returns: The the existing nodeInter if found, or a new nodeInter.
     */
    func addADownObject(downNode:BNNode, moc : NSManagedObjectContext?) -> BNNodeInter { //Add an arrow from self to the other
        if let downInterBetween = self.getDownInterBetween(downNode: downNode) {
            return downInterBetween
        }
        
        let downNodeUpInters = downNode.mutableOrderedSetValue(forKey: "up") //The upstream connections of the downstream node
        let newBNNodeInter: BNNodeInter = BNNodeInter(entity: BNNodeInter.entity(), insertInto: moc)
        downNodeUpInters.add(newBNNodeInter)
        newBNNodeInter.down = downNode
        
        let downInters = self.mutableOrderedSetValue(forKey: "down") //The downstream connections of this node
        downInters.add(newBNNodeInter)
        newBNNodeInter.up = self
        
        return newBNNodeInter
    }
    
    
    /**
     Checks if a BNNodeInter already exists between this node and an upstream node. Creates one if not.
     
     - Parameters:
     - upNode: The upstream node to be connected.
     - moc: Managed object context where new BNNodeInter should be inserted.
     
     - Returns: The the existing nodeInter if found, or a new nodeInter.
     */
    func addAnUpObject(upNode:BNNode, moc : NSManagedObjectContext?) -> BNNodeInter { //Add an arrow from other to self
        if let upInterBetween = self.getUpInterBetween(upNode: upNode) {
            return upInterBetween
        }

        //if no such node exists, create it
        let upNodeDownInters = upNode.mutableOrderedSetValue(forKey: "down") //The downstream connections of the upstream node
        let newBNNodeInter: BNNodeInter = BNNodeInter(entity: BNNodeInter.entity(), insertInto: moc)
        upNodeDownInters.add(newBNNodeInter)
        newBNNodeInter.up = upNode
        
        let upInters = self.mutableOrderedSetValue(forKey: "up") //The upstream connections of this node
        upInters.add(newBNNodeInter)
        newBNNodeInter.down = self
        
        return newBNNodeInter
    }
    
    
    /**
     Removes the arrow between this BNNode and a downstream BNNode.
     
     - Parameters:
     - downNode: The downstream node to be disconnected.
     - moc: Managed object context where new BNNodeInter should be.
     
     */
    func removeADownObject(downNode:BNNode, moc : NSManagedObjectContext?) {
        if let theBNNodeInter = self.getDownInterBetween(downNode: downNode){
            let downInters = self.mutableOrderedSetValue(forKey: "down")
            downInters.remove(theBNNodeInter)
            
            let downNodeUpInters = downNode.mutableOrderedSetValue(forKey: "up");
            downNodeUpInters.remove(theBNNodeInter)
            
            moc?.delete(theBNNodeInter)
        }
    }
    
    
    /**
     Removes the arrow between this BNNode and an upstream BNNode.
     
     - Parameters:
     - upNode: The upstream node to be disconnected.
     - moc: Managed object context where new BNNodeInter should be.
     
     */
    func removeAnUpObject(upNode:BNNode, moc : NSManagedObjectContext?) {
        if let theBNNodeInter = self.getUpInterBetween(upNode: upNode){
            let upInters = self.mutableOrderedSetValue(forKey: "up")
            upInters.remove(theBNNodeInter)
            
            let upNodeDownInters = upNode.mutableOrderedSetValue(forKey: "down");
            upNodeDownInters.remove(theBNNodeInter)
            
            moc?.delete(theBNNodeInter)
        }
        
    }
    
    
    /**
     Ensures a Node is not connected to other nodes in the Model.
     
     - Parameter moc: Managed Object Context.
     
   */
    func removeSelfFromNeighbors(moc : NSManagedObjectContext?){
        for upNode in self.upNodes(self){
            upNode.removeADownObject(downNode: self, moc: moc)
        }
        for downNode in self.downNodes(self){
            downNode.removeAnUpObject(upNode: self, moc: moc)
        }
    }

    /**
     Checks to ensure nodes in a model are a Directed Acyclic Graph.
     
     - Parameters:
     - nodeStack: Array of BNNodes to be checked

     - Returns: Boolean telling whether a cycle has been found (which means the nodes do not form a DAG).
     */
    func DFTcyclechk(_ nodeStack:[BNNode]) -> Bool {
        var tmpnodeStack = nodeStack
        for chknode in tmpnodeStack {
            var chkcount = 0
            for chkchknode in tmpnodeStack{
                if(chknode == chkchknode){
                    chkcount += 1
                }
            }
            if(chkcount > 1) {
                return true
            }
        }

        for thisDownNode in self.downNodes(self) {
            tmpnodeStack.append(thisDownNode)
            if(thisDownNode.DFTcyclechk(tmpnodeStack) == true){
                return true;
            }
        }
        return false;
    }
    
    
    /**
     Calculates a Conditional Probability Table for this BNNode.
     
     - Parameter fake: If true, ignore data and calculate by rolling off BNInterNode.
     - Parameter thisMOC: Managed object context. May not be nil.
     
     - Returns: 2 if successfully completed.
     */
    func CPT(fake:Bool, thisMOC : NSManagedObjectContext) -> Int {
//        let start = DispatchTime.now()
        print ("\n**********START CPT for \(self.name)")
        

        let curModel : Model = self.model
        let theEntries = curModel.entry
        
        var ifthens = [Float]()
        
        let theUpNodes = self.upNodes(self)
        let nUp = theUpNodes.count
        if(nUp < 1) { //since 2^0 is 1
            self.cptArray = [Float](repeating: -1.0, count: 1)
            return 2
        }
        else {
            for thisUpNode in theUpNodes {
                //Which of the entries contain a trait matching the name of the node trait
                //get the interbetwene or make if it does nto exist
                if let curUpNodeInter = self.getUpInterBetween(upNode: thisUpNode){
                    

                    
                    if fake {
                        ifthens.append(curUpNodeInter.ifthen.floatValue)
                    }
                    else{

                    let request = NSFetchRequest<Trait>(entityName: "Trait")
                    let predicate = NSPredicate(format: "entry IN %@ && name == %@", argumentArray: [theEntries, thisUpNode.name])
                    request.predicate = predicate
                    
                    do {
                        let allCount = try thisMOC.count(for: request)
                        
                        if allCount < 1 {
                            ifthens.append(0.5)
                            curUpNodeInter.ifthen = 0.5
                        }
                        else {
                            let matchRequest = NSFetchRequest<Trait>(entityName: "Trait")
                            var matchPredicate = NSPredicate()
                            var chkNumeric = true
                            if thisUpNode.numericData {
                                if Double(thisUpNode.value) == nil {
                                    chkNumeric = false
                                }
                                
                            }
                            
                            //If data is numeric, need to calculate based on tolerance value.
                            if thisUpNode.numericData && chkNumeric == true {
                                let calcNumVal = Double(thisUpNode.value)
                                let tol = thisUpNode.tolerance as! Double
                                let lowT = calcNumVal! * (1.0 - (tol/2.0))
                                let highT = calcNumVal! * (1.0 + (tol/2.0))
                                
                                matchPredicate = NSPredicate(format: "entry IN %@ && name == %@ && value >= %f && value <= %f", argumentArray: [theEntries, thisUpNode.name, lowT, highT])
                            }
                            else{
                                matchPredicate = NSPredicate(format: "entry IN %@ && name == %@ && value == %@", argumentArray: [theEntries, thisUpNode.name, thisUpNode.value])
                            }
                            matchRequest.predicate = matchPredicate
                            do {
                                
                                let matchCount = try thisMOC.count(for: matchRequest)
                                ifthens.append(Float(matchCount) / Float(allCount))
                                curUpNodeInter.ifthen = NSNumber.init(value: (Float(matchCount) / Float(allCount)))
                                
                            } catch {
                                print("Failed")
                            }
                            
                        }
                        
                    } catch {
                        
                        print("Failed")
                    }
                    
                }
                    
                }//END if let curNodeInter
                
                
            } // END for thisInfluencedBy in theInfluencedBy
            
            
        } //END else
        
        
        
        
        let cptarraysize = Int(pow(2.0,Double(nUp)))
        var cptarray = [Float](repeating: 0.0, count: cptarraysize)
        
        for i in 0..<cptarraysize {
            let poststr = String(i, radix: 2)
            
            var prestr = String()
            for _ in poststr.count..<nUp {
                prestr += "0"
            }
            let bin = prestr + poststr
            
            var compound = [Float]()
            
            var tfc = 0
            for tf in bin {
                if tf == "1" {
                    compound.append(ifthens[tfc])
                }
                else {
                    compound.append(1.0-ifthens[tfc])
                }
                tfc += 1
            }
            cptarray[i] = (compound.reduce(1,*))
            
        }
        
        self.cptArray = cptarray
        
        return 2
    }
    
    /**
     Calculates then gets Conditional Probability Table for this BNNode.
     
     - Parameters:
     - sender:
     - mocChanged: Whether the Managed Object Context has changed.
     
     - Returns: CPT as an array.
     */
    func getCPTArray(_ sender:AnyObject, mocChanged:Bool, fake : Bool,  thisMOC : NSManagedObjectContext) -> [cl_float] {
        //FIXME only change this back if you feel really safe about it
        _ = self.CPT(fake: fake, thisMOC: thisMOC)
        
        //        print ("getCPTArray \(self.name) \(self.cptReady)")
        //        if mocChanged == true || self.cptReady != 2 {
        //           _ = self.CPT()
        //        }
        return self.cptArray
    }
    
} //END BNNode extension
