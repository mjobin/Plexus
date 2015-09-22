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


class PlexusMainWindowController: NSWindowController, NSWindowDelegate {
    
    

  
    var moc : NSManagedObjectContext!
    var mainSplitViewController = PlexusMainSplitViewController()
    @IBOutlet var mainToolbar : NSToolbar!
    @IBOutlet var datasetController : NSArrayController!
    @IBOutlet var testprog : NSProgressIndicator!
    var queue: dispatch_queue_t = dispatch_queue_create("My Queue", DISPATCH_QUEUE_SERIAL)
   // var group : dispatch_group_t = dispatch_group_create()
    
    var progSheet : NSWindow!
    var progInd : NSProgressIndicator!
    var workLabel : NSTextField!
    var curLabel : NSTextField!
    var ofLabel : NSTextField!
    var maxLabel : NSTextField!
    var cancelButton : NSButton!
    
    var breakloop = false
    


    
    override func windowWillLoad() {
        
        //let errorPtr : NSErrorPointer = nil

        //Get MOC from App delegate
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext

        

        
        //create a dataset if there are none
        let request = NSFetchRequest(entityName: "Dataset")
        let fetchedDatasets: [AnyObject]?
        do {
            fetchedDatasets = try moc.executeFetchRequest(request)
        } catch let error as NSError {
            print(error)
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
                print(error)
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

    
    func progSetup(sender: AnyObject) -> NSWindow {
        var retWin : NSWindow!
        
        //sheet programamticaly
        let sheetRect = NSRect(x: 0, y: 0, width: 400, height: 82)
        retWin = NSWindow(contentRect: sheetRect, styleMask: NSTitledWindowMask, backing: NSBackingStoreType.Buffered, `defer`: true)
        let contentView = NSView(frame: sheetRect)
        self.progInd = NSProgressIndicator(frame: NSRect(x: 143, y: 52, width: 239, height: 20))
        
        self.workLabel = NSTextField(frame: NSRect(x: 10, y: 52, width: 64, height: 20))
        workLabel.editable = false
        workLabel.drawsBackground = false
        workLabel.selectable = false
        workLabel.bezeled = false
        workLabel.stringValue = "Working..."
        
        self.cancelButton = NSButton(frame: NSRect(x: 304, y: 12, width: 84, height: 32))
        cancelButton.bezelStyle = NSBezelStyle.RoundedBezelStyle
        cancelButton.title = "Cancel"
        cancelButton.target = self
        cancelButton.action = "cancelProg:"
        
        self.maxLabel = NSTextField(frame: NSRect(x: 60, y: 10, width: 64, height: 20))
        maxLabel.editable = false
        maxLabel.drawsBackground = false
        maxLabel.selectable = false
        maxLabel.bezeled = false
        maxLabel.stringValue = String(0)
        
        self.ofLabel = NSTextField(frame: NSRect(x: 40, y: 10, width: 64, height: 20))
        ofLabel.editable = false
        ofLabel.drawsBackground = false
        ofLabel.selectable = false
        ofLabel.bezeled = false
        ofLabel.stringValue = "of"
        
        self.curLabel = NSTextField(frame: NSRect(x: 10, y: 10, width: 64, height: 20))
        curLabel.editable = false
        curLabel.drawsBackground = false
        curLabel.selectable = false
        curLabel.bezeled = false
        curLabel.stringValue = String(0)
        
        contentView.addSubview(workLabel)
        //contentView.addSubview(curLabel)
        //contentView.addSubview(ofLabel)
        //contentView.addSubview(maxLabel)
        contentView.addSubview(progInd)
        contentView.addSubview(cancelButton)
        
        retWin.contentView = contentView
        
        
        return retWin
    }
    /*
    @IBAction func  progtest(x:NSToolbarItem){

        let testmax = 100
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        
        
        /*
        //sheet programamticaly
        let sheetRect = NSRect(x: 0, y: 0, width: 400, height: 114)
        progSheet = NSWindow(contentRect: sheetRect, styleMask: NSTitledWindowMask, backing: NSBackingStoreType.Buffered, `defer`: true)
        let contentView = NSView(frame: sheetRect)
        let progInd = NSProgressIndicator(frame: NSRect(x: 143, y: 72, width: 239, height: 20))
        
        let workLabel = NSTextField(frame: NSRect(x: 10, y: 72, width: 64, height: 20))
        workLabel.editable = false
        workLabel.drawsBackground = false
        workLabel.selectable = false
        workLabel.bezeled = false
        workLabel.stringValue = "Working..."
        
        let cancelButton = NSButton(frame: NSRect(x: 304, y: 12, width: 84, height: 32))
        cancelButton.bezelStyle = NSBezelStyle.RoundedBezelStyle
        cancelButton.title = "Cancel"
        cancelButton.target = self
        cancelButton.action = "cancelProg:"
        
        let maxLabel = NSTextField(frame: NSRect(x: 60, y: 10, width: 64, height: 20))
        maxLabel.editable = false
        maxLabel.drawsBackground = false
        maxLabel.selectable = false
        maxLabel.bezeled = false
        maxLabel.stringValue = String(testmax)
        
        let ofLabel = NSTextField(frame: NSRect(x: 40, y: 10, width: 64, height: 20))
        ofLabel.editable = false
        ofLabel.drawsBackground = false
        ofLabel.selectable = false
        ofLabel.bezeled = false
        ofLabel.stringValue = "of"
        
        let curLabel = NSTextField(frame: NSRect(x: 10, y: 10, width: 64, height: 20))
        curLabel.editable = false
        curLabel.drawsBackground = false
        curLabel.selectable = false
        curLabel.bezeled = false
        curLabel.stringValue = String(0)
        
        
        contentView.addSubview(curLabel)
        contentView.addSubview(ofLabel)
        contentView.addSubview(maxLabel)
        contentView.addSubview(progInd)
        contentView.addSubview(cancelButton)
        
        progSheet.contentView = contentView
        */
        
        progSheet = self.progSetup(self)
        self.maxLabel.stringValue = String(testmax)
        
        self.window!.beginSheet(progSheet, completionHandler: nil)
        
        progSheet.makeKeyAndOrderFront(self)
        
        progInd.indeterminate = false
        progInd.doubleValue = 0

        progInd.startAnimation(self)
        
        progInd.maxValue =  Double(testmax)
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            for i in 0 ... testmax {
                if(self.breakloop){
                    self.breakloop = false
                    break
                }

                dispatch_async(dispatch_get_main_queue()) {
                    
                    self.progInd.incrementBy(1)
                }
                self.curLabel.stringValue = String(i)
                NSThread.sleepForTimeInterval(0.1)
            }
            
            
            dispatch_async(dispatch_get_main_queue()) {
                self.progInd.indeterminate = true
                self.window!.endSheet(self.progSheet)
                self.progSheet.orderOut(self)
            }
            
        }
        

        
    }
    
    func cancelProg(sender: AnyObject){

        self.breakloop = true
    }
    */
    @IBAction func  calculate(x:NSToolbarItem){
        
        
        
        progSheet = self.progSetup(self)
        self.window!.beginSheet(progSheet, completionHandler: nil)
        progSheet.makeKeyAndOrderFront(self)
        //progInd.doubleValue = 0
        progInd.indeterminate = false
        progInd.startAnimation(self)
        


        

        //collect data
        var nodesForCalc : [BNNode] = mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode]
      
        let curModels : [Model] = mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        
    
        
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
                print(error)
            }
        

        self.window!.endSheet(self.progSheet)
        self.progSheet.orderOut(self)
        
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
                
                
                self.progSheet = self.progSetup(self)
                self.window!.beginSheet(self.progSheet, completionHandler: nil)
                self.progSheet.makeKeyAndOrderFront(self)
                self.progInd.indeterminate = true
                self.workLabel.stringValue = "Exporting..."
                self.progInd.startAnimation(self)
                
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
                
                
                self.window!.endSheet(self.progSheet)
                self.progSheet.orderOut(self)
            }
            
            else { return }
        })
        
    }
    
    @IBAction func importCSV(x:NSToolbarItem){


        
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

                let inFile  = op.URL
                
                op.close()
                
                
                
                var i = 1
                
                var firstLine = true
                
                if (inFile != nil){ // operate on iput file
                    


                    
                    //instatntiate progress controller
                    
                    self.progSheet = self.progSetup(self)
                    self.window!.beginSheet(self.progSheet, completionHandler: nil)
                    self.progSheet.makeKeyAndOrderFront(self)
                    self.progInd.indeterminate = true
                    self.workLabel.stringValue = "Importing..."
                    self.progInd.startAnimation(self)


                    
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
                        print(error)
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
                    
                    
                    self.progInd.indeterminate = false
                    self.progInd.maxValue =  Double(fileLines.count)
                    self.progInd.doubleValue = 0
                    
                    self.maxLabel.stringValue = String(fileLines.count)
                    self.curLabel.stringValue = String(0)
                    

                    
                    
                    var batchCount : Int = 0
                    var columnCount = 0
                    var nameColumn = -1
                    var structureColumn = -1
                    var headers = [String]()

                    
                        for thisLine : String in fileLines {
                            
                            if(self.breakloop){
                                self.breakloop = false
                                break
                            }
                            
                            
                            
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
                            


       
                            firstLine = false
                            i++


                            
                                batchCount++
                            
                            if(batchCount > 100){
                                do {
                                    try self.moc.save()
                                } catch let error as NSError {
                                    print(error)
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
                            print(error)
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


    
                    self.window!.endSheet(self.progSheet)
                    self.progSheet.orderOut(self)
                    
                    
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
    

    



}
