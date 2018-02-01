//
//  BNNodeExtension.swift
//  Plexus
//
//  Created by matt on 1/9/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData




extension BNNode {
    
    
    
    func addInfluencesObject(_ value:BNNode) {
        let influences = self.mutableOrderedSetValue(forKey: "influences");
        influences.add(value)
    }
    

    func removeInfluencesObject(_ value:BNNode) {
        let influences = self.mutableOrderedSetValue(forKey: "influences");
        influences.remove(value)
    }

    
    func addInfluencedByObject(_ value:BNNode) {
        let influencedBy = self.mutableOrderedSetValue(forKey: "influencedBy");
        influencedBy.add(value)
    }
    
    func removeInfluencedByObject(_ value:BNNode) {
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
    
    func CPT() -> Int {
//        let start = DispatchTime.now()
//        print ("\n**********START altCPT for \(self.nodeLink.name)")
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        let moc = appDelegate.managedObjectContext
        
        let curModel : Model = self.model
        
        //First collect all the scoped ENTRIES
        
        var theEntries = [Entry]()
        if(curModel.scope.entity.name == "Entry"){
            let thisEntry = curModel.scope as! Entry
            theEntries = thisEntry.collectChildren([Entry](), depth: 0)
        }
        else if (curModel.scope.entity.name == "Structure"){
            let thisStructure = curModel.scope as! Structure
            theEntries = thisStructure.entry.allObjects as! [Entry]
        }
        else{
            let request = NSFetchRequest<Entry>(entityName: "Entry")
            do {
                theEntries = try moc.fetch(request)
            } catch {
                return -1
            }
            
        }
        
    
        let theInfluencedBy = self.infBy(self)

        let nInfBy = theInfluencedBy.count
        if(nInfBy < 1) { //since 2^0 is 1
            let cptarray = [Double](repeating: -1.0, count: 1)
            let archivedCPTArray = NSKeyedArchiver.archivedData(withRootObject: cptarray)
            self.setValue(archivedCPTArray, forKey: "cptArray")
//            let end = DispatchTime.now()
//            let cptRunTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
            //            print ("**********END CPT for \(self.nodeLink.name) \(cptRunTime) seconds")
            return 2
        }
        
        var infNames = [String]()
        var infNumericData : [String : Bool] = [:]
        var infTraitvalue : [String : String] = [:]
        var infTolerance : [String : Double] = [:]
        var infLowT : [String : Double] = [:]
        var infHighT : [String : Double] = [:]
        var infTraits  = [String]()
        for thisInfluencedBy in theInfluencedBy {
            let  curInfluencedBy = thisInfluencedBy as! BNNode
            infNames.append(curInfluencedBy.nodeLink.name)
            infNumericData[curInfluencedBy.nodeLink.name] = curInfluencedBy.numericData as? Bool
            infTolerance[curInfluencedBy.nodeLink.name] = curInfluencedBy.tolerance as? Double
            let curTrait : Trait = curInfluencedBy.nodeLink as! Trait
            infTraits.append(curTrait.name)
            infTraitvalue[curInfluencedBy.nodeLink.name] = curTrait.traitValue
            
            //checlk here to make sure data really IS numeric. if not, switch back
            
            if infNumericData[curInfluencedBy.nodeLink.name] == true {
                let infTraittest = infTraitvalue[curInfluencedBy.nodeLink.name]!
                if Double(infTraittest) == nil {
                    infNumericData[curInfluencedBy.nodeLink.name] = false
                    curInfluencedBy.numericData = false
                    
                }
            }
            
            
        }
        
        
        var entryTraits : [String : [Trait]] = [:]
        for thisEntry in theEntries {
            let emptyTraits = [Trait]()
            entryTraits[thisEntry.name] = emptyTraits
        }
        
        for infName in infNames {
            
            if infNumericData[infName] == true {

                infLowT[infName] = Double(infTraitvalue[infName]!)! * (1.0 - (infTolerance[infName]!/2.0))
                infHighT[infName] = Double(infTraitvalue[infName]!)! * (1.0 + (infTolerance[infName]!/2.0))
                


            }

            
        }
        
        
        let cptarraysize = Int(pow(2.0,Double(nInfBy)))
        var cptarray = [Double](repeating: 0.0, count: cptarraysize)
        
        
        var total = 0.0
        var missing = 0.0

        
        var theTraits = [Trait]()
        let request = NSFetchRequest<Trait>(entityName: "Trait")
        request.returnsObjectsAsFaults = false
        let predicate = NSPredicate(format: "entry IN %@ && name IN %@", argumentArray: [theEntries, infNames])
        request.predicate = predicate
        

        
        do {
            theTraits = try moc.fetch(request)
            for thisTrait in theTraits {
                entryTraits[thisTrait.entry.name]?.append(thisTrait)
            }
            for thisEntry in theEntries {
                var allbins = [String]()
                let thisEntryTraits = entryTraits[thisEntry.name]!
                for curTrait in infTraits {
                    var traitbins = [String]()
                    for thisTrait in thisEntryTraits {
                        if(thisTrait.name == curTrait){
                            if infNumericData[curTrait] == true {
                                if(Double(thisTrait.traitValue)! >= infLowT[curTrait]!  && Double(thisTrait.traitValue)! <= infHighT[curTrait]!){
                                    traitbins.append("1")
                                }
                                else {
                                    traitbins.append("0")
                                }
                            }
                            else {
                                if thisTrait.traitValue == infTraitvalue[curTrait] {
                                    traitbins.append("1")
                                }
                                else {
                                   traitbins.append("0")
                                }
                                
                            }
                            
                        }
                    }
                    
                    if allbins.isEmpty {
                        for traitbin in traitbins {
                            allbins.append(traitbin)
                        }
                    }
                    else {
                        var workbins = [String]()
                        for traitbin in traitbins {
                            for oldbin in allbins {
                                let newbin = oldbin + traitbin
                                workbins.append(newbin)
                            }
                        }
                        allbins = workbins
                    }
                }
                
                for thebin in allbins {
                    if thebin.characters.count == nInfBy {
                        cptarray[Int(strtoul(thebin, nil, 2))] += 1.0
                        total += 1
                    }
                    else {
                        missing += 1
                    }
                    
                    
                }
                
            }
 
        } catch  {
            return -1
        }

        
        for i in 0 ..< cptarray.count {
            cptarray[i] = cptarray[i]/total
        }
        
 
        
        let archivedCPTArray = NSKeyedArchiver.archivedData(withRootObject: cptarray)
        self.setValue(archivedCPTArray, forKey: "cptArray")
//        let end = DispatchTime.now()
//        let cptRunTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
//        print ("**********END ALT CPT for \(self.nodeLink.name) \(cptRunTime) seconds. Usable \(total) missing \(missing) Array: \(cptarray)")

        return 2
        

    }
    

    
    func getCPTArray(_ sender:AnyObject, mocChanged:Bool, cptReady:Int) -> [cl_float] {
        if mocChanged == true || cptReady != 2 {
           _ = self.CPT()
        }
        let cptarray = NSKeyedUnarchiver.unarchiveObject(with: self.value(forKey: "cptArray") as! Data) as! [cl_float]
        return  cptarray
    }
    
    
    
    func infBy(_ sender:AnyObject) -> NSArray {
        return self.influencedBy.array as! [BNNode] as NSArray
    }
    
 
    
    func infs(_ sender:AnyObject) -> NSArray {
        return self.influences.array as! [BNNode] as NSArray
    }
    
    
}
