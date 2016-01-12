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
        let influences = self.mutableSetValueForKey("influences");
        influences.addObject(value)
    }
    
    func addInfluencedByObject(value:BNNode) {
        let influencedBy = self.mutableSetValueForKey("influencedBy");
        influencedBy.addObject(value)
    }
    
    
    
    func freqForCPT(sender:AnyObject) -> cl_float{
        
        //Get MOC from App delegate
        //let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
      // var  moc = appDelegate.managedObjectContext

        

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
                    //println("sample from piorarray \(priorArray[randomIndex])")
                    pVal = priorArray[randomIndex]
                    
                    
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
        else{
            return cl_float(self.cptFreq)
        }
        
            /*
        else {// has parents
            let request = NSFetchRequest(entityName: "Trait")
            var predicate = NSPredicate()
            

            let curModel : Model = self.model
            let curDataset : Dataset = curModel.dataset
            

            
            
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
                    
                    //if it's an entry, then the proportion of those trait entries in all the traits
                    
                    if(self.nodeLink.entity.name == "Entry"){
                        predicate = NSPredicate(format: "entry.dataset == %@ AND name == %@", curDataset, self.nodeLink.name)
                        request.resultType = .DictionaryResultType
                        request.predicate = predicate
                        request.returnsDistinctResults = false
                        request.propertiesToFetch = ["traitValue"]
                        
                        if let fetch = moc!.executeFetchRequest(request, error:&err) {
                            println("global entry fetch \(fetch)")
                            /*
                            for obj  in fetch {
                            println(obj.valueForKey("traitValue"))
                            
                            
                            }
                            */
                            let trequest = NSFetchRequest(entityName: "Trait")
                            var tpredicate = NSPredicate(format: "entry.dataset == %@", curDataset)
                            
                            trequest.resultType = .DictionaryResultType
                            trequest.predicate = tpredicate
                            trequest.returnsDistinctResults = false
                            trequest.propertiesToFetch = ["traitValue"]
                            
                            if let tfetch = moc!.executeFetchRequest(trequest, error:&err) {
                                let tresult = (cl_float(tfetch.count)/cl_float(fetch.count))
                                println(" global entry with parent \(tresult)")
                                return tresult
                            }
                            else {
                                return 0.0
                            }
                            
                            
                    }
                        else {
                            return -999
                        }
                    


                    }
                    
                        //if its a trait, the the proportion of those trait values in all the traits?
                        
                        
                    else if (self.nodeLink.entity.name == "Trait"){
                        //so this trait's value
                        let thisTrait = self.nodeLink as! Trait
                        
                        predicate = NSPredicate(format: "entry.dataset == %@ AND name == %@", curDataset, thisTrait.name)
                        request.resultType = .DictionaryResultType
                        request.predicate = predicate
                        request.returnsDistinctResults = false
                        request.propertiesToFetch = ["traitValue"]
                        
                        if let fetch = moc!.executeFetchRequest(request, error:&err) {
                         //   println("global trait fetch coiunt \(fetch.count)")
                            
                            
                            for obj  in fetch {
                               // println(obj.valueForKey("traitValue"))

                            }

                            
                            let trequest = NSFetchRequest(entityName: "Trait")
                            let tpredicate = NSPredicate(format: "entry.dataset == %@ AND name == %@ AND traitValue == %@", curDataset, thisTrait.name, thisTrait.traitValue)
                            
                            trequest.resultType = .DictionaryResultType
                            trequest.predicate = tpredicate
                            trequest.returnsDistinctResults = false
                            trequest.propertiesToFetch = ["traitValue"]
                            
                            if let tfetch = moc!.executeFetchRequest(trequest, error:&err) {
                                //println("global trait tfetch count \(tfetch.count)")
                                for obj  in tfetch {
                                  //  println(obj.valueForKey("traitValue"))
                                    
                                }
                                
                                let tresult = (cl_float(tfetch.count)/cl_float(fetch.count))
                                println(" global entry with parent \(tresult)")
                                return tresult
                            }
                            else {
                                return 0.0
                            }

                            
                            
                        }
                        
                        else {
                            return -999
                        }


                        
                        
                    }
                    
                    else {
                        return -999
                    }
                    


                case 1: //se;f
                    
                    if(self.nodeLink.entity.name == "Entry"){
                        let thisEntry = self.nodeLink as! Entry
                        
                        predicate = NSPredicate(format: "entry == %@ AND name == %@", thisEntry, self.dataName)
                        request.resultType = .DictionaryResultType
                        request.predicate = predicate
                        request.returnsDistinctResults = false
                        request.propertiesToFetch = ["traitValue"]
                        
                        if let fetch = moc!.executeFetchRequest(request, error:&err) {
                               println("self entry fetch coiunt \(fetch.count)")
                            
                            
                            for obj  in fetch {
                                 println(obj.valueForKey("traitValue"))
                                
                            }
                            
                            let trequest = NSFetchRequest(entityName: "Trait")
                            let tpredicate = NSPredicate(format: "entry == %@ AND name == %@ AND traitValue == %@", thisEntry, self.dataName, self.dataSubName)
                            
                            trequest.resultType = .DictionaryResultType
                            trequest.predicate = tpredicate
                            trequest.returnsDistinctResults = false
                            trequest.propertiesToFetch = ["traitValue"]
                            
                            if let tfetch = moc!.executeFetchRequest(trequest, error:&err) {
                                println("self entry tfetch count \(tfetch.count)")
                                for obj  in tfetch {
                                      println(obj.valueForKey("traitValue"))
                                    
                                }
                                
                                let tresult = (cl_float(tfetch.count)/cl_float(fetch.count))
                                println("self entry with parent \(tresult)")
                                return tresult
                                
                            }
                            else {
                                return -999
                            }
                            
                            
                        }
                        else {
                            return -999
                        }
                        
                        

                    }
                    else if (self.nodeLink.entity.name == "Trait"){//if you select trait here, you can only mean this trait, and so freq of it's value in itself must be 1
                        

                        return 1
                    }
                    else {
                        return -999
                    }


                    
                case 2: //children
                    if(self.nodeLink.entity.name == "Entry"){
                        let thisEntry = self.nodeLink as! Entry
                        
                        predicate = NSPredicate(format: "entry.parent == %@ AND name == %@", thisEntry, self.dataName)
                        request.resultType = .DictionaryResultType
                        request.predicate = predicate
                        request.returnsDistinctResults = false
                        request.propertiesToFetch = ["traitValue"]
                        
                        if let fetch = moc!.executeFetchRequest(request, error:&err) {
                            println("children entry fetch coiunt \(fetch.count)")
                            
                            
                            for obj  in fetch {
                                println(obj.valueForKey("traitValue"))
                                
                            }
                            
                            let trequest = NSFetchRequest(entityName: "Trait")
                            let tpredicate = NSPredicate(format: "entry.parent == %@ AND name == %@ AND traitValue == %@", thisEntry, self.dataName, self.dataSubName)
                            
                            trequest.resultType = .DictionaryResultType
                            trequest.predicate = tpredicate
                            trequest.returnsDistinctResults = false
                            trequest.propertiesToFetch = ["traitValue"]
                            
                            if let tfetch = moc!.executeFetchRequest(trequest, error:&err) {
                                println("children entry tfetch count \(tfetch.count)")
                                for obj  in tfetch {
                                    println(obj.valueForKey("traitValue"))
                                    
                                }
                                
                                let tresult = (cl_float(tfetch.count)/cl_float(fetch.count))
                                println("self entry with parent \(tresult)")
                                return tresult
                                
                            }
                            else {
                                return -999
                            }
                            
                            
                        }
                        else {
                            return -999
                        }
                        
                        
                    }
                    
                    return 1
                    
                    
                default:
                    return -999 //uh oh
                }
                
                
            }


           
        }*/
    }
    
    func calcWParentCPT(sender:AnyObject) {
        //let errorPtr : NSErrorPointer = nil
        
        //Get MOC from App delegate
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let  moc = appDelegate.managedObjectContext

    
        
            let request = NSFetchRequest(entityName: "Trait")
            var predicate = NSPredicate()
            
            
            let curModel : Model = self.model
            let curDataset : Dataset = curModel.dataset
            
            
            
            
            //check for numeric
            if(self.numericData == true){
               // let digits = NSCharacterSet.decimalDigitCharacterSet()
                /*
                for thisValue in dataNames {
                println("thisValue \(thisValue)")
                for thisChar in thisValue.unicodeScalars{
                println("thisChar \(thisChar)")
                }
                }
                */
                self.cptFreq = 1
            }
                
            else { // non numeric data, frequency of listed type
                
                
                
                switch(self.dataScope) {
                case 0://global
                    
                    //if it's an entry, then the proportion of those trait entries in all the traits
                    // for a structure, the values of all the traits that atch the structure's name ...pretty weird, but why not include it
                    
                    if(self.nodeLink.entity.name == "Entry" || self.nodeLink.entity.name == "Structure"){
                        predicate = NSPredicate(format: "entry.dataset == %@ AND name == %@", curDataset, self.nodeLink.name)
                        request.resultType = .DictionaryResultType
                        request.predicate = predicate
                        request.returnsDistinctResults = false
                        request.propertiesToFetch = ["traitValue"]
                        
                        do {
                            let fetch = try moc.executeFetchRequest(request)
                           // println("global entry fetch \(fetch)")
                            /*
                            for obj  in fetch {
                            println(obj.valueForKey("traitValue"))
                            
                            
                            }
                            */
                            let trequest = NSFetchRequest(entityName: "Trait")
                            let tpredicate = NSPredicate(format: "entry.dataset == %@", curDataset)
                            
                            trequest.resultType = .DictionaryResultType
                            trequest.predicate = tpredicate
                            trequest.returnsDistinctResults = false
                            trequest.propertiesToFetch = ["traitValue"]
                            
                            do {
                                let tfetch = try moc.executeFetchRequest(trequest)
                                let tresult = (cl_float(tfetch.count)/cl_float(fetch.count))
                               // println(" global entry with parent \(tresult)")
                                self.cptFreq = tresult
                            } catch let error as NSError {
                                print(error)
                                self.cptFreq = 0.0
                            }
                            
                            
                        } catch let error as NSError {
                            print(error)
                            self.cptFreq = -999
                        }
                        
                        
                        
                    }
                        
                        //if its a trait, the the proportion of those trait values in all the traits?
                        
                        
                    else if (self.nodeLink.entity.name == "Trait"){
                        //so this trait's value
                        let thisTrait = self.nodeLink as! Trait
                        
                        predicate = NSPredicate(format: "entry.dataset == %@ AND name == %@", curDataset, thisTrait.name)
                        request.resultType = .DictionaryResultType
                        request.predicate = predicate
                        request.returnsDistinctResults = false
                        request.propertiesToFetch = ["traitValue"]
                        
                        do {
                            let fetch = try moc.executeFetchRequest(request)


                            
                            let trequest = NSFetchRequest(entityName: "Trait")
                            let tpredicate = NSPredicate(format: "entry.dataset == %@ AND name == %@ AND traitValue == %@", curDataset, thisTrait.name, thisTrait.traitValue)
                            
                            trequest.resultType = .DictionaryResultType
                            trequest.predicate = tpredicate
                            trequest.returnsDistinctResults = false
                            trequest.propertiesToFetch = ["traitValue"]
                            
                            do {
                                let tfetch = try moc.executeFetchRequest(trequest)

                                let tresult = (cl_float(tfetch.count)/cl_float(fetch.count))

                                self.cptFreq = tresult
                            } catch let error as NSError {
                                print(error)
                                self.cptFreq = 0.0
                            }
                            
                            
                            
                        } catch let error as NSError {
                            print(error)
                            self.cptFreq = -999
                        }
                        
                        
                        
                        
                    }
                        
                        

                        
                    else {
                        self.cptFreq = -999
                    }
                    
                    
                    
                case 1: //se;f
                    
                    if(self.nodeLink.entity.name == "Entry"){
                        let thisEntry = self.nodeLink as! Entry
                        
                        predicate = NSPredicate(format: "entry == %@ AND name == %@", thisEntry, self.dataName)
                        request.resultType = .DictionaryResultType
                        request.predicate = predicate
                        request.returnsDistinctResults = false
                        request.propertiesToFetch = ["traitValue"]
                        
                        do {
                            let fetch = try moc.executeFetchRequest(request)

                            
                            let trequest = NSFetchRequest(entityName: "Trait")
                            let tpredicate = NSPredicate(format: "entry == %@ AND name == %@ AND traitValue == %@", thisEntry, self.dataName, self.dataSubName)
                            
                            trequest.resultType = .DictionaryResultType
                            trequest.predicate = tpredicate
                            trequest.returnsDistinctResults = false
                            trequest.propertiesToFetch = ["traitValue"]
                            
                            do {
                                let tfetch = try moc.executeFetchRequest(trequest)

                                
                                let tresult = (cl_float(tfetch.count)/cl_float(fetch.count))
                               // println("self entry with parent \(tresult)")
                                self.cptFreq = tresult
                                
                            } catch let error as NSError {
                                print(error)
                                self.cptFreq = -999
                            }
                            
                            
                        } catch let error as NSError {
                            print(error)
                            self.cptFreq = -999
                        }
                        
                        
                        
                    }
                    else if (self.nodeLink.entity.name == "Trait"){//if you select trait here, you can only mean this trait, and so freq of it's value in itself must be 1
                        
                        
                        self.cptFreq = 1
                    }
                        
                    else if (self.nodeLink.entity.name == "Structure"){ //The traits whose entries are part of this structure
                        
                        let thisStructure = self.nodeLink as! Structure
                        
                        
                        predicate = NSPredicate(format: "entry.sructure == %@ AND name == %@", thisStructure, self.dataName)
                        request.resultType = .DictionaryResultType
                        request.predicate = predicate
                        request.returnsDistinctResults = false
                        request.propertiesToFetch = ["traitValue"]
                        
                        do {
                            let fetch = try moc.executeFetchRequest(request)

                            
                            let trequest = NSFetchRequest(entityName: "Trait")
                            let tpredicate = NSPredicate(format: "entry.structure == %@ AND name == %@ AND traitValue == %@", thisStructure, self.dataName, self.dataSubName)
                            
                            trequest.resultType = .DictionaryResultType
                            trequest.predicate = tpredicate
                            trequest.returnsDistinctResults = false
                            trequest.propertiesToFetch = ["traitValue"]
                            
                            do {
                                let tfetch = try moc.executeFetchRequest(trequest)

                                
                                let tresult = (cl_float(tfetch.count)/cl_float(fetch.count))
                                // println("self entry with parent \(tresult)")
                                self.cptFreq = tresult
                                
                            } catch let error as NSError {
                                print(error)
                                self.cptFreq = -999
                            }
                            
                            
                        } catch let error as NSError {
                            print(error)
                            self.cptFreq = -999
                        }
                        
                    }
                    else {
                        self.cptFreq = -999
                    }
                    
                    
                    
                case 2: //children
                    if(self.nodeLink.entity.name == "Entry"){
                        let thisEntry = self.nodeLink as! Entry
                        
                        predicate = NSPredicate(format: "entry.parent == %@ AND name == %@", thisEntry, self.dataName)
                        request.resultType = .DictionaryResultType
                        request.predicate = predicate
                        request.returnsDistinctResults = false
                        request.propertiesToFetch = ["traitValue"]
                        
                        do {
                            let fetch = try moc.executeFetchRequest(request)
                           // println("children entry fetch coiunt \(fetch.count)")
                            
                            
                            
                            let trequest = NSFetchRequest(entityName: "Trait")
                            let tpredicate = NSPredicate(format: "entry.parent == %@ AND name == %@ AND traitValue == %@", thisEntry, self.dataName, self.dataSubName)
                            
                            trequest.resultType = .DictionaryResultType
                            trequest.predicate = tpredicate
                            trequest.returnsDistinctResults = false
                            trequest.propertiesToFetch = ["traitValue"]
                            
                            do {
                                let tfetch = try moc.executeFetchRequest(trequest)

                                
                                let tresult = (cl_float(tfetch.count)/cl_float(fetch.count))
                             //   println("self entry with parent \(tresult)")
                                self.cptFreq = tresult
                                
                            } catch let error as NSError {
                                print(error)
                                self.cptFreq = -999
                            }
                            
                            
                        } catch let error as NSError {
                            print(error)
                            self.cptFreq = -999
                        }
                        
                        
                    }
                    
                    self.cptFreq = 1
                    
                    
                default:
                    self.cptFreq = -999 //uh oh
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
                let pos = infBy.indexOf(self)
                if (pos == nil) {
                    print("Error: could not find influence in CPT fxn")
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
    
    
   
    
    
    func getDataNames() -> [String] {
        var dataNames = [String]()

        
        switch(self.dataScope) {
            
            case 0://global // ALL entities matching this one's name
             dataNames.append(self.nodeLink.name)
            
        case 1:// self

            //from that object, select only the names of what is directly connected to it
            if(self.nodeLink.entity.name == "Entry"){
                let curEntry = self.nodeLink as! Entry
                let theTraits = curEntry.trait
                for thisTrait in theTraits {
                    dataNames.append(thisTrait.name)
                }
                
            }
            else if (self.nodeLink.entity.name == "Trait"){//if you select trait here, you can only mean this trait
                dataNames.append(self.nodeLink.name)

            }
                
            else if (self.nodeLink.entity.name == "Structure"){    //The traits whose entries are part of this structure
                let curStructure = self.nodeLink as! Structure
                let curEntries = curStructure.entry
                for curEntry in curEntries {
                    let curTraits = curEntry.trait
                    for curTrait in curTraits{
                        dataNames.append(curTrait.name)
                    }
                }
                
            }
            else {
                dataNames = [String]()
            }
            
        case 2: //children of current entry


            if(self.nodeLink.entity.name == "Entry"){ //take this entry's children and look at it's traits
                
                
                //If it is connected to this entry, then it is autmatically in that entry's only possible dataset
                
                let curEntry = self.nodeLink as! Entry
                let curKids = curEntry.children
                for curKid in curKids {
                    let curTraits = curKid.trait
                    for curTrait in curTraits{
                        dataNames.append(curTrait.name)
                    }
                }
                

                
            }
            else if (self.nodeLink.entity.name == "Trait" || self.nodeLink.entity.name == "Structure"){ //traits and structures have no children
                self.dataScope = 0
                dataNames = [String]()

                
            }
            else {
                dataNames = [String]()
                
            }
            
            
            
            default:
                dataNames = [String]()
            
        }
        
        return dataNames
    }
    
    func getDataSubNames() -> [String] {
        var dataSubNames = [String]()
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let moc : NSManagedObjectContext = appDelegate.managedObjectContext
        
        let curModel : Model = self.model
        let curDataset : Dataset = curModel.dataset
        
        
        let request = NSFetchRequest(entityName: "Trait")
        var predicate = NSPredicate()
        
        
        switch(self.dataScope) {
        case 0:
            if(self.nodeLink.entity.name == "Entry"){//Traits whose names match the name of this entry

                predicate = NSPredicate(format: "entry.dataset == %@ AND name == %@", curDataset, self.nodeLink.name)
                
            }
            else if (self.nodeLink.entity.name == "Trait"){ //you obviously want this trait's own value, then

                predicate = NSPredicate(format: "entry.dataset == %@ AND name == %@", curDataset, self.nodeLink.name)
            }

        case 1:
            
            if(self.nodeLink.entity.name == "Entry"){

                predicate = NSPredicate(format: "entry == %@ AND name == %@", self.nodeLink, self.dataName)
                
            }
                
            else if (self.nodeLink.entity.name == "Trait"){ //you obviously want this trait's own value, then

                predicate = NSPredicate(format: "entry == %@", self.nodeLink)
                
            }
            
        case 2:
            
            if(self.nodeLink.entity.name == "Entry"){ //take this entry's children and look at it's children

                predicate = NSPredicate(format: "entry.parent == %@ AND name == %@", self.nodeLink, self.dataName)
                
            }
                
            else if (self.nodeLink.entity.name == "Trait"){ //traits cannot have children

            }
            
            
        default:
            dataSubNames = [String]()
            
        }

        
        request.resultType = .DictionaryResultType
        request.predicate = predicate
        request.returnsDistinctResults = true
        request.propertiesToFetch = ["traitValue"]
        
        do {
            let fetch = try moc.executeFetchRequest(request)
            // print("sub fetch \(fetch)")
            for obj  in fetch {
              //     print(obj.valueForKey("traitValue"))
                dataSubNames.append(obj.valueForKey("traitValue") as! String)
                
            }
        } catch let error as NSError {
            print(error)
        }

        
        return dataSubNames
    }
    
 
}