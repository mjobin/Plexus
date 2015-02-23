//
//  BNNodeExtenstion.swift
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
        
        //
        if(self.influencedBy.count < 1){//no parents, use prior
        
            switch (priorDistType) {
            case 0://prior/expert
                return cl_float(priorV1)
                
            default:
                return -999 //uh oh
            }
            
        }
        
        else {// has parents
            
            switch(self.nodeLink.entity){
            case "entry":
                println("entry")
                return -999
                
            case "trait":
                println("trait")
                return -999
                
            default:
                println("damn")
                return -999
            
            }
            
        }

    }
    
    func CPT(sender:AnyObject, infBy:[BNNode], ftft:[NSNumber] , depth:Int) -> cl_float{
        var cpt : cl_float = 1.0
        
        println("CPT: Node name \(self.name) at depth \(depth)")
        //for every input node 
        let theInfluencedBy : [BNNode] = self.influencedBy.allObjects as [BNNode]
        

        if(theInfluencedBy.count > 0){//continue up tree

        
            for thisInfluencedBy in theInfluencedBy {
                //skip any acciedntal self influences
                if(thisInfluencedBy != self){
                    println("CPT: is influenced by: \(thisInfluencedBy.name)")
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
                

                println("fftft is \(ftft[pos!])")
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
        
        
        let theInfluencedBy : [BNNode] = self.influencedBy.allObjects as [BNNode]
        
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
        
        
        let theInfluences : [BNNode] = self.influences.allObjects as [BNNode]
        
        for thisInfluences in theInfluences {
            //skip any acciedntal self influences
            if(thisInfluences != self){
                thisInfluences.recursiveInfs(self, infs: infs, depth: (depth+1))
            }
        }
        
        
        return infs
    }
    
 
}