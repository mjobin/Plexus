//
//  BNNodeExtension.swift
//  Plexus
//
//  Created by matt on 1/9/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData
import OpenCL



extension BNNode {
    
    
    
    func addInfluencesObject(_ value:BNNode) {
        let influences = self.mutableOrderedSetValue(forKey: "influences");
        influences.add(value)
    }
    



    
    func addInfluencedByObject(_ value:BNNode) {
        let influencedBy = self.mutableOrderedSetValue(forKey: "influencedBy");
        influencedBy.add(value)
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
        
       // print("checking \(self.nodeLink.name)")
        var tmpnodeStack = nodeStack
        
        //check if any two in the array are the same, if so return true
        for chknode in tmpnodeStack {

            var chkcount = 0
            for chkchknode in tmpnodeStack{
                if(chknode == chkchknode){
                    chkcount += 1
                }
            }
            //print("chknode \(chknode.nodeLink.name) has \(chkcount) copies")
            if(chkcount > 1) {
                return true
            }
        }
        //

        let theInfluences : [BNNode] = self.influences.array as! [BNNode]

        for thisInfluences in theInfluences {
           // print("influences \(thisInfluences.nodeLink.name)")
            tmpnodeStack.append(thisInfluences)
            if(thisInfluences.DFTcyclechk(tmpnodeStack) == true){
                return true;
            }
        }
        
        
        return false;
    }
    
    func CPT() {

        let startcalc = NSDate()
        self.setValue(1, forKey: "cptReady") //processing, not ready
       // print ("**********\nCPT for \(self.nodeLink.name) cptReady \(self.cptReady)")
        
        
        let curModel : Model = self.model
               
        //First collect all the scoped ENTRIES
        
        var theEntries = [Entry]()
        if(curModel.scope.entity.name == "Entry"){
            let thisEntry = curModel.scope as! Entry
            theEntries = thisEntry.collectChildren([Entry]())
        }
        else if (curModel.scope.entity.name == "Structure"){
            let thisStructure = curModel.scope as! Structure
            theEntries = thisStructure.entry.allObjects as! [Entry]
        }
        else{
            let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
            let moc = appDelegate.managedObjectContext
            
            let request = NSFetchRequest<Entry>(entityName: "Entry")
            do {
                theEntries = try moc.fetch(request) 
            } catch let error as NSError {
                print (error)
                return
            }
            
        }

        
        
    
        let theInfluencedBy = self.infBy(self)
        let nInfBy = theInfluencedBy.count
        if(nInfBy < 1) { //since 2^0 is 1
            let cptarray = [Double](repeating: -1.0, count: 1)
            let archivedCPTArray = NSKeyedArchiver.archivedData(withRootObject: cptarray)
            self.setValue(archivedCPTArray, forKey: "cptArray")
            return
        }
        
        let cptarraysize = Int(pow(2.0,Double(nInfBy)))
        var cptarray = [Double](repeating: 0.0, count: cptarraysize)
        

        
        var total = 0.0
        var missing = 0.0
        
        for thisEntry in theEntries {
           // print(thisEntry.name)
            var binbins = [String]()
            
            

            for thisInfluencedBy in theInfluencedBy {
                var addbins = [String]()
                let thisthisInfluencedBy = thisInfluencedBy as! BNNode
                let curInfluencedBy = thisthisInfluencedBy.nodeLink as! Trait
                //print ("CURRENT: \(curInfluencedBy.name) \(curInfluencedBy.traitValue)")
                
               // var binbin = String()

                
                var infTraits = [Trait]()
                for thisTrait in thisEntry.trait {
                    let curTrait = thisTrait as! Trait

                    if(curTrait.name == curInfluencedBy.name){
                        var bin = "0"
                        //print ("INF: \(curTrait.name) \(curTrait.traitValue)")
                        infTraits.append(curTrait)
                        if(thisthisInfluencedBy.numericData == true){
                            let lowT = Double(curInfluencedBy.traitValue)! * (1.0 - (thisthisInfluencedBy.tolerance.doubleValue/2.0))
                            let highT = Double(curInfluencedBy.traitValue)! * (1.0 + (thisthisInfluencedBy.tolerance.doubleValue/2.0))
                            if(Double(curTrait.traitValue)! >= lowT && Double(curTrait.traitValue)! <= highT){
                                //binbin += "1"
                                bin = "1"
                            }
                            else{
                                //binbin += "0"
                            }
                        }
                        else{
                            if(curTrait.traitValue == curInfluencedBy.traitValue){
                               // binbin += "1"
                                bin = "1"
                                
                            }
                            else {
                                //binbin += "0"
                                
                            }
                            
                        }
                        
                        addbins.append(bin)
                        
                       // binbins.append(binbin)

                    }
                    
                }

                
                if (binbins.isEmpty){
                    for bin in addbins{
                        binbins.append(bin)
                    }
                }
                else{
                    var workbins = [String]()
                    for bin in addbins {
                        for oldbin in binbins {
                            let newbin = oldbin + bin
                            workbins.append(newbin)
                        }
                    }
                    binbins = workbins
                }

                
            }

            

           // print(binbins)
            
            
            for binbin in binbins {
                if(binbin.characters.count == theInfluencedBy.count){ //ONLY include in part of the total if ALL influences have an associated trait in this entry
                    
                    if let number = Int(binbin, radix: 2) {
                        cptarray[number] += 1.0
                    }
                    
                    total += 1
                    
                }
                else{ //add as ppart of the missing
                    missing += 1
                }
            }
 
            

        }

        
        for i in 0 ..< cptarray.count {
            cptarray[i] = cptarray[i]/total
        }
        
/*
        print("--")
        print(cptarray)
        print("--")
        print("total usable \(total)")
        print("total entries missing \(missing)")
 */
        

        let archivedCPTArray = NSKeyedArchiver.archivedData(withRootObject: cptarray)
        self.setValue(archivedCPTArray, forKey: "cptArray")
        self.setValue(2, forKey: "cptReady") //processed, ready

        let timetaken = startcalc.timeIntervalSinceNow
        
//        print ("CPT calc took \(timetaken) cptReady set to \(self.cptReady)")

        return
    }
    

    
    func getCPTArray(_ sender:AnyObject) -> [cl_float] {
        if(self.cptReady != 2){
            self.CPT()
        }
        let cptarray = NSKeyedUnarchiver.unarchiveObject(with: self.value(forKey: "cptArray") as! Data) as! [cl_float]
        return  cptarray
    }
    
    
    func recursiveInfBy(_ sender:AnyObject, infBy:NSMutableOrderedSet , depth:Int) -> NSMutableOrderedSet {
        
        if(depth > 0){
            infBy.add(self) //ignore first call, dpeth 0
        }
        
        
        let theInfluencedBy : [BNNode] = self.influencedBy.array as! [BNNode]
        
        for thisInfluencedBy in theInfluencedBy {
            //skip any acciedntal self influences
            if(thisInfluencedBy != self){
                thisInfluencedBy.recursiveInfBy(self, infBy: infBy, depth: (depth+1))
            }
        }
        
        
        return infBy
    }
    
    func infBy(_ sender:AnyObject) -> NSArray {
        return self.influencedBy.array as! [BNNode] as NSArray
    }
    
    func recursiveInfs(_ sender:AnyObject, infs:NSMutableOrderedSet , depth:Int) -> NSMutableOrderedSet {
        
        if(depth > 0){
            infs.add(self) //ignore first call, dpeth 0
        }
        
        
        let theInfluences : [BNNode] = self.influences.array as! [BNNode]
        
        for thisInfluences in theInfluences {
            //skip any acciedntal self influences
            if(thisInfluences != self){
                thisInfluences.recursiveInfs(self, infs: infs, depth: (depth+1))
            }
        }
        
        
        return infs
    }
    
    
    func infs(_ sender:AnyObject) -> NSArray {
        return self.influences.array as! [BNNode] as NSArray
    }
    
    
    
    

    
    
}
