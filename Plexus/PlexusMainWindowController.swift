//
//  PlexusMainWindowController.swift
//  Plexus
//
//  Created by matt on 10/1/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import CoreData
import OpenCL


class PlexusMainWindowController: NSWindowController, ProgressViewControllerDelegate, NSWindowDelegate {
    
    

  
    var moc : NSManagedObjectContext!
    var mainSplitViewController = PlexusMainSplitViewController()
    var progressViewController : PlexusProgressPanel!
    @IBOutlet var datasetController : NSArrayController!
    //var pProgress: NSProgress?
    var queue: dispatch_queue_t = dispatch_queue_create("My Queue", DISPATCH_QUEUE_SERIAL)
    


    
    override func windowWillLoad() {
        
        let errorPtr : NSErrorPointer = nil

        //Get MOC from App delegate
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext

        

        
        //create a dataset if there are none
        let request = NSFetchRequest(entityName: "Dataset")
        let fetchedDatasets: [AnyObject]?
        do {
            fetchedDatasets = try moc.executeFetchRequest(request)
        } catch let error as NSError {
            errorPtr.memory = error
            fetchedDatasets = nil
        }
        
        if fetchedDatasets == nil {
            print("error")

        }
        
        let initDatasets = fetchedDatasets as! [NSManagedObject]
        if(initDatasets.count == 0){
            print("no datasets")
            //so make an initial one
            let newDataset = NSEntityDescription.insertNewObjectForEntityForName("Dataset", inManagedObjectContext: moc) 

            let newModel = NSEntityDescription.insertNewObjectForEntityForName("Model", inManagedObjectContext: moc) 
            newModel.setValue("newmodel", forKey: "name")
            newModel.setValue(newDataset, forKey: "dataset")
            newModel.setValue(NSDate(), forKey: "dateCreated")
            newModel.setValue(NSDate(), forKey: "dateModded")
            do {
                try moc.save()
            } catch let error as NSError {
                errorPtr.memory = error
            }

        }


        
        
        
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        
        mainSplitViewController = contentViewController as! PlexusMainSplitViewController

        mainSplitViewController.datasetController = self.datasetController
       // println(self.datasetController)
        //println(mainSplitViewController.datasetController)
        
        
     //   println(datasetController!.selectionIndexes)
        
      //  datasetController!.setSelectionIndex(1)

        
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func  copyDataset(x:NSToolbarItem){
        print("copy dataset Tapped: \(x)")
        
    }
    
    @IBAction func  toggleModels(x:NSToolbarItem){
        //println("Toggle models Tapped: \(x)")

        mainSplitViewController.toggleModels(x)
        
    }
    
    @IBAction func  toggleStructures(x:NSToolbarItem){

        
        mainSplitViewController.toggleStructures(x)
        
    }
    

    
    @IBAction func testRandom(x:NSToolbarItem){
        
        let nodes : [BNNode] = mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode]
        
        
        for fNode in nodes {
            if(fNode.influencedBy.count > 0){
                fNode.calcWParentCPT(self)
            }
        }
        
        for fNode in nodes {
            let blankArray = [NSNumber]()
            let blankData = NSKeyedArchiver.archivedDataWithRootObject(blankArray)
            
            var postCount = [Int](count: 101, repeatedValue: 0)
            
 
            fNode.setValue(blankData, forKey: "postCount")
            fNode.setValue(blankData, forKey: "postArray")
            
            
            var testranarray = [Double]()
            for _ in 1 ... 10000 {
                testranarray.append(Double(fNode.freqForCPT(self)))
            }
            
            var gi = 0
            for gNode : Double in testranarray {
                
                print(gNode)
                
                
                if(gNode == gNode && gNode >= 0.0 && gNode <= 1.0) {//fails if nan
                    
                    let whut = (Int)(floor(gNode/0.01))
                    
                    postCount[whut]++
                    
                }
                    
                    
                else{
                    // println("problem detected in reloadData. gNode is \(gNode)")
                }
                
                gi++
            }
            
            let archivedPostCount = NSKeyedArchiver.archivedDataWithRootObject(postCount)
            fNode.setValue(archivedPostCount, forKey: "postCount")
            let archivedPostArray = NSKeyedArchiver.archivedDataWithRootObject(testranarray)
            fNode.setValue(archivedPostArray, forKey: "postArray")
        }
    }

    
    
    @IBAction func  calculate(x:NSToolbarItem){
        let errorPtr : NSErrorPointer = nil
        
       // var i : Int = 0
        
        

        
        

        //instatntiate progress controller
        if self.progressViewController == nil {
            let storyboard = NSStoryboard(name:"Main", bundle:nil)

            self.progressViewController = storyboard.instantiateControllerWithIdentifier("ProgressViewController") as? PlexusProgressPanel
            
        }
        self.progressViewController?.delegate = self
        

        
        self.contentViewController?.presentViewControllerAsSheet(self.progressViewController!)
        //swap it in?
        
        self.progressViewController?.changeLabel(String("Calculating..."))
        

        
        

        //collect data
        var nodesForCalc : [BNNode] = mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode]
      
        let curModels : [Model] = mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        
     //   pProgress = NSProgress(totalUnitCount: curModel.runstot.integerValue)
        
        
        //self.progressViewController.changeMaxWork(curModel.runstot.integerValue)
        /*
        for i in 0...100 {
           // self.progressViewController?.changeCurWork(i)
           // sleep(1)
            
            dispatch_sync(queue) {
                
              //  self.progressIndicator.doubleValue = progress.fractionCompleted
                self.progressViewController.changeCurWork(i)
                usleep(320000)
            }
            
        }
*/
        
//dispatch_async(queue) {
            let op = PlexusCalculationOperation(nodes: nodesForCalc, withRuns: curModel.runsper, withBurnin: curModel.burnins, withComputes: curModel.runstot)
        
            
            var operr: NSError?
            
            operr = op.calc(self)
    

            if(operr == nil){
                let resultNodes : NSMutableArray = op.getResults(self)
                
                let blankArray = [NSNumber]()
                let blankData = NSKeyedArchiver.archivedDataWithRootObject(blankArray)
                
                var fi = 0
                for fNode in resultNodes {
                    
                    var postCount = [Int](count: 101, repeatedValue: 0)
                    

                    
                    let inNode : BNNode = nodesForCalc[fi]  //FIXME is this the same node???
                    
                    //blank out previous postdata
                    //this shoudl never happen.. safer to blank it than mingle data
                    inNode.setValue(blankData, forKey: "postCount")
                    inNode.setValue(blankData, forKey: "postArray")


                    
                    let fline : [Double] = fNode as! [Double]

                  //  println("fline \(fline)")
                    var gi = 0
                    for gNode : Double in fline {
                    //    println(gNode)
                       
                        if(gNode == gNode && gNode >= 0.0 && gNode <= 1.0) {//fails if nan
                            
                            let whut = (Int)(floor(gNode/0.01))

                            postCount[whut]++

                        }
                        
                        
                        else{
                           // println("problem detected in reloadData. gNode is \(gNode)")
                        }

                        gi++
                    }
                    
                    let archivedPostCount = NSKeyedArchiver.archivedDataWithRootObject(postCount)
                    inNode.setValue(archivedPostCount, forKey: "postCount")
                    let archivedPostArray = NSKeyedArchiver.archivedDataWithRootObject(fline)
                    inNode.setValue(archivedPostArray, forKey: "postArray")
                    
                    
                    
                   // self.moc.save(errorPtr)


                    fi++
                    
                }
                
                let notification:NSUserNotification = NSUserNotification()
                notification.title = "Plexus"
                //notification.subtitle = "Yur stuff are done"
                notification.informativeText = "\(curModel.runstot.integerValue) runs completed."
                
                notification.soundName = NSUserNotificationDefaultSoundName
                
                notification.deliveryDate = NSDate(timeIntervalSinceNow: 5)
                let notificationcenter:NSUserNotificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter()
                
                notificationcenter.scheduleNotification(notification)


            }
            else{
                
                let calcAlert : NSAlert = NSAlert()
                calcAlert.alertStyle = NSAlertStyle.WarningAlertStyle
                calcAlert.messageText = (operr?.localizedFailureReason)!
                calcAlert.informativeText = (operr?.localizedRecoverySuggestion)!
                calcAlert.addButtonWithTitle("OK")
                
              //  let res = calcAlert.runModal()

                
                

        }


            do {
                //FIXME remove when ready curModel.setValue(true, forKey: "complete")
                try self.moc.save()
            } catch let error as NSError {
                errorPtr.memory = error
            }
            
            self.contentViewController?.dismissViewController(self.progressViewController!)
            
            

        
    
        print("End calcuilate fxn")
    }

    
    @IBAction func exportCSV(x:NSToolbarItem){
        let err : NSErrorPointer = nil
        
        let sv:NSSavePanel = NSSavePanel()
        sv.allowedFileTypes = ["csv"]
        
        sv.beginSheetModalForWindow(window!, completionHandler: {(result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                let outFile  = sv.URL
                 print(outFile)
                
                sv.close()
                
                var outText = "Name,"
                
                //Exporting current daatset only
                let curDatasets : [Dataset] = self.datasetController.selectedObjects as! [Dataset]
                let curDataset : Dataset = curDatasets[0]
                //get list of all traits in this dataset
                let trequest = NSFetchRequest(entityName: "Trait")
                let tpredicate = NSPredicate(format: "entry.dataset == %@", curDataset)
                trequest.resultType = .DictionaryResultType
                trequest.predicate = tpredicate
                trequest.returnsDistinctResults = true
                trequest.propertiesToFetch = ["name"]
                
                
                
                do {
                    let headerTraits  = try self.moc!.executeFetchRequest(trequest)
                    //test and print for now
                    for headerTrait in headerTraits {
                       // println(headerTrait.name)
                        
                       outText += headerTrait.valueForKey("name") as! String
                       // outText += headerTrait
                        outText += ","

                    }
                    outText += "\n"
                    let entries : [Entry] = curDataset.entry.allObjects as! [Entry]
                    for entry : Entry in entries {
                        outText += entry.name
                        outText += ","
                        
                        //let traits = entry.trait
                        
                        for _ in headerTraits {
                            
                            
                            /*
                            let ttrequest = NSFetchRequest(entityName: "Trait")
                            var ttpredicate = NSPredicate(format: "entry == %@ AND name == %@", entry, headerTrait.name)
                            
                            if let ttTraits : [Trait] = self.moc!.executeFetchRequest(ttrequest, error:err) as? [Trait]{
                                outText += ttTraits[0].traitValue //should only ever get one anyway
                                
                            }
                            */
                            
                            outText += ","
                            
                        }
                        

                        outText += "\n"
                    }
                    
                    
                    
                    
                    do {
                        try outText.writeToURL(sv.URL!, atomically: true, encoding: NSUTF8StringEncoding)
                    } catch _ {
                    }
                } catch let error as NSError {
                    err.memory = error
                    return
                } catch {
                    fatalError()
                }
                
                //Fetch all Datasets
                /*
                
                let datafetch = NSFetchRequest(entityName: "Dataset")
                let datasets : [Dataset] = self.moc.executeFetchRequest(datafetch, error: err) as! [Dataset]
            
                
                for dataset : Dataset in datasets {
                    let entries : [Entry] = dataset.entry.allObjects as! [Entry]
                    for entry : Entry in entries {
                        entry.name.writeToURL(sv.URL!, atomically: false, encoding: NSUTF8StringEncoding, error: nil)
                        let traits : [Trait] = entry.trait.allObjects as! [Trait]
                        for trait :Trait in traits{
                            
                        }
                    }
                    
                }
                */
                
                

            }
            
            else { return }
        })
        
    }
    
    @IBAction func importCSV(x:NSToolbarItem){
       // println("Tapped: \(x)")
        
        
       // let undoM : NSUndoManager = moc.undoManager!
       // moc.undoManager = nil

        
        let errorPtr : NSErrorPointer = nil
        
        let op:NSOpenPanel = NSOpenPanel()
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true
        op.allowedFileTypes = ["csv"]
        
        //accessory view
        let av:NSButton = NSButton(frame: NSMakeRect(0.0, 0.0, 324.0, 22.0))
        av.setButtonType(NSButtonType.SwitchButton)
        av.title = "Add to Current Dataset"

        op.accessoryView = av
        
        
        op.beginSheetModalForWindow(window!, completionHandler: {(result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                
               // println("button state \(av.state)")
                

               // println(op.URL)
                let inFile  = op.URL
               // println(inFile)
                
                op.close()
                
                var i = 1
                
                var firstLine = true
                
                if (inFile != nil){ // operate on iput file
                    
                    //Create a MOC
                  //  let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
                  //  var inPSC: NSPersistentStoreCoordinator = appDelegate.persistentStoreCoordinator!
                  //  var inMOC = NSManagedObjectContext()
                  //  inMOC.persistentStoreCoordinator = inPSC
                  //  inMOC.undoManager = nil

                    
                    //instatntiate progress controller
                    if self.progressViewController == nil {
                        let storyboard = NSStoryboard(name:"Main", bundle:nil)
                        self.progressViewController = storyboard.instantiateControllerWithIdentifier("ProgressViewController") as? PlexusProgressPanel
                    }
                    self.progressViewController.delegate = self
                  
                    
                    self.contentViewController?.presentViewControllerAsSheet(self.progressViewController!)
                    
                    
                    self.progressViewController?.changeLabel(String("Importing..."))
                    
                    var inDataset : Dataset!
                    if(av.state == 0){//new dataset
                        inDataset = Dataset(entity: NSEntityDescription.entityForName("Dataset", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                        inDataset.setValue(inFile!.lastPathComponent, forKey: "name")
                    }
                    else {// the
                        let curDatasets : [Dataset] = self.datasetController.selectedObjects as! [Dataset]
                        inDataset = curDatasets[0]
                    }
                    



                    
                    do {
                        try self.moc.save()
                    } catch let error as NSError {
                        errorPtr.memory = error
                    } catch {
                        fatalError()
                    }
                    

                    let datasetID = inDataset.objectID

                    
                    //give it an initial model
                    let newModel : Model = Model(entity: NSEntityDescription.entityForName("Model", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                    newModel.setValue("First Model", forKey: "name")
                    newModel.setValue(inDataset, forKey: "dataset")
                    inDataset.addModelObject(newModel)
                    
                    
                    let fileContents : String = (try! NSString(contentsOfFile: inFile!.path!, encoding: NSUTF8StringEncoding)) as String
                    // print(fileContents)
                    let fileLines : [String] = fileContents.componentsSeparatedByString("\n")
                    
                    let lineCount = Double(fileLines.count)
                    
                    var batchCount : Int = 0
                    var columnCount = 0
                    var nameColumn = -1
                    var structureColumn = -1
                    var headers = [String]()
                    
                    for thisLine : String in fileLines {
                        
                        
                        
                        if firstLine {  //this is the header line
                            let theHeader : [String] = thisLine.componentsSeparatedByString(",")
                            for thisHeader in theHeader {
                             //   println(thisHeader)
                                if thisHeader == "Name" {
                                    nameColumn = columnCount
                                }
                                if thisHeader == "Structure" {
                                    structureColumn = columnCount
                                }
                                headers.append(thisHeader)
                                columnCount++
                            }
                            
                        }
                        
                        let newEntry : Entry = Entry(entity: NSEntityDescription.entityForName("Entry", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                        var theTraits : [String] = thisLine.componentsSeparatedByString(",")

                        if nameColumn >= 0{
                            newEntry.setValue(theTraits[nameColumn], forKey: "name")
                        }
                        else {
                            newEntry.setValue(String(i), forKey: "name")
                        }
                        /*
                        if structureColumn >=0 {
                            let strerror = nil
                            let request = NSFetchRequest(entityName: "Structure")
                            let predicate = NSPredicate(format: "dataset == %@ AND name == %@", inDataset, theTraits[structureColumn])
                            let strCount = moc.countForFetchRequest(request, error: strerror)
                            if(strCount == NSNotFound){ //does not exist, create
                                var newStructure : Structure = Structure(entity: NSEntityDescription.entityForName("Structure", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                                
                                newEntry.setValue(inDataset, forKey: "dataset")

                            }
                            else { //exists
                                
                            }
    
                            
                        }
*/
                        
                        newEntry.setValue("Entry", forKey: "type")
                        newEntry.setValue(inDataset, forKey: "dataset")
                        inDataset.addEntryObject(newEntry)

                        

                        columnCount = 0
                        for thisTrait in theTraits {
                            
                            if columnCount == structureColumn {
                               //FIXME check if the streucvture exists, if not make it here
                                

                                
                               // if let fetch = moc!.executeFetchRequest(request, error:&err)
                            }

                            let newTrait : Trait = Trait(entity: NSEntityDescription.entityForName("Trait", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                            newTrait.setValue(headers[columnCount], forKey: "name")
                            newTrait.setValue(thisTrait, forKey: "traitValue")
                            newTrait.setValue(newEntry, forKey: "entry")
                            
                            newEntry.addTraitObject(newTrait)
                            
                            columnCount++
                            
                        }
                        

                        self.progressViewController.moveBar(1/lineCount*100)
   
                        firstLine = false
                        i++
                        batchCount++
                        if(batchCount > 100){
                            do {
                                try self.moc.save()
                            } catch let error as NSError {
                                errorPtr.memory = error
                            } catch {
                                fatalError()
                            }
                            batchCount = 0
                            self.moc.reset()

                            
                            inDataset = self.moc.objectWithID(datasetID) as! Dataset

                            
                        }
                        
                    }
                    
                    
                    
                    do {
                        try self.moc.save()
                    } catch let error as NSError {
                        errorPtr.memory = error
                    } catch {
                        fatalError()
                    }
                    self.moc.reset()
                    
                  //  self.moc.undoManager = undoM
                    
                  //clear controller


                    let datafetch = NSFetchRequest(entityName: "Dataset")
                    let datasets : [Dataset] = try! self.moc.executeFetchRequest(datafetch) as! [Dataset]
                    
                    
                    self.datasetController.addObjects(datasets)

                    inDataset = self.moc.objectWithID(datasetID) as! Dataset

                    
                    let nDarray : [Dataset] = [inDataset]

                    
                    self.datasetController.setSelectedObjects(nDarray)


                    

                    self.contentViewController?.dismissViewController(self.progressViewController!)
                    
                    
                }
                
                
                
            }
            else { return }
        })
            

        
        
        
    }
    

    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject!) {

        if (segue.identifier == "DatasetPopover") {

            let datasetViewController = segue.destinationController as! PlexusDatasetViewController
            datasetViewController.datasetController = self.datasetController
            
        }
    }
    
    func progressViewControllerDidCancel(progressViewController: PlexusProgressPanel) {
        print("Cancelled progress")
        self.contentViewController?.dismissViewController(self.progressViewController!)
    }
    


}
