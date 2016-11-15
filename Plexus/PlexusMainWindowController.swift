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
    dynamic var modelTreeController : NSTreeController!
    

    
    override func windowWillLoad() {
        
        //let errorPtr : NSErrorPointer = nil

        //Get MOC from App delegate
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        
        let request = NSFetchRequest<Model>(entityName: "Model")
        let fetchedModels: [AnyObject]?
        do {
            fetchedModels = try moc.fetch(request)
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


            let newModel = NSEntityDescription.insertNewObject(forEntityName: "Model", into: moc) 
            newModel.setValue("newmodel", forKey: "name")
            newModel.setValue(Date(), forKey: "dateCreated")
            newModel.setValue(Date(), forKey: "dateModded")
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
        
        if((calcop.isBNProgram(self) == nil)){
            DispatchQueue.global().async {
                self.calcop.clCompile()
            }
        }
 

        UserDefaults.standard.addObserver(self, forKeyPath: "hardwareDevice", options: NSKeyValueObservingOptions.new, context: nil)
        
        modelTreeController = mainSplitViewController.modelViewController?.modelTreeController
        
    }
    

    
    @IBAction func  toggleModels(_ x:NSToolbarItem){


        mainSplitViewController.toggleModels(x)
        
    }
    
    @IBAction func  toggleStructures(_ x:NSToolbarItem){

        
        mainSplitViewController.toggleStructures(x)

        
    }
    

    @IBAction func testRandom(_ x:NSToolbarItem){
        
        let nodes : [BNNode] = mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode]
        
        
        
        for fNode in nodes {
            let blankArray = [NSNumber]()
            let blankData = NSKeyedArchiver.archivedData(withRootObject: blankArray)
            
            var postCount = [Int](repeating: 0, count: 101)
            
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
            
            let archivedPostCount = NSKeyedArchiver.archivedData(withRootObject: postCount)
            fNode.setValue(archivedPostCount, forKey: "postCount")
            let archivedPostArray = NSKeyedArchiver.archivedData(withRootObject: testranarray)
            fNode.setValue(archivedPostArray, forKey: "postArray")
        }
    }

    
    func progSetup(_ sender: AnyObject) -> NSWindow {
        var retWin : NSWindow!
        
        //sheet programamticaly
        let sheetRect = NSRect(x: 0, y: 0, width: 400, height: 82)
        retWin = NSWindow(contentRect: sheetRect, styleMask: NSTitledWindowMask, backing: NSBackingStoreType.buffered, defer: true)
        let contentView = NSView(frame: sheetRect)
        self.progInd = NSProgressIndicator(frame: NSRect(x: 143, y: 52, width: 239, height: 20))
        self.progInd.canDrawConcurrently = true
        self.progInd.isIndeterminate = false
        self.progInd.usesThreadedAnimation = true
        
        self.workLabel = NSTextField(frame: NSRect(x: 10, y: 52, width: 72, height: 20))
        workLabel.isEditable = false
        workLabel.drawsBackground = false
        workLabel.isSelectable = false
        workLabel.isBezeled = false
        workLabel.stringValue = "Working..."
        
        self.cancelButton = NSButton(frame: NSRect(x: 304, y: 12, width: 84, height: 32))
        cancelButton.bezelStyle = NSBezelStyle.rounded
        cancelButton.title = "Cancel"
        cancelButton.target = self
        cancelButton.action = #selector(PlexusMainWindowController.cancelProg(_:))
        
        self.maxLabel = NSTextField(frame: NSRect(x: 138, y: 10, width: 64, height: 20))
        maxLabel.isEditable = false
        maxLabel.drawsBackground = false
        maxLabel.isSelectable = false
        maxLabel.isBezeled = false
        maxLabel.stringValue = String(0)
        
        self.ofLabel = NSTextField(frame: NSRect(x: 74, y: 10, width: 64, height: 20))
        ofLabel.isEditable = false
        ofLabel.drawsBackground = false
        ofLabel.isSelectable = false
        ofLabel.isBezeled = false
        ofLabel.stringValue = "of"
        
        self.curLabel = NSTextField(frame: NSRect(x: 10, y: 10, width: 64, height: 20))
        curLabel.isEditable = false
        curLabel.drawsBackground = false
        curLabel.isSelectable = false
        curLabel.isBezeled = false
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
    
    
    
    
    
    @IBAction func  importCSV(_ x:NSToolbarItem){


        self.mainSplitViewController.entryTreeController.fetch(self)
        
        
        //Open panel for .csv files only
        let op:NSOpenPanel = NSOpenPanel()
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true
        op.allowedFileTypes = ["csv"]
        
        //accessory view to allow addition to current locaiton
        let av:NSButton = NSButton(frame: NSMakeRect(0.0, 0.0, 324.0, 22.0))
        av.setButtonType(NSButtonType.switch)
        av.title = "Add as child of current selection"
        av.state = 0
        op.accessoryView = av
        if #available(OSX 10.11, *) {
            op.isAccessoryViewDisclosed = true
        } else {
            op.accessoryView?.isHidden = false
        }
        
        let result = op.runModal()
        

        
        op.close()
        

        
        if (result == NSFileHandlingPanelOKButton) {
            var i = 1
            var firstLine = true
            let inFile  = op.url
            let inFileBase = inFile?.deletingPathExtension()

            
            var curEntry : Entry!
            
            if(av.state == 0){//New entires will be added as a child of an entry given the name of the input file
                curEntry = Entry(entity: NSEntityDescription.entity(forEntityName: "Entry", in: self.moc)!, insertInto: self.moc)
                curEntry.setValue(inFileBase?.lastPathComponent, forKey: "name")
            }
            
            else { //New Entries will be added as children of current entry.
                let curEntries : [Entry] = self.mainSplitViewController.entryTreeController.selectedObjects as! [Entry]
                if(curEntries.count > 0){
                    curEntry  = curEntries[0]
                }
                else {
                    curEntry = Entry(entity: NSEntityDescription.entity(forEntityName: "Entry", in: self.moc)!, insertInto: self.moc)
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
            
            DispatchQueue.global().async {
                
                
                //create moc

                let inMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                inMOC.undoManager = nil
                inMOC.persistentStoreCoordinator = self.moc.persistentStoreCoordinator

                let parentEntry : Entry = inMOC.object(with: curEntryID) as! Entry


                
                let fileContents : String = (try! NSString(contentsOfFile: inFile!.path, encoding: String.Encoding.utf8.rawValue)) as String
                let fileLines : [String] = fileContents.components(separatedBy: "\n")
                
                
                let delimiterCharacterSet = NSMutableCharacterSet(charactersIn: ",\"")
                delimiterCharacterSet.formUnion(with: CharacterSet.whitespacesAndNewlines)

                var batchCount : Int = 0
                var columnCount = 0
                var nameColumn = -1
                var structureColumn = -1
                var latitudeColumn = -1
                var longitudeColumn = -1
                var headers = [String]()
                var existingStructures = [Structure]()
                var existingStructureNames = [String]() //for speed
                
                let request = NSFetchRequest<Structure>(entityName: "Structure")
                do{
                    existingStructures = try self.moc.fetch(request)

                    } catch let error as NSError {
                        print(error)
                }
                
                for curStructure :Structure in existingStructures {
                    existingStructureNames.append(curStructure.name)
                }
            
                DispatchQueue.main.async {
                    self.progSheet = self.progSetup(self)
                    self.maxLabel.stringValue = String(fileLines.count)
                    self.window!.beginSheet(self.progSheet, completionHandler: nil)
                    self.progSheet.makeKeyAndOrderFront(self)
                    self.progInd.isIndeterminate = false
                    self.progInd.doubleValue = 0
                    self.workLabel.stringValue = "Importing..."
                    self.progInd.startAnimation(self)
                    self.progInd.maxValue =  Double(fileLines.count)
                }
                

                for thisLine : String in fileLines {

                    if(self.breakloop){
                        self.breakloop = false
                        break
                    }
                    
                    if firstLine {  //this is the header line
                        
                        let theHeader : [String] = thisLine.components(separatedBy: ",")
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
                            headers.append(thisHeader.trimmingCharacters(in: delimiterCharacterSet as CharacterSet))
                            columnCount += 1
                        }
                        
                        
                    }
                        
                    else {
                        
                        
                        if(thisLine.trimmingCharacters(in: delimiterCharacterSet as CharacterSet) != "" ){ //ignore lines that are blank and/or only contain commas
                            
                            let newEntry : Entry = Entry(entity: NSEntityDescription.entity(forEntityName: "Entry", in: inMOC)!, insertInto: inMOC)
                            
 
                            var theTraits : [String] = thisLine.components(separatedBy: ",")
                            
                            
                            
                            if(theTraits.count != columnCount){
                                
                                
                                DispatchQueue.main.async {
                                    

                                    self.window!.endSheet(self.progSheet)
                                    self.progSheet.orderOut(self)
                                    
                                    let question = NSLocalizedString("Line \(i) has \(theTraits.count) entries, while the header line has \(columnCount) entries", comment: "Non-matching line sizes")
                                    let info = NSLocalizedString("Make sure that you use tab (\t) for multiple entries within a cell, and newlines (\n) for the end of each line", comment: "Non-matching line sizes");
                                    let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                                    let alert = NSAlert()
                                    alert.messageText = question
                                    alert.informativeText = info
                                    
                                    alert.addButton(withTitle: cancelButton)
                                    
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
                                let theSubStructures : [String] = theTraits[structureColumn].components(separatedBy: "\t")
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
                                        let newStructure : Structure = Structure(entity: NSEntityDescription.entity(forEntityName: "Structure", in: inMOC)!, insertInto: inMOC)
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
                                    
                                    let theSubTraits : [String] = thisTrait.components(separatedBy: "\t")
                                    
                                    for thisSubTrait in theSubTraits {
                                        //  print(thisSubTrait)
                                        if(thisSubTrait.trimmingCharacters(in: delimiterCharacterSet as CharacterSet) != "" ){//ignore empty
                                            let newTrait : Trait = Trait(entity: NSEntityDescription.entity(forEntityName: "Trait", in: inMOC)!, insertInto: inMOC)
                                            newTrait.setValue(headers[columnCount], forKey: "name")
                                            newTrait.setValue(thisSubTrait.trimmingCharacters(in: delimiterCharacterSet as CharacterSet), forKey: "traitValue")
                                            newTrait.setValue(newEntry, forKey: "entry")
                                            
                                            newEntry.addTraitObject(newTrait)
                                        }
                                    }
                                    
                                    
                                }
                                
                                
                                
                                columnCount += 1
                                
                            }
                            

 

                            
                        }
                        
                    }


                    DispatchQueue.main.async {
                        
                        self.progInd.increment(by: 1)
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
                       // inMOC.reset()
     
                        

                        
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
                
                

                

                    DispatchQueue.main.async {
                        
                        self.progInd.isIndeterminate = true
                        self.progInd.startAnimation(self)
                        self.window!.endSheet(self.progSheet)
                        self.progSheet.orderOut(self)
                        
                        let mSelPath = self.mainSplitViewController.modelTreeController.selectionIndexPath
                        self.moc.reset()
                        self.mainSplitViewController.entryTreeController.fetch(self)
                        self.mainSplitViewController.modelTreeController.fetch(self)
                        self.mainSplitViewController.modelTreeController.setSelectionIndexPath(mSelPath)
 
                        

                        
                    }
                
                
                
            }
            
            

            
            
            
        }
        

        
    }

    func cancelProg(_ sender: AnyObject){

        self.breakloop = true
    }
    
    @IBAction func  calculate(_ x:NSToolbarItem){

        
        //collect data
        var nodesForCalc : [BNNode] = mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode]
        let curModels : [Model] = mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        
        self.progSheet = self.progSetup(self)
        self.maxLabel.stringValue = String(describing: curModel.runstot)
        self.window!.beginSheet(self.progSheet, completionHandler: nil)
        self.progInd.isIndeterminate = false
        self.progInd.doubleValue = 0
        self.progInd.maxValue =  Double(curModel.runstot)
        self.progSheet.makeKeyAndOrderFront(self)
        
        
        DispatchQueue.global().async {
            
            let starttime = Date.timeIntervalSinceReferenceDate;
            



            var operr: NSError?
            
            operr = self.calcop.calc(self.progInd, withCurLabel: self.curLabel, withWorkLabel: self.workLabel, withNodes: nodesForCalc, withRuns: curModel.runsper, withBurnin: curModel.burnins, withComputes: curModel.runstot) as NSError?
            
            DispatchQueue.main.async {
                self.progInd.isIndeterminate = true
                self.progInd.startAnimation(self)
                self.workLabel.stringValue = "Saving..."
            }

    
            if(operr == nil){
                let resultNodes : NSMutableArray = self.calcop.getResults(self)
                
                let blankArray = [NSNumber]()
                let blankData = NSKeyedArchiver.archivedData(withRootObject: blankArray)
                
                var bins = Int(pow(Double(curModel.runstot), 0.5))
                
                if(bins < 100) {
                    bins = 100
                }
                
                let binQuotient = 1.0/Double(bins)
            
                bins = bins + 1 //one more bin for anything that is a 1.0
                
                var fi = 0
                for fNode in resultNodes {
                
                   // print("\n\n\n\n\n\n\n\n\n\n\n\n************\(fi)")
                    
                    var postCount = [Int](repeating: 0, count: bins)
                    

                    
                    let inNode : BNNode = nodesForCalc[fi]  //FIXME is this the same node???
                    
                    //blank out previous postdata
                    //this shoudl never happen.. safer to blank it than mingle data
                    inNode.setValue(blankData, forKey: "postCount")
                    inNode.setValue(blankData, forKey: "postArray")


                    
                    let fline : [Double] = fNode as! [Double]


                    var gi = 0
                    var flinetot = 0.0
                    var flinecount = 0.0
                    for gNode : Double in fline {
                        
                       
                        if(gNode == gNode && gNode >= 0.0 && gNode <= 1.0) {//fails if nan
                            
                            let x = (Int)(floor(gNode/binQuotient))
                            //print ("result: \(gNode)  bin:\(x)")
                            postCount[x] += 1
                            flinetot += gNode
                            flinecount += 1.0

                        }
                        
                        else{
                           // println("problem detected in reloadData. gNode is \(gNode)")
                        }

                        gi += 1
                    }
                    
                    let archivedPostCount = NSKeyedArchiver.archivedData(withRootObject: postCount)
                    inNode.setValue(archivedPostCount, forKey: "postCount")
                    
                    
                    //Stats on post Array
                    //Mean
                    let flinemean = flinetot / flinecount
                    //print ("Mean \(flinemean)")
                    inNode.setValue(flinemean, forKey: "postMean")
                    
                    //Sample Standard Deviation
                    var sumsquares = 0.0
                    flinecount = 0.0
                    for gNode : Double in fline {
                        
                        if(gNode == gNode && gNode >= 0.0 && gNode <= 1.0) {//ignores if nan
                            sumsquares +=  pow(gNode - flinemean, 2.0)
                            flinecount += 1.0
                        }
                    }
                    
                    let ssd = sumsquares / (flinecount - 1.0)
                    inNode.setValue(ssd, forKey: "postSSD")
                    
                    let sortfline = fline.sorted()
                    let lowTail = sortfline[Int(Double(sortfline.count)*0.05)]
                    let highTail = sortfline[Int(Double(sortfline.count)*0.95)]
                    
                    inNode.setValue(lowTail, forKey: "postETLow")
                    inNode.setValue(highTail, forKey: "postETHigh")
                    
                    //Highest Posterior Density Interval. Alpha = 0.05
                    //Where n = sortfline.count (i.e. last entry)
                    //Compute credible intervals for j = 0 to j = n - ((1-0.05)n)
                    let alpha = 0.05
                    let jmax = Int(Double(sortfline.count) - ((1.0-alpha) * Double(sortfline.count)))
                    
                   var firsthpd = true
                    var interval = -999.99
                    var low = 0
                    var high = sortfline.count
                    for hpdi in 0..<jmax {
                        let highpos = hpdi + Int(((1.0-alpha)*Double(sortfline.count)))
                        if(firsthpd || (sortfline[highpos] - sortfline[hpdi]) < interval){
                            firsthpd = false
                            interval = sortfline[highpos] - sortfline[hpdi]
                            low = hpdi
                            high = highpos
                        }

                    }
                    inNode.setValue(sortfline[low], forKey: "postHPDLow")
                    inNode.setValue(sortfline[high], forKey: "postHPDHigh")


    
                    let startatime = Date.timeIntervalSinceReferenceDate;
                    let defaults = UserDefaults.standard
                    //var preserveRO = defaults.value(forKey: "preserveRawOutput") as! Int
                   // assert(preserveRO == 1)
                    //if(preserveRO == 1){
                        let archivedPostArray = NSKeyedArchiver.archivedData(withRootObject: fline)
                        inNode.setValue(archivedPostArray, forKey: "postArray")
                  //  }
                    
                    let endatime = Date.timeIntervalSinceReferenceDate;
                    let ainterval = endatime-startatime
                    print("Saving postarray took \(ainterval) seconds");

                    fi += 1
                    
                }
                
                let notification:NSUserNotification = NSUserNotification()
                notification.title = "Plexus"
                notification.informativeText = "\(curModel.runstot.intValue) runs completed."
                
                notification.soundName = NSUserNotificationDefaultSoundName
                
                notification.deliveryDate = Date(timeIntervalSinceNow: 5)
                let notificationcenter:NSUserNotificationCenter = NSUserNotificationCenter.default
                
                notificationcenter.scheduleNotification(notification)


            }
            else{
                
                DispatchQueue.main.async {
                    let calcAlert : NSAlert = NSAlert()
                    calcAlert.alertStyle = NSAlertStyle.warning
                    calcAlert.messageText = (operr?.localizedFailureReason)!
                    calcAlert.informativeText = (operr?.localizedRecoverySuggestion)!
                    calcAlert.addButton(withTitle: "OK")
                    
                    let _ = calcAlert.runModal()
                    
                }

                


        }

            
            DispatchQueue.main.async {
                

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
            

        

            let endtime = Date.timeIntervalSinceReferenceDate;
            let interval = endtime-starttime
            print("Calculation took \(interval) seconds");
        }
        
       // print("End calcuilate fxn reached")
    }
    


    
    @IBAction func exportCSV(_ x:NSToolbarItem){
        let err : NSErrorPointer? = nil
        

        
        let curModels : [Model] = self.mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        let defaults = UserDefaults.standard
        let pTypes = defaults.array(forKey: "PriorTypes") as! [String]
        
        let sv:NSSavePanel = NSSavePanel()
        sv.nameFieldStringValue = curModel.name
        
        
        let result = sv.runModal()
        sv.close()
        
        if (result == NSFileHandlingPanelOKButton) {
           
            var baseFile  = sv.url?.absoluteString
            let baseDir = sv.directoryURL
            
            do {
                try FileManager.default.removeItem(at: sv.url!)
            }  catch let error as NSError {
                //print(error.description)
            }
            
            
            do {
                try FileManager.default.createDirectory(at: baseDir!.appendingPathComponent(sv.nameFieldStringValue), withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.description)
                return
            }
 
            baseFile = baseFile! + sv.nameFieldStringValue
            
            let outFileName = baseFile! + "-data.csv"

            let outURL = URL(string: outFileName)
            

            DispatchQueue.global().async {
                let request = NSFetchRequest<Entry>(entityName: "Entry")
                do {
                    let entries : [Entry] = try self.moc!.fetch(request)
                    
                    self.progSheet = self.progSetup(self)
                    self.maxLabel.stringValue = String(entries.count)
                    self.window!.beginSheet(self.progSheet, completionHandler: nil)
                    self.progSheet.makeKeyAndOrderFront(self)
                    self.progInd.isIndeterminate = true
                    self.workLabel.stringValue = "Exporting Entries..."
                    self.progInd.doubleValue = 0
                    
                    self.progInd.startAnimation(self)
                    
                    
                    self.progInd.maxValue =  Double(entries.count)
                    
                    
                    self.progInd.startAnimation(self)
                    
                    var outText = "Name,"
                    
                    let trequest = NSFetchRequest<Trait>(entityName: "Trait")
                    
                    
                    var i = 0
                    
                    do {
                        let headerTraits : [Trait] = try self.moc!.fetch(trequest) 
                        
                        let distinctHeaderTraits = NSSet(array: headerTraits.map { $0.name })
                        
                        
                        for headerTrait in distinctHeaderTraits {
                            outText += headerTrait as! String
                            
                            
                            outText += ","
                            
                        }
                        outText += "\n"
                        
                        self.progInd.isIndeterminate = false
                        
                        for entry : Entry in entries {
                            outText += entry.name
                            outText += ","
                            
                            let tTraits = entry.trait
                            for headerTrait in distinctHeaderTraits {
                                let hKey = headerTrait as! String
                                
                                
                                
                                var traitString = [String]()
                                for tTrait in tTraits{
                                    let tKey = (tTrait as AnyObject).value(forKey: "name") as! String
                                    if hKey == tKey{
                                        //outText += tTrait.valueForKey("traitValue") as! String
                                        //outText += "\t"
                                        traitString.append((tTrait as AnyObject).value(forKey: "traitValue") as! String)
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
                            
                            DispatchQueue.main.async {
                                
                                self.progInd.increment(by: 1)
                                self.curLabel.stringValue = String(i)
                                
                            }
                            i += 1
                            
                        }
                        
                        
                        
                        do {
                            try outText.write(to: outURL!, atomically: true, encoding: String.Encoding.utf8)
                        } catch _ {
                        }
                    } catch let error as NSError {
                        err??.pointee = error
                        return
                    } catch {
                        fatalError()
                    }
                    
                    
                }catch let error as NSError {
                        err??.pointee = error
                        return
                    } catch {
                        fatalError()
                    }
                
            


                
                //now print nodes
               // let outDir = sv.directoryURL?.absoluteString
               // let baseDir = outFile.absoluteString
                DispatchQueue.main.async {
                
                    self.progInd.isIndeterminate = true
                    self.progInd.startAnimation(self)
                    self.workLabel.stringValue = "Exporting Nodes..."
                    
                    var i = 0
                    
                    let nodeTXTFileName = baseFile! + "-nodes.csv"
                    let nodeTXTURL = URL(string: nodeTXTFileName)
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
                            outText += String(describing: node.priorV1)
                            outText += "\n"
                            
                            outText += "Prior V2,"
                            outText += String(describing: node.priorV2)
                            outText += "\n"
                            

                            
                        }
                        
                        if node.postCount != nil {
                            outText += "Posterior Count Bin,"
                            let postCount = NSKeyedUnarchiver.unarchiveObject(with: node.value(forKey: "postCount") as! Data) as! [Int]
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
                            let postArray = NSKeyedUnarchiver.unarchiveObject(with: node.value(forKey: "postArray") as! Data) as! [Double]

                            
                            for thisPost in postArray {
                                outText += String(thisPost)
                                outText += ","
                            }
                            outText += "\n"
                            
                        }
                        
                        outText += "\n"
                        
                        
                        do {
                            try outText.write(to: nodeTXTURL!, atomically: true, encoding: String.Encoding.utf8)
                        }
                        catch let error as NSError {
                            print(error)
                        } catch {
                            fatalError()
                        }
                        
                        //create a compound of the outFile name and node name
                        let nodePDFFileName = baseFile! + "-" + node.nodeLink.name + ".pdf"
                        let nodeURL = URL(string: nodePDFFileName)

                        
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
                        try? pdfData!.write(to: nodeURL!, options: [.atomic])
                        

                        
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


    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if(keyPath == "hardwareDevice"){
            DispatchQueue.global().async {
                self.calcop.clCompile()
            }
        }
    }

}
