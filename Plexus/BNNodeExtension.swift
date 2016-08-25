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
    
    
    
    func addInfluencesObject(value:BNNode) {
        let influences = self.mutableOrderedSetValueForKey("influences");
        influences.addObject(value)
    }
    



    
    func addInfluencedByObject(value:BNNode) {
        let influencedBy = self.mutableOrderedSetValueForKey("influencedBy");
        influencedBy.addObject(value)
    }
    


    
    func getCPTFreq(sender:AnyObject) -> cl_float {
        return cl_float(self.cptFreq)
    }
    
    
    func freqForCPT(sender:AnyObject) -> cl_float {
        
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
            case 5: //sample from the prioarray
                let priorArray = NSKeyedUnarchiver.unarchiveObjectWithData(self.valueForKey("priorArray") as! NSData) as! [cl_float]
                let randomIndex = Int(arc4random_uniform(UInt32(priorArray.count)))
                
                pVal = priorArray[randomIndex]
                
                
            default:
                return cl_float.NaN //uh oh
            }
            
            
            chk += 1
            if(chk > 1000){
                return cl_float.NaN
            }
        }
        
        return pVal
        
   
    }
    
    func calcCPT(sender:AnyObject) -> NSString {
        
        
        
        if(self.influencedBy.count < 1){//no parents, use prior to get a deviate
            self.cptFreq = self.freqForCPT(self)
            if(self.cptFreq == cl_float.NaN){
                return "Node: \(self.nodeLink.name). NaN calculated for cptFreq. Please check that Traits list not empty for the data linked by that node."
            }
            
        }
            
        else {
            

            
           

            

            
        }
        
        return "No Error"
    }
    

    
    func DFTcyclechk(nodeStack:[BNNode]) -> Bool {
        
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
    
    func CPT(){
        
       // print ("**********\nCPT for \(self.nodeLink.name)")
        
        
        let curModel : Model = self.model
        let curDataset : Dataset = curModel.dataset
        
        //First collect all the scoped ENTRIES
        
        var theEntries = [Entry]()
        if(curModel.scope.entity.name == "Entry"){
          //  print("entry scope")
            let thisEntry = curModel.scope as! Entry
            theEntries = thisEntry.collectChildren([Entry]())
        }
        else if (curModel.scope.entity.name == "Structure"){
           // print("structure scope")
            let thisStructure = curModel.scope as! Structure
            theEntries = thisStructure.entry.allObjects as! [Entry]
        }
        else{
          //  print("dataset scope")
            theEntries = curDataset.entry.allObjects as! [Entry]
            
        }

        
        
    
        let theInfluencedBy = self.infBy(self)
        //print("infby count: \(theInfluencedBy.count)")
        let nInfBy = theInfluencedBy.count
        let cptarraysize = Int(pow(2.0,Double(nInfBy)))
        var cptarray = [Double](count: cptarraysize, repeatedValue: 0.0)
        

        
        var total = 0.0
        var missing = 0.0
        
        for thisEntry in theEntries {
            var binbin = String()
            for thisInfluencedBy in theInfluencedBy {
                let thisthisInfluencedBy = thisInfluencedBy as! BNNode
                let curInfluencedBy = thisInfluencedBy.nodeLink as! Trait
                //print("infleucned by \(curInfluencedBy.name)")
                 //get traits matching this name from this entry
                
                var infTraits = [Trait]()
                for thisTrait in thisEntry.trait {
                    let curTrait = thisTrait as! Trait
                    if(curTrait.name == curInfluencedBy.name){
                        infTraits.append(curTrait)
                    }
                    
                }
                
                if(infTraits.count == 1){ //FIXME only looking at a single instance of a trait
                    if(thisthisInfluencedBy.numericData == true){
                        let lowT = Double(curInfluencedBy.traitValue)! * (1.0 - (thisthisInfluencedBy.tolerance.doubleValue/2.0))
                        let highT = Double(curInfluencedBy.traitValue)! * (1.0 + (thisthisInfluencedBy.tolerance.doubleValue/2.0))
                        if(Double(infTraits[0].traitValue)! >= lowT && Double(infTraits[0].traitValue)! <= highT){
                            binbin += "1"
                        }
                        else{
                            binbin += "0"
                        }
                    }
                    else{
                        if(infTraits[0].traitValue == curInfluencedBy.traitValue){
                            binbin += "1"
                            
                        }
                        else {
                            binbin += "0"
                            
                        }

                    }
                }
                
            }
            
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

        
        for i in 0 ..< cptarray.count {
            cptarray[i] = cptarray[i]/total
        }
        
/*
        print("--")
        print(cptarray)
        print("--")
        print("total entries usable \(total)")
        print("total entries missing \(missing)")
        */
        

        let archivedCPTArray = NSKeyedArchiver.archivedDataWithRootObject(cptarray)
        self.setValue(archivedCPTArray, forKey: "cptArray")

          //  print(" ")


    }
    
    func getCPTArray(sender:AnyObject) -> [cl_float] {
        self.CPT()
        let cptarray = NSKeyedUnarchiver.unarchiveObjectWithData(self.valueForKey("cptArray") as! NSData) as! [cl_float]
        return  cptarray
        /*
        let cptnsarray : NSMutableArray = NSMutableArray()
        for cptelem in cptarray {
            cptnsarray.addObject(cptelem)
        }
        
        return  cptnsarray
        */
    }
    /*
    func CPT(sender:AnyObject, infBy:[BNNode], ftft:[NSNumber] , depth:Int) -> cl_float{
        var cpt : cl_float = 1.0
        
       // print("CPT: Node name \(self.nodeLink.name) at depth \(depth)")
        //for every input node
        let theInfluencedBy : [BNNode] = self.influencedBy.allObjects as! [BNNode]
        
        
        if(theInfluencedBy.count > 0){//continue up tree
            
            for thisInfluencedBy in theInfluencedBy {
                //skip any acciedntal self influences
                if(thisInfluencedBy != self){
                    
                    // println("CPT: is influenced by: \(thisInfluencedBy.name)")
                    cpt *= thisInfluencedBy.CPT(self, infBy: infBy, ftft: ftft, depth: (depth+1))
                }
            }
        }
        else { //have reached a tip
            if(depth>0){
                let pos = infBy.indexOf(self)
                if (pos == nil) {
                    return cl_float.NaN
                }
                
              //  print("fftft is \(ftft[pos!])")
                if(ftft[pos!] == 1){//if true
                    return Float(self.cptFreq)
                }
                else {
                    return (1.0-Float(self.cptFreq))
                }
                
            }
            else {//This means that there are no parent nodes of the original search node - it's an independent node
                cpt = -1.0
            }
        }
        
        return cpt //should only reach this if it's an independent node
    }
    */
    
    func recursiveInfBy(sender:AnyObject, infBy:NSMutableOrderedSet , depth:Int) -> NSMutableOrderedSet {
        
        if(depth > 0){
            infBy.addObject(self) //ignore first call, dpeth 0
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
    
    func infBy(sender:AnyObject) -> NSArray {
        return self.influencedBy.array as! [BNNode]
    }
    
    func recursiveInfs(sender:AnyObject, infs:NSMutableOrderedSet , depth:Int) -> NSMutableOrderedSet {
        
        if(depth > 0){
            infs.addObject(self) //ignore first call, dpeth 0
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
    
    
    func infs(sender:AnyObject) -> NSArray {
        return self.influences.array as! [BNNode]
    }
    
    
    
    

    
    
}