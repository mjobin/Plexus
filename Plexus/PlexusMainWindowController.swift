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


class PlexusMainWindowController: NSWindowController, ProgressViewControllerDelegate {
    
    

  
    var moc : NSManagedObjectContext!
    var mainSplitViewController = PlexusMainSplitViewController()
    var progressViewController : PlexusProgressPanel!
    @IBOutlet var datasetController : NSArrayController!
    //var pProgress: NSProgress?
    var queue: dispatch_queue_t = dispatch_queue_create("My Queue", DISPATCH_QUEUE_SERIAL)
    


    
    override func windowWillLoad() {

        //Get MOC from App delegate
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext

        

        
        //create a dataset if there are none
        let request = NSFetchRequest(entityName: "Dataset")
        var anyError: NSError?
        let fetchedDatasets = moc.executeFetchRequest(request, error:&anyError)
        
        if fetchedDatasets == nil {
            println("error")

        }
        
        let initDatasets = fetchedDatasets as! [NSManagedObject]
        if(initDatasets.count == 0){
            println("no datasets")
            //so make an initial one
            let newDataset = NSEntityDescription.insertNewObjectForEntityForName("Dataset", inManagedObjectContext: moc) as! NSManagedObject

            var newModel = NSEntityDescription.insertNewObjectForEntityForName("Model", inManagedObjectContext: moc) as! NSManagedObject
            newModel.setValue("newmodel", forKey: "name")
            newModel.setValue(newDataset, forKey: "dataset")
            newModel.setValue(NSDate(), forKey: "dateCreated")
            newModel.setValue(NSDate(), forKey: "dateModded")
            moc.save(&anyError)

        }


        
        
        
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()


        
        mainSplitViewController = contentViewController as! PlexusMainSplitViewController
        //mainSplitViewController.mainWindowController = self
        mainSplitViewController.datasetController = self.datasetController
       // println(self.datasetController)
        //println(mainSplitViewController.datasetController)
        
        
     //   println(datasetController!.selectionIndexes)
        
       // datasetController!.setSelectionIndex(0)

        
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func  copyDataset(x:NSToolbarItem){
        println("copy dataset Tapped: \(x)")
        
    }
    
    @IBAction func  toggleModels(x:NSToolbarItem){
        //println("Toggle models Tapped: \(x)")

        mainSplitViewController.toggleModels(x)
        
    }
    

    
    @IBAction func  calculate(x:NSToolbarItem){
        var errorPtr : NSErrorPointer = nil
        
        var i : Int = 0
        
        

        //instatntiate progress controller
        if self.progressViewController == nil {
            let storyboard = NSStoryboard(name:"Main", bundle:nil)

            self.progressViewController = storyboard!.instantiateControllerWithIdentifier("ProgressViewController") as? PlexusProgressPanel
            
        }
        self.progressViewController?.delegate = self
        

        
        self.contentViewController?.presentViewControllerAsSheet(self.progressViewController!)
        //swap it in?
        
        self.progressViewController?.changeLabel(String("Calculating..."))
        

        
        

        //collect data
        var nodesForCalc : [BNNode] = mainSplitViewController.modelTabViewController?.bnSplitViewController?.nodesController.arrangedObjects as! [BNNode]
      
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
        

        var op = PlexusCalculationOperation(nodes: nodesForCalc, withRuns: curModel.runsper, withBurnin: curModel.burnins, withComputes: curModel.runstot)

        
        var operr: NSError?
        
        operr = op.calc(self)

        if(operr == nil){
          //  println("no prob")
            var resultNodes : NSMutableArray = op.getResults(self)
            
            
            var fi = 0
            for fNode in resultNodes {
                
                var postCount = [Int](count: 101, repeatedValue: 0)
                
                var curtop = 0
                
                var inNode : BNNode = nodesForCalc[fi]  //FIXME is this the same node???
                
                var fline : [Double] = fNode as! [Double]

                
                var gi = 0
                for gNode : Double in fline {
                    
                   
                    if(gNode == gNode && gNode >= 0.0 && gNode <= 1.0) {//fails if nan
                        
                        let whut = (Int)(floor(gNode/0.01))

                        postCount[whut]++

                    }
                    
                    
                    else{
                        println("problem detected in reloadData. gNode is \(gNode)")
                    }

                    gi++
                }
                
                let archivedPostCount = NSKeyedArchiver.archivedDataWithRootObject(postCount)
                inNode.setValue(archivedPostCount, forKey: "postCount")
                let archivedPostArray = NSKeyedArchiver.archivedDataWithRootObject(fline)
                inNode.setValue(archivedPostArray, forKey: "postArray")
                
                moc.save(errorPtr)

                fi++
                
            }


        }


        curModel.setValue(true, forKey: "complete")
        moc.save(errorPtr)
        
        self.contentViewController?.dismissViewController(self.progressViewController!)
        
        
        var notification:NSUserNotification = NSUserNotification()
        notification.title = "Plexus"
        notification.subtitle = "Yur stuff are done"
        notification.informativeText = "\(curModel.runstot.integerValue) runs completed."
        
        notification.soundName = NSUserNotificationDefaultSoundName
        
        notification.deliveryDate = NSDate(timeIntervalSinceNow: 5)
        var notificationcenter:NSUserNotificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter()

        notificationcenter.scheduleNotification(notification)
        
        
        
    }
    
    @IBAction func exportCSV(x:NSToolbarItem){
        var errorPtr : NSErrorPointer = nil
        
        let sv:NSSavePanel = NSSavePanel()
        sv.allowedFileTypes = ["csv"]
        
        sv.beginSheetModalForWindow(window!, completionHandler: {(result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                var outFile  = sv.URL
                 println(outFile)
                
                sv.close()
                
                //Fetch all Datasets
                
                let datafetch = NSFetchRequest(entityName: "Dataset")
                let datasets : [Dataset] = self.moc.executeFetchRequest(datafetch, error: errorPtr) as! [Dataset]
                
                for dataset : Dataset in datasets {
                    let entries : [Entry] = dataset.entry.allObjects as! [Entry]
                    for entry : Entry in entries {
                        entry.name.writeToURL(sv.URL!, atomically: false, encoding: NSUTF8StringEncoding, error: nil)
                    }
                    
                }
                
                

            }
            
            else { return }
        })
        
    }
    
    @IBAction func importCSV(x:NSToolbarItem){
       // println("Tapped: \(x)")
        
        
       // let undoM : NSUndoManager = moc.undoManager!
       // moc.undoManager = nil

        
        var errorPtr : NSErrorPointer = nil
        
        let op:NSOpenPanel = NSOpenPanel()
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true
        op.allowedFileTypes = ["csv"]

        
        op.beginSheetModalForWindow(window!, completionHandler: {(result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                

               // println(op.URL)
                var inFile  = op.URL
               // println(inFile)
                
                op.close()
                
                var i = 1
                
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
                        self.progressViewController = storyboard!.instantiateControllerWithIdentifier("ProgressViewController") as? PlexusProgressPanel
                    }
                    self.progressViewController.delegate = self
                  
                    
                    
                    
                    
                    self.contentViewController?.presentViewControllerAsSheet(self.progressViewController!)
                    
                    
                    self.progressViewController?.changeLabel(String("Importing..."))
                    
                    var newDataset : Dataset = Dataset(entity: NSEntityDescription.entityForName("Dataset", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                    
                    newDataset.setValue(inFile!.lastPathComponent, forKey: "name")



                    
                    self.moc.save(errorPtr)
                    

                    let datasetID = newDataset.objectID


                    
                    //give it an initial model
                    var newModel : Model = Model(entity: NSEntityDescription.entityForName("Model", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                    newModel.setValue("First Model", forKey: "name")
                    newModel.setValue(newDataset, forKey: "dataset")
                    newDataset.addModelObject(newModel)
                    
                    
                    let fileContents : String = NSString(contentsOfFile: inFile!.path!, encoding: NSUTF8StringEncoding, error: nil)! as String
                    // print(fileContents)
                    var fileLines : [String] = fileContents.componentsSeparatedByString("\n")
                    
                    var lineCount = Double(fileLines.count)
                    
                    var batchCount : Int = 0
                    
                    for thisLine : String in fileLines {
                        var newEntry : Entry = Entry(entity: NSEntityDescription.entityForName("Entry", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                        // newEntry.setValue("test", forKey: "name")
                        newEntry.setValue(String(i), forKey: "name")
                        newEntry.setValue("PlexusEntry", forKey: "icon")
                        //newEntry.setValue(NSImage(named: "PlexusTest.png"), forKey: "icon")
                        newEntry.setValue(newDataset, forKey: "dataset")
                        newDataset.addEntryObject(newEntry)
                        //  println(thisLine)
                        //  println("\n********************************************\n")
                        
                        var theTraits : [String] = thisLine.componentsSeparatedByString(",")
                        for thisTrait in theTraits {
                            //println(thisTrait)
                            var newTrait : Trait = Trait(entity: NSEntityDescription.entityForName("Trait", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                            newTrait.setValue("test", forKey: "name")
                            newTrait.setValue(thisTrait, forKey: "value")
                            newTrait.setValue(newEntry, forKey: "entry")
                            
                            newEntry.addTraitObject(newTrait)
                            
                        }
                        

                        self.progressViewController.moveBar(1/lineCount*100)
   

                        i++
                        batchCount++
                        if(batchCount > 100){
                            self.moc.save(errorPtr)
                            batchCount = 0
                            self.moc.reset()

                            
                            newDataset = self.moc.objectWithID(datasetID) as! Dataset



                            
                            
                        }
                    }
                    
                    
                    
                    self.moc.save(errorPtr)
                    self.moc.reset()
                    
                  //  self.moc.undoManager = undoM
                    
                  //clear controller


                    let datafetch = NSFetchRequest(entityName: "Dataset")
                    let datasets : [Dataset] = self.moc.executeFetchRequest(datafetch, error: errorPtr) as! [Dataset]
                    
                    
                    self.datasetController.addObjects(datasets)

                    newDataset = self.moc.objectWithID(datasetID) as! Dataset

                    
                    let nDarray : [Dataset] = [newDataset]

                    
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
        println("Cancelled progress")
        self.contentViewController?.dismissViewController(self.progressViewController!)
    }
    


}
