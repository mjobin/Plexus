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
        var influences = self.mutableSetValueForKey("influences");
        influences.addObject(value)
    }
    
    func addInfluencedByObject(value:BNNode) {
        var influencedBy = self.mutableSetValueForKey("influencedBy");
        influencedBy.addObject(value)
    }
    
    
    func freqForCPT(sender:AnyObject) -> cl_float{
        //FIXME
        

        var lidum : CLong = 1
        //
        if(self.influencedBy.count < 1){//no parents, use prior to get a deviate
            var chk = 0
            var pVal : cl_float = -999
            
            while pVal < 0 || pVal > 1 {
        
                switch (priorDistType) {
                case 0://prior/expert
                    pVal = cl_float(priorV1)
                   // return cl_float(priorV1)
                    
                case 1://uniform
                    let r = Double(arc4random())/Double(UInt32.max)
                    let u = cl_float((r*(priorV2.doubleValue - priorV1.doubleValue)) + priorV1.doubleValue)
                    println("uniform \(u)")
                    pVal = cl_float((r*(priorV2.doubleValue - priorV1.doubleValue)) + priorV1.doubleValue)
                    //return cl_float((r*(priorV2.doubleValue - priorV1.doubleValue)) + priorV1.doubleValue)
                    
                case 2: //gaussian

                    var gd = cl_float(gasdev(&lidum))
                    var gdv = cl_float(priorV2) * gd + cl_float(priorV1)
                    println("gaussdev \(gd) \(gdv)")
                    pVal = gdv
                    //return gdv
                case 3: //beta
                    var bd = cl_float(beta_dev(priorV1.doubleValue, priorV2.doubleValue))
                    println("betadev \(bd)")
                    pVal = bd
                    //return bd
                case 4: //gamma
                    var gd = cl_float(gamma_dev(priorV1.doubleValue)/priorV2.doubleValue)
                    println("gammadev \(gd)")
                    pVal = gd
    //                return gd
                    
                    
                default:
                    return -999 //uh oh
                }

            
                chk++
                if(chk > 1000){
                    return -999
                }
            }
            
            return pVal
        }
        
        else {// has parents
            let request = NSFetchRequest(entityName: "Trait")

            
            
            //check for numeric
            if(self.numericData == true){
                let digits = NSCharacterSet.decimalDigitCharacterSet()
                /*
                for thisValue in dataNames {
                    println("thisValue \(thisValue)")
                    for thisChar in thisValue.unicodeScalars{
                        println("thisChar \(thisChar)")
                    }
                }
                */
                return 1
            }
            
            else { // non numeric data, frequency of listed type
                switch(self.dataScope) {
                case 0://global

                    
                    
                    return 1
                case 1: //se;f
                    return 1
                case 2: //children
                    return 1
                    
                    
                default:
                    return -999 //uh oh
                }
                
                
            }

            

            
            
           
        }
    }
    
    func CPT(sender:AnyObject, infBy:[BNNode], ftft:[NSNumber] , depth:Int) -> cl_float{
        var cpt : cl_float = 1.0
        
        //println("CPT: Node name \(self.name) at depth \(depth)")
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
                var pos = find(infBy, self)
                if (pos == nil) {
                    println("Error: could not find influence in CPT fxn")
                    return cl_float.NaN
                }
                

                //println("fftft is \(ftft[pos!])")
                if(ftft[pos!] == 1){//if true
                    return self.freqForCPT(self)
                }
                else {
                    return (1.0-self.freqForCPT(self))
                }
                
            }
            else {//This means that there are no parent nodes of the original search node - it's an independent node
                cpt = -1.0
            }
        }
        
        
        return cpt //should only reach this if it's an independent node
    }
    
    func recursiveInfBy(sender:AnyObject, infBy:NSMutableOrderedSet , depth:Int) -> NSMutableOrderedSet {
        
        if(depth > 0){
            infBy.addObject(self) //ignore first call, dpeth 0
        }
        
        
        let theInfluencedBy : [BNNode] = self.influencedBy.allObjects as! [BNNode]
        
        for thisInfluencedBy in theInfluencedBy {
            //skip any acciedntal self influences
            if(thisInfluencedBy != self){
                thisInfluencedBy.recursiveInfBy(self, infBy: infBy, depth: (depth+1))
            }
        }
        
        
        return infBy
    }
    
    func recursiveInfs(sender:AnyObject, infs:NSMutableOrderedSet , depth:Int) -> NSMutableOrderedSet {
        
        if(depth > 0){
            infs.addObject(self) //ignore first call, dpeth 0
        }
        
        
        let theInfluences : [BNNode] = self.influences.allObjects as! [BNNode]
        
        for thisInfluences in theInfluences {
            //skip any acciedntal self influences
            if(thisInfluences != self){
                thisInfluences.recursiveInfs(self, infs: infs, depth: (depth+1))
            }
        }
        
        
        return infs
    }
    
 
}