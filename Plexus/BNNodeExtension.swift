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
    
    
    
    func getInfInterBetween(infByNode:BNNode, moc : NSManagedObjectContext?) -> BNNodeInter? {
        
        let influencedByInter = infByNode.mutableOrderedSetValue(forKey: "influencedBy")
        for thisinfByInter in influencedByInter {
            let curinfByInter = thisinfByInter as! BNNodeInter
            
            if curinfByInter.influencedBy == self {
                return curinfByInter
            }
        }
        
        return nil
    }
    

    
    
    
    func getInfByInterBetween(infNode:BNNode, moc : NSManagedObjectContext?) -> BNNodeInter? {
        //infNode is the influencing node, self is the influencedBy
        let influencesInter = infNode.mutableOrderedSetValue(forKey: "influences")
        for thisinfInter in influencesInter {
            let curinfInter = thisinfInter as! BNNodeInter
            
            if curinfInter.influences == self {
                
                return curinfInter
            }
        }
        
        return nil
        
    }
    
    
    
    func addAnInfluencesObject(infBy:BNNode, moc : NSManagedObjectContext?) -> BNNodeInter { //Add an arrow from self to the other
        
        if let infInterBetween = self.getInfInterBetween(infByNode: infBy, moc: moc ?? nil) {
            return infInterBetween
        }
        
        //if no such node exists, create it
        let influencedByInter = infBy.mutableOrderedSetValue(forKey: "influencedBy")
        let newBNNodeInter: BNNodeInter = BNNodeInter(entity: BNNodeInter.entity(), insertInto: moc)
        influencedByInter.add(newBNNodeInter)
        newBNNodeInter.influences = infBy
        
        let influencesInter = self.mutableOrderedSetValue(forKey: "influences")
        influencesInter.add(newBNNodeInter)
        newBNNodeInter.influencedBy = self
        
        return newBNNodeInter
        
    }
    
    
    func addAnInfluencedByObject(inf:BNNode, moc : NSManagedObjectContext?) -> BNNodeInter { //Add an arrow from other to self
        if let infbyinter = self.getInfByInterBetween(infNode: inf, moc:  moc ?? nil) {
            _ = self.CPT() //once added, start calculating CPT right away
            return infbyinter
        }

        //if no such node exists, create it
        let influencesInter = inf.mutableOrderedSetValue(forKey: "influences")
        let newBNNodeInter: BNNodeInter = BNNodeInter(entity: BNNodeInter.entity(), insertInto: moc)
        influencesInter.add(newBNNodeInter)
        newBNNodeInter.influencedBy = inf
        
        let influencedByInter = self.mutableOrderedSetValue(forKey: "influencedBy")
        influencedByInter.add(newBNNodeInter)
        newBNNodeInter.influences = self
        
        return newBNNodeInter
        
        
        
    }
    
    
    
    func removeAnInfluencesObject(_ value:BNNode, moc : NSManagedObjectContext?) {
        let influencesInter = self.mutableOrderedSetValue(forKey: "influences");
        
        var theBNNodeInter : BNNodeInter!
        for thisinfInter in influencesInter {
            let curinfInter = thisinfInter as! BNNodeInter
            if curinfInter.influences == value{
                theBNNodeInter = curinfInter
            }
        }
        
        if theBNNodeInter == nil { //Should not happen
            return
        }
        
        influencesInter.remove(theBNNodeInter)
        let influenceByInter = value.mutableOrderedSetValue(forKey: "influencedBy");
        
        influenceByInter.remove(theBNNodeInter)
        
        moc?.delete(theBNNodeInter)
        
    }
    
    
    
    func removeAnInfluencedByObject(_ value:BNNode, moc : NSManagedObjectContext?) {
        let influencedByInter = self.mutableOrderedSetValue(forKey: "influencedBy");
        
        var theBNNodeInter : BNNodeInter!
        for thisinfInter in influencedByInter {
            let curinfInter = thisinfInter as! BNNodeInter
            if curinfInter.influencedBy == self {
                theBNNodeInter = curinfInter
            }
        }
        
        if theBNNodeInter == nil { //Should not happen
            return
        }
        
        influencedByInter.remove(theBNNodeInter)
        let influencesInter = self.mutableOrderedSetValue(forKey: "influences");
        
        influencesInter.remove(theBNNodeInter)
        
        moc?.delete(theBNNodeInter)
        
    }
    
    func removeAnInfluencedByObject(_ value:BNNode) {
        let influencedBy = self.mutableOrderedSetValue(forKey: "influencedBy");
        influencedBy.remove(value)
    }
    
    
    
    
    func freqForCPT(_ sender:AnyObject) -> cl_float {
        
        var lidum : CLong = 1
        
        var chk = 0
        var pVal : cl_float = -999
        
        while pVal < 0 || pVal > 1 {
            
            switch (priorDistType) {
            case 0://prior/expert
                pVal = cl_float(priorV1)
                // return cl_float(priorV1)
                
            case 1://uniform
                let r = Double(arc4random())/Double(UInt32.max)
                
                // println("uniform \(u)")
                pVal = cl_float((r*(priorV2.doubleValue - priorV1.doubleValue)) + priorV1.doubleValue)
                //return cl_float((r*(priorV2.doubleValue - priorV1.doubleValue)) + priorV1.doubleValue)
                
            case 2: //gaussian
                
                let gd = cl_float(gasdev(&lidum))
                let gdv = cl_float(priorV2) * gd + cl_float(priorV1)
                //  println("gaussdev \(gd) \(gdv)")
                pVal = gdv
            //return gdv
            case 3: //beta
                let bd = cl_float(beta_dev(priorV1.doubleValue, priorV2.doubleValue))
                //  println("betadev \(bd)")
                pVal = bd
            //return bd
            case 4: //gamma
                let gd = cl_float(gamma_dev(priorV1.doubleValue)/priorV2.doubleValue)
                //  println("gammadev \(gd)")
                pVal = gd
                //                return gd
                
                
                
            default:
                return cl_float.nan //uh oh
            }
            
            
            chk += 1
            if(chk > 1000){
                return cl_float.nan
            }
        }
        
        return pVal
        
        
    }
    
    
    func DFTcyclechk(_ nodeStack:[BNNode]) -> Bool {
        
        // print("checking \(self.node.name)")
        var tmpnodeStack = nodeStack
        
        //check if any two in the array are the same, if so return true
        for chknode in tmpnodeStack {
            
            var chkcount = 0
            for chkchknode in tmpnodeStack{
                if(chknode == chkchknode){
                    chkcount += 1
                }
            }
            //print("chknode \(chknode.name) has \(chkcount) copies")
            if(chkcount > 1) {
                return true
            }
        }
        //
        let theInfluences : [BNNode] = self.infs(self)
        for thisInfluences in theInfluences {
            tmpnodeStack.append(thisInfluences)
            if(thisInfluences.DFTcyclechk(tmpnodeStack) == true){
                return true;
            }
        }
        
        
        return false;
    }
    
    
    
    func CPT() -> Int {
        let start = DispatchTime.now()
        print ("\n**********START CPT for \(self.name)")
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        let moc = appDelegate.persistentContainer.viewContext
        let curModel : Model = self.model
        let theEntries = curModel.entry
        
        var ifthens = [Float]()
        
        var end = DispatchTime.now()
        var cptRunTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
        
        let theInfluencedBy = self.infBy(self)
        let nInfBy = theInfluencedBy.count
        if(nInfBy < 1) { //since 2^0 is 1
            self.cptArray = [Float](repeating: -1.0, count: 1)
            let end = DispatchTime.now()
            let cptRunTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
            print ("**********END CPT for \(self.name) \(cptRunTime) seconds.")
            
            return 2
        }
        else {
            let theInfluencedBy = self.infBy(self)
            for thisInfluencedBy in theInfluencedBy {
                let  curInfluencedBy = thisInfluencedBy
                //Which of the entries contain a trait matching the name of the node trait
                
                //get the interbetwene or make if it does nto exist
                if let curNodeInter = self.getInfByInterBetween(infNode: thisInfluencedBy, moc: moc) {
                    
                    
                    let request = NSFetchRequest<Trait>(entityName: "Trait")
                    let predicate = NSPredicate(format: "entry IN %@ && name == %@", argumentArray: [theEntries, curInfluencedBy.name])
                    request.predicate = predicate
                    
                    do {
                        let allCount = try moc.count(for: request)
                        //                    print("allCount \(allCount)")
                        
                        if allCount < 1 {
                            ifthens.append(0.5)
                            curNodeInter.ifthen = 0.5
                        }
                        else {
                            
                            let matchRequest = NSFetchRequest<Trait>(entityName: "Trait")
                            var matchPredicate = NSPredicate()
                            var chkNumeric = true
                            if curInfluencedBy.numericData {
                                if Double(curInfluencedBy.value) == nil {
                                    chkNumeric = false
                                }
                                
                            }
                            
                            
                            //If data is numeric, need to invoke tolerance
                            if curInfluencedBy.numericData && chkNumeric == true {
                                
                                let calcNumVal = Double(curInfluencedBy.value)
                                let tol = curInfluencedBy.tolerance as! Double
                                let lowT = calcNumVal! * (1.0 - (tol/2.0))
                                let highT = calcNumVal! * (1.0 + (tol/2.0))
                                
                                matchPredicate = NSPredicate(format: "entry IN %@ && name == %@ && value >= %f && value <= %f", argumentArray: [theEntries, curInfluencedBy.name, lowT, highT])
                                
                            }
                            else{
                                
                                matchPredicate = NSPredicate(format: "entry IN %@ && name == %@ && value == %@", argumentArray: [theEntries, curInfluencedBy.name, curInfluencedBy.value])
                            }
                            matchRequest.predicate = matchPredicate
                            do {
                                
                                let matchCount = try moc.count(for: matchRequest)
                                print("\(Float(matchCount)) \(Float(allCount)) \((Float(matchCount) / Float(allCount)))")
                                ifthens.append(Float(matchCount) / Float(allCount))
                                curNodeInter.ifthen = NSNumber.init(value: (Float(matchCount) / Float(allCount)))
                                
                            } catch {
                                print("Failed")
                            }
                            
                        }
                        
                    } catch {
                        
                        print("Failed")
                    }
                    
                }//END if let curNodeInter
                
                
            } // END for thisInfluencedBy in theInfluencedBy
            
            
        } //END else
        
        
        
        
        let cptarraysize = Int(pow(2.0,Double(nInfBy)))
        var cptarray = [Float](repeating: 0.0, count: cptarraysize)
        
        for i in 0..<cptarraysize {
            let poststr = String(i, radix: 2)
            
            var prestr = String()
            for _ in poststr.count..<nInfBy {
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
        
        end = DispatchTime.now()
        cptRunTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
        print ("**********END CPT for \(self.name) \(cptRunTime) seconds.  Array: \(cptarray)")
        
        
        //END CPT()
        return 2
    }
    
    
    func getCPTArray(_ sender:AnyObject, mocChanged:Bool) -> [cl_float] {
        //FIXME only change this back if you feel really safe about it
        _ = self.CPT()
        
        //        print ("getCPTArray \(self.name) \(self.cptReady)")
        //        if mocChanged == true || self.cptReady != 2 {
        //           _ = self.CPT()
        //        }
        return self.cptArray
    }
    
    
    func infsInter (sender : AnyObject) -> [BNNodeInter] {
        return self.influences.array as! [BNNodeInter]
    }
    
    
    func infByInter (sender : AnyObject) -> [BNNodeInter] {
        return self.influencedBy.array as! [BNNodeInter]
    }
    
    

    
    func infs(_ sender:AnyObject) -> [BNNode] {
        let infinters = self.infsInter(sender: self)
        var inftargets = [BNNode]()
        for thisInfinter in infinters {
            inftargets.append(thisInfinter.influences)
        }
        return inftargets
    }
    
    func infBy(_ sender:AnyObject) -> [BNNode] {
        let infByinters = self.infByInter(sender: self)
        var inftargets = [BNNode]()
        for thisInfByinter in infByinters {
            inftargets.append(thisInfByinter.influencedBy)
        }
        return inftargets
    }
    

    
    
}
