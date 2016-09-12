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
    @IBOutlet var testprog : NSProgressIndicator!

    
    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
    
    let calcop = PlexusCalculationOperation()

    
    var progSheet : NSWindow!
    var progInd : NSProgressIndicator!
    var workLabel : NSTextField!
    var curLabel : NSTextField!
    var ofLabel : NSTextField!
    var maxLabel : NSTextField!
    var cancelButton : NSButton!
    
    var breakloop = false
    
    dynamic var entryTreeController : NSTreeController!
    

    
    override func windowWillLoad() {
        
        //let errorPtr : NSErrorPointer = nil

        //Get MOC from App delegate
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext

        
        
    //    NSNotificationCenter.defaultCenter().addObserver(self, selector: "mocDidChange:", name: NSManagedObjectContextDidSaveNotification, object: nil)
        

        let request = NSFetchRequest(entityName: "Model")
        let fetchedModels: [AnyObject]?
        do {
            fetchedModels = try moc.executeFetchRequest(request)
        } catch let error as NSError {
            print(error)
            fetchedModels = nil
        }
        
        if fetchedModels == nil {
            print("error")

        }
        
        let initModels = fetchedModels as! [NSManagedObject]
        if(initModels.count == 0){

            //so make an initial one


            let newModel = NSEntityDescription.insertNewObjectForEntityForName("Model", inManagedObjectContext: moc) 
            newModel.setValue("newmodel", forKey: "name")
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


        
    

        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            let operr = self.calcop.clCompile();
            
           if(operr != nil){
                
                let calcAlert : NSAlert = NSAlert()
                calcAlert.alertStyle = NSAlertStyle.WarningAlertStyle
                calcAlert.messageText = (operr?.localizedFailureReason)!
                calcAlert.informativeText = (operr?.localizedRecoverySuggestion)!
                calcAlert.addButtonWithTitle("OK")
                
                let _ = calcAlert.runModal()

            }
            
        }
        
        
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
                    let x = (Int)(floor(gNode/0.01))
                    postCount[x] += 1
                }
                    
                    
                else{
                    // println("problem detected in reloadData. gNode is \(gNode)")
                }
                
                gi += 1
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
        retWin = NSWindow(contentRect: sheetRect, styleMask: NSTitledWindowMask, backing: NSBackingStoreType.Buffered, defer: true)
        let contentView = NSView(frame: sheetRect)
        self.progInd = NSProgressIndicator(frame: NSRect(x: 143, y: 52, width: 239, height: 20))
        self.progInd.canDrawConcurrently = true
        self.progInd.indeterminate = false
        self.progInd.usesThreadedAnimation = true
        
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
        cancelButton.action = #selector(PlexusMainWindowController.cancelProg(_:))
        
        self.maxLabel = NSTextField(frame: NSRect(x: 138, y: 10, width: 64, height: 20))
        maxLabel.editable = false
        maxLabel.drawsBackground = false
        maxLabel.selectable = false
        maxLabel.bezeled = false
        maxLabel.stringValue = String(0)
        
        self.ofLabel = NSTextField(frame: NSRect(x: 74, y: 10, width: 64, height: 20))
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
        contentView.addSubview(curLabel)
        contentView.addSubview(ofLabel)
        contentView.addSubview(maxLabel)
        contentView.addSubview(progInd)
        contentView.addSubview(cancelButton)
        
        retWin.contentView = contentView
        
        
        return retWin
    }
    
    
    
    
    
    @IBAction func  importCSV(x:NSToolbarItem){


        self.mainSplitViewController.entryTreeController.fetch(self)
        
        
        //Open panel for .csv files only
        let op:NSOpenPanel = NSOpenPanel()
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true
        op.allowedFileTypes = ["csv"]
        
        //accessory view to allow addition to current locaiton
        let av:NSButton = NSButton(frame: NSMakeRect(0.0, 0.0, 324.0, 22.0))
        av.setButtonType(NSButtonType.SwitchButton)
        av.title = "Add as child of current selection"
        av.state = 0
        op.accessoryView = av
        if #available(OSX 10.11, *) {
            op.accessoryViewDisclosed = true
        } else {
            op.accessoryView?.hidden = false
        }
        
        let result = op.runModal()
        

        
        op.close()
        

        
        if (result == NSFileHandlingPanelOKButton) {
            var i = 1
            var firstLine = true
            let inFile  = op.URL
            let inFileBase = inFile?.URLByDeletingPathExtension

            
            var curEntry : Entry!
            
            if(av.state == 0){//New entires will be added as a child of an entry given the name of the input file
                curEntry = Entry(entity: NSEntityDescription.entityForName("Entry", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                curEntry.setValue(inFileBase?.lastPathComponent, forKey: "name")
            }
            
            else { //New Entries will be added as children of current entry.
                let curEntries : [Entry] = self.mainSplitViewController.entryTreeController.selectedObjects as! [Entry]
                if(curEntries.count > 0){
                    curEntry  = curEntries[0]
                }
                else {
                    curEntry = Entry(entity: NSEntityDescription.entityForName("Entry", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                   curEntry.setValue(inFileBase?.lastPathComponent, forKey: "name")
                }
                
            }
            
            

            do {
                try self.moc.save()
            } catch let error as NSError {
                print(error)
            } catch {
                fatalError()
            }
            
            
            let curEntryID = curEntry.objectID
            
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                
                
                //create moc

                let inMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                inMOC.undoManager = nil
                inMOC.persistentStoreCoordinator = self.moc.persistentStoreCoordinator

                let parentEntry : Entry = inMOC.objectWithID(curEntryID) as! Entry


                
                let fileContents : String = (try! NSString(contentsOfFile: inFile!.path!, encoding: NSUTF8StringEncoding)) as String
                let fileLines : [String] = fileContents.componentsSeparatedByString("\n")
                
                
                let delimiterCharacterSet = NSMutableCharacterSet(charactersInString: ",\"")
                delimiterCharacterSet.formUnionWithCharacterSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

                var batchCount : Int = 0
                var columnCount = 0
                var nameColumn = -1
                var structureColumn = -1
                var latitudeColumn = -1
                var longitudeColumn = -1
                var headers = [String]()
                var existingStructures = [Structure]()
                var existingStructureNames = [String]() //for speed
                
                
                let request = NSFetchRequest(entityName: "Structure")
                do{
                    existingStructures = try self.moc.executeFetchRequest(request) as! [Structure]

                    } catch let error as NSError {
                        print(error)
                }
                
                for curStructure :Structure in existingStructures {
                    existingStructureNames.append(curStructure.name)
                }
            
                self.progSheet = self.progSetup(self)
                self.maxLabel.stringValue = String(fileLines.count)
                self.window!.beginSheet(self.progSheet, completionHandler: nil)
                self.progSheet.makeKeyAndOrderFront(self)
                self.progInd.indeterminate = false
                self.progInd.doubleValue = 0
                self.workLabel.stringValue = "Importing..."
                self.progInd.startAnimation(self)
                

                self.progInd.maxValue =  Double(fileLines.count)
                    

                for thisLine : String in fileLines {

                    if(self.breakloop){
                        self.breakloop = false
                        break
                    }
                    
                    if firstLine {  //this is the header line
                        
                        let theHeader : [String] = thisLine.componentsSeparatedByString(",")
                        for thisHeader in theHeader {
                            if thisHeader == "Name" {
                                nameColumn = columnCount
                            }
                            if thisHeader == "Structure" {
                                structureColumn = columnCount
                            }
                            if thisHeader == "Latitude" {
                                latitudeColumn = columnCount
                            }
                            if thisHeader == "Longitude" {
                                longitudeColumn = columnCount
                            }
                            headers.append(thisHeader.stringByTrimmingCharactersInSet(delimiterCharacterSet))
                            columnCount += 1
                        }
                        
                        
                    }
                        
                    else {
                        
                        
                        if(thisLine.stringByTrimmingCharactersInSet(delimiterCharacterSet) != "" ){ //ignore lines that are blank and/or only contain commas
                            
                            let newEntry : Entry = Entry(entity: NSEntityDescription.entityForName("Entry", inManagedObjectContext: inMOC)!, insertIntoManagedObjectContext: inMOC)
                            
 
                            var theTraits : [String] = thisLine.componentsSeparatedByString(",")
                            
                            
                            
                            if(theTraits.count != columnCount){
                                
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    

                                    self.window!.endSheet(self.progSheet)
                                    self.progSheet.orderOut(self)
                                    
                                    let question = NSLocalizedString("Line \(i) has \(theTraits.count) entries, while the header line has \(columnCount) entries", comment: "Non-matching line sizes")
                                    let info = NSLocalizedString("Make sure that you use tab (\t) for multiple entries within a cell, and newlines (\n) for the end of each line", comment: "Non-matching line sizes");
                                    let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                                    let alert = NSAlert()
                                    alert.messageText = question
                                    alert.informativeText = info
                                    
                                    alert.addButtonWithTitle(cancelButton)
                                    
                                    let _ = alert.runModal()


                                    
                                }
                                
                                return

                            }
                            
                            
                            if nameColumn >= 0{
                                newEntry.setValue(theTraits[nameColumn], forKey: "name")
                            }
                            else {
                                newEntry.setValue(String(i), forKey: "name")
                            }
                            
                            if latitudeColumn >= 0 {
                            
                                newEntry.setValue(Float(theTraits[latitudeColumn]), forKey: "latitude")
                            }
                            
                            if longitudeColumn >= 0 {
                                newEntry.setValue(Float(theTraits[longitudeColumn]), forKey: "longitude")
                            }
                            
                            if (structureColumn >= 0 ) {
                                let theSubStructures : [String] = theTraits[structureColumn].componentsSeparatedByString("\t")
                                for thisSubStructure in theSubStructures {
                                    if(existingStructureNames.contains(thisSubStructure)){
                                        for chkStructure in existingStructures {
                                            if (chkStructure.name == thisSubStructure){
                                                chkStructure.addEntryObject(newEntry)
                                                //  an entry is part of EACH structure of that name
                                            }
                                        }
                                        
                                    }
                                    else{ // a new stuetcure must be made, and added to exisitngStructures and existingStructureNames
                                        let newStructure : Structure = Structure(entity: NSEntityDescription.entityForName("Structure", inManagedObjectContext: inMOC)!, insertIntoManagedObjectContext: inMOC)
                                        newStructure.setValue(thisSubStructure, forKey: "name")
                                        newStructure.addEntryObject(newEntry)
                                        existingStructures.append(newStructure)
                                        existingStructureNames.append(newStructure.name)
                                    }
                                }
                                
                            }
                            
                            
                            
                            newEntry.setValue("Entry", forKey: "type")
                            
                          //  if(av.state == 1){
                                newEntry.setValue(parentEntry, forKey: "parent")
                                parentEntry.addChildObject(newEntry)
                          //  }

                            


                            
                            columnCount = 0
                            for thisTrait in theTraits {
                                //  print(thisTrait)
                                
                                if(columnCount != nameColumn && columnCount != structureColumn && columnCount != longitudeColumn && columnCount != latitudeColumn){
                                    
                                    let theSubTraits : [String] = thisTrait.componentsSeparatedByString("\t")
                                    
                                    for thisSubTrait in theSubTraits {
                                        //  print(thisSubTrait)
                                        if(thisSubTrait.stringByTrimmingCharactersInSet(delimiterCharacterSet) != "" ){//ignore empty
                                            let newTrait : Trait = Trait(entity: NSEntityDescription.entityForName("Trait", inManagedObjectContext: inMOC)!, insertIntoManagedObjectContext: inMOC)
                                            newTrait.setValue(headers[columnCount], forKey: "name")
                                            newTrait.setValue(thisSubTrait.stringByTrimmingCharactersInSet(delimiterCharacterSet), forKey: "traitValue")
                                            newTrait.setValue(newEntry, forKey: "entry")
                                            
                                            newEntry.addTraitObject(newTrait)
                                        }
                                    }
                                    
                                    
                                }
                                
                                
                                
                                columnCount += 1
                                
                            }
                            

 

                            
                        }
                        
                    }


                    dispatch_async(dispatch_get_main_queue()) {
                        
                        self.progInd.incrementBy(1)
                        self.curLabel.stringValue = String(i)

                    }
                    

                    firstLine = false
                    i += 1
                    


                    
                    batchCount += 1
                    if(batchCount > 100){
                        

                        
                        
                        
                        do {
                            try inMOC.save()
                        } catch let error as NSError {
                            print(error)
                        } catch {
                            fatalError()
                        }
                        batchCount = 0
                        inMOC.reset()
     
                        

                        
                    }
 


                    
                }
                
                
                

 
                
                
                    do {
                        try inMOC.save()
                    } catch let error as NSError {
                        print(error)
                    } catch {
                        fatalError()
                    }
                
                

                    inMOC.reset()
                
                

                

                    dispatch_async(dispatch_get_main_queue()) {
                        
                        self.progInd.indeterminate = true
                        self.progInd.startAnimation(self)
                        self.window!.endSheet(self.progSheet)
                        self.progSheet.orderOut(self)
                        
                        
                        self.moc.reset()



                        
                        
                        self.mainSplitViewController.entryTreeController.fetch(self)
                        

                        
                    }
                
                
                
            }
            
            

            
            
            
        }
        

        
    }

    func cancelProg(sender: AnyObject){

        self.breakloop = true
    }
    
    @IBAction func  calculate(x:NSToolbarItem){
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        
        //collect data
        var nodesForCalc : [BNNode] = mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode]
        let curModels : [Model] = mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            let starttime = NSDate.timeIntervalSinceReferenceDate();
            
            self.progSheet = self.progSetup(self)
            self.maxLabel.stringValue = String(curModel.runstot)
            self.window!.beginSheet(self.progSheet, completionHandler: nil)
            self.progInd.indeterminate = false
            self.progInd.doubleValue = 0
            self.progInd.maxValue =  Double(curModel.runstot)
            self.progSheet.makeKeyAndOrderFront(self)

            
        

            var operr: NSError?
            
            operr = self.calcop.calc(self.progInd, withCurLabel: self.curLabel, withWorkLabel: self.workLabel, withNodes: nodesForCalc, withRuns: curModel.runsper, withBurnin: curModel.burnins, withComputes: curModel.runstot)
            
            self.progInd.indeterminate = true
            self.progInd.startAnimation(self)
            self.workLabel.stringValue = "Saving..."

    
            if(operr == nil){
                let resultNodes : NSMutableArray = self.calcop.getResults(self)
                
                let blankArray = [NSNumber]()
                let blankData = NSKeyedArchiver.archivedDataWithRootObject(blankArray)
                
                var bins = Int(pow(Double(curModel.runstot), 0.5))
                
                if(bins < 100) {
                    bins = 100
                }
                
                let binQuotient = 1.0/Double(bins)
            
                bins = bins + 1 //one more bin for anything that is a 1.0
                
                var fi = 0
                for fNode in resultNodes {
                
                   // print("\n\n\n\n\n\n\n\n\n\n\n\n************\(fi)")
                    
                    var postCount = [Int](count: bins, repeatedValue: 0)
                    

                    
                    let inNode : BNNode = nodesForCalc[fi]  //FIXME is this the same node???
                    
                    //blank out previous postdata
                    //this shoudl never happen.. safer to blank it than mingle data
                    inNode.setValue(blankData, forKey: "postCount")
                    inNode.setValue(blankData, forKey: "postArray")


                    
                    let fline : [Double] = fNode as! [Double]


                    var gi = 0
                    for gNode : Double in fline {

                       
                        if(gNode == gNode && gNode >= 0.0 && gNode <= 1.0) {//fails if nan
                            
                            let x = (Int)(floor(gNode/binQuotient))
                            //print ("result: \(gNode)  bin:\(x)")
                            postCount[x] += 1

                        }
                        
                        
                        else{
                           // println("problem detected in reloadData. gNode is \(gNode)")
                        }

                        gi += 1
                    }
                    
                    let archivedPostCount = NSKeyedArchiver.archivedDataWithRootObject(postCount)
                    inNode.setValue(archivedPostCount, forKey: "postCount")
                    
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    let preserveRO = defaults.valueForKey("preserveRawOutput") as! Int

                    if(preserveRO == 1){
                        let archivedPostArray = NSKeyedArchiver.archivedDataWithRootObject(fline)
                        inNode.setValue(archivedPostArray, forKey: "postArray")
                    }

                    fi += 1
                    
                }
                
                let notification:NSUserNotification = NSUserNotification()
                notification.title = "Plexus"
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
                
                let _ = calcAlert.runModal()

                


        }

            
            dispatch_async(dispatch_get_main_queue()) {
                

                /*
                
                do {
                    //FIXME remove when ready curModel.setValue(true, forKey: "complete")
                    try self.moc.save()
                } catch let error as NSError {
                    print(error)
                }
                */
                
                self.window!.endSheet(self.progSheet)
                self.progSheet.orderOut(self)

            }
            

        

            let endtime = NSDate.timeIntervalSinceReferenceDate();
            let interval = endtime-starttime
            print("Calculation took \(interval) seconds");
        }
        
       // print("End calcuilate fxn reached")
    }

    
    @IBAction func exportCSV(x:NSToolbarItem){
        let err : NSErrorPointer = nil
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        

        
        let curModels : [Model] = self.mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let pTypes = defaults.arrayForKey("PriorTypes") as! [String]
        
        let sv:NSSavePanel = NSSavePanel()
        sv.nameFieldStringValue = curModel.name
        
        
        let result = sv.runModal()
        sv.close()
        
        if (result == NSFileHandlingPanelOKButton) {
           
            let baseFile  = sv.URL?.absoluteString
            let outFileName = baseFile! + "-data.csv"

            let outURL = NSURL(string: outFileName)
            

            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                
                let request = NSFetchRequest(entityName: "Entry")
                do {
                    let entries : [Entry] = try self.moc!.executeFetchRequest(request) as! [Entry]
                    
                    self.progSheet = self.progSetup(self)
                    self.maxLabel.stringValue = String(entries.count)
                    self.window!.beginSheet(self.progSheet, completionHandler: nil)
                    self.progSheet.makeKeyAndOrderFront(self)
                    self.progInd.indeterminate = true
                    self.workLabel.stringValue = "Exporting Entries..."
                    self.progInd.doubleValue = 0
                    
                    self.progInd.startAnimation(self)
                    
                    
                    self.progInd.maxValue =  Double(entries.count)
                    
                    
                    self.progInd.startAnimation(self)
                    
                    var outText = "Name,"
                    
                    
                    let trequest = NSFetchRequest(entityName: "Trait")
                    
                    
                    var i = 0
                    
                    do {
                        let headerTraits : [Trait] = try self.moc!.executeFetchRequest(trequest) as! [Trait]
                        
                        let distinctHeaderTraits = NSSet(array: headerTraits.map { $0.name })
                        
                        
                        for headerTrait in distinctHeaderTraits {
                            outText += headerTrait as! String
                            
                            
                            outText += ","
                            
                        }
                        outText += "\n"
                        
                        self.progInd.indeterminate = false
                        
                        for entry : Entry in entries {
                            outText += entry.name
                            outText += ","
                            
                            let tTraits = entry.trait
                            for headerTrait in distinctHeaderTraits {
                                let hKey = headerTrait as! String
                                
                                
                                
                                var traitString = [String]()
                                for tTrait in tTraits{
                                    let tKey = tTrait.valueForKey("name") as! String
                                    if hKey == tKey{
                                        //outText += tTrait.valueForKey("traitValue") as! String
                                        //outText += "\t"
                                        traitString.append(tTrait.valueForKey("traitValue") as! String)
                                    }
                                    
                                    
                                }
                                if(traitString.count > 1){
                                    outText += "\""
                                }
                                var k = 1
                                for thisTraitString in traitString {
                                    outText += thisTraitString
                                    if(traitString.count > 1 && k < traitString.count){
                                        outText += "\r"
                                    }
                                    k += 1
                                }
                                
                                if(traitString.count > 1){
                                    outText += "\""
                                }
                                
                                
                                outText += ","
                            }
                            
                            
                            outText += "\n"
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                self.progInd.incrementBy(1)
                                self.curLabel.stringValue = String(i)
                                
                            }
                            i += 1
                            
                        }
                        
                        
                        
                        do {
                            try outText.writeToURL(outURL!, atomically: true, encoding: NSUTF8StringEncoding)
                        } catch _ {
                        }
                    } catch let error as NSError {
                        err.memory = error
                        return
                    } catch {
                        fatalError()
                    }
                    
                    
                }catch let error as NSError {
                        err.memory = error
                        return
                    } catch {
                        fatalError()
                    }
                
            


                
                //now print nodes
               // let outDir = sv.directoryURL?.absoluteString
               // let baseDir = outFile.absoluteString
                dispatch_async(dispatch_get_main_queue()) {
                
                    self.progInd.indeterminate = true
                    self.progInd.startAnimation(self)
                    self.workLabel.stringValue = "Exporting Nodes..."
                    
                    var i = 0
                    
                    let nodeTXTFileName = baseFile! + "-nodes.csv"
                    let nodeTXTURL = NSURL(string: nodeTXTFileName)
                    var outText : String = String()

                    for node in self.mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode] {
                        self.mainSplitViewController.modelDetailViewController?.nodesController.setSelectionIndex(i) //FIXME wont work on a background thread

                        
                        outText += "********\n"
                        
                        outText += "Node:,"
                        outText += node.nodeLink.name
                        outText += "\n"

                        
                        let infBy = node.influencedBy.count
                        if (infBy < 1) { //independent node, print prior info
                            
                            outText += "Prior Type,"
                            outText += pTypes[node.priorDistType as Int]
                            outText += "\n"
                            
                            outText += "Prior V1,"
                            outText += String(node.priorV1)
                            outText += "\n"
                            
                            outText += "Prior V2,"
                            outText += String(node.priorV2)
                            outText += "\n"
                            
                            if node.priorArray != nil {
                                outText += "Prior Distribution,"
                                let priorArray = NSKeyedUnarchiver.unarchiveObjectWithData(node.valueForKey("priorArray") as! NSData) as! [Int]
                                
                                
                                for thisPrior in priorArray {
                                    outText += String(thisPrior)
                                    outText += ","
                                }
                                outText += "\n"
                                
                            }
                            
                        }
                        
                        if node.postCount != nil {
                            outText += "Posterior Count Bin,"
                            let postCount = NSKeyedUnarchiver.unarchiveObjectWithData(node.valueForKey("postCount") as! NSData) as! [Int]
                            let postBins = Double(postCount.count)
                            
                            var binc = 0.0
                            for _ in postCount {
                                outText += String(binc/postBins)
                                outText += ","
                                binc = binc + 1
                            }
                            outText += "\n"
                            outText += "Posterior Count,"
                            for thisPost in postCount {
                                outText += String(thisPost)
                                outText += ","
                            }
                            outText += "\n"

                        }
                        
                        if node.postArray != nil {
                            
                            
                            outText += "Posterior Distribution,"
                            let postArray = NSKeyedUnarchiver.unarchiveObjectWithData(node.valueForKey("postArray") as! NSData) as! [Double]

                            
                            for thisPost in postArray {
                                outText += String(thisPost)
                                outText += ","
                            }
                            outText += "\n"
                            
                        }
                        
                        outText += "\n"
                        
                        
                        do {
                            try outText.writeToURL(nodeTXTURL!, atomically: true, encoding: NSUTF8StringEncoding)
                        }
                        catch let error as NSError {
                            print(error)
                        } catch {
                            fatalError()
                        }
                        
                        //create a compound of the outFile name and node name
                        let nodePDFFileName = baseFile! + "-" + node.nodeLink.name + ".pdf"
                        let nodeURL = NSURL(string: nodePDFFileName)

                        
                        let graphView = self.mainSplitViewController.modelDetailViewController?.graphView
                        graphView?.frame = NSMakeRect(0, 0, 800, 600)
                        
                        
                        let graph = self.mainSplitViewController.modelDetailViewController?.graph
                        
                        graph?.frame = NSMakeRect(0, 0, 800, 600)
                        
                        graph?.paddingTop = 10.0
                        graph?.paddingBottom = 10.0
                        graph?.paddingLeft = 10.0
                        graph?.paddingRight = 10.0
                        

                        


                        
                        /*

                        
                        
                         let titleStyle = CPTMutableTextStyle()
                         titleStyle.fontName = "SanFrancisco"
                         titleStyle.fontSize = 18.0
                         titleStyle.color = CPTColor.blackColor()
                         graph?.titleTextStyle = titleStyle
                         graph?.title = node.nodeLink.name
                         print ("title \(graph?.title)")
                        
                         let plotSpace : CPTXYPlotSpace = graph?.defaultPlotSpace as! CPTXYPlotSpace
                         plotSpace.allowsUserInteraction = false
                         
                         
                         let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
                         let yRange = plotSpace.yRange.mutableCopy() as! CPTMutablePlotRange
                         
                         xRange.length = 1.1
                         yRange.length = 1.1
                         
                         
                         plotSpace.xRange = xRange
                         plotSpace.yRange = yRange

                                                 plotSpace.scaleToFitPlots(graph?.allPlots())
                        
                        
                        
                        
                        for plot in (graph?.allPlots())! {
                            
                            plot.frame = (graph?.bounds)!
                            //print("plot \(plot.identifier) \(plot.frame.size)")
                            //plot.reloadData()
                            
                        }

                        
        */


                        let pdfData = graph?.dataForPDFRepresentationOfLayer()
                        pdfData!.writeToURL(nodeURL!, atomically: true)
                        

                        
                        i += 1
                    }
                
                

                    
                    self.window!.endSheet(self.progSheet)
                    self.progSheet.orderOut(self)
                    
                }
            
            }

            


            

        }
        else { return }
        
        
    }
    

   

    

    
/*
    func mocDidChange(notification: NSNotification){
        

    
        dispatch_async(dispatch_get_main_queue()) {
            self.moc.mergeChangesFromContextDidSaveNotification(notification)
        }
 
        
    }

*/



}
