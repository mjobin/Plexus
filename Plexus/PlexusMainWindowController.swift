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
        
        //Exporting current daatset only
        let curDatasets : [Dataset] = self.datasetController.selectedObjects as! [Dataset]
        let curDataset : Dataset = curDatasets[0]
        
        let curModels : [Model] = self.mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        let sv:NSSavePanel = NSSavePanel()
        //sv.allowedFileTypes = ["csv"]
        sv.nameFieldStringValue = curDataset.name + "-" + curModel.name
        
        sv.beginSheetModalForWindow(window!, completionHandler: {(result:Int) -> Void in
            

            
            if (result == NSFileHandlingPanelOKButton) {
               
                let baseFile  = sv.URL?.absoluteString
                let outFileName = baseFile! + ".csv"

                let outURL = NSURL(string: outFileName)
                print(outURL)
                

                
                sv.close()
                
                
                self.progSheet = self.progSetup(self)
                self.window!.beginSheet(self.progSheet, completionHandler: nil)
                self.progSheet.makeKeyAndOrderFront(self)
                self.progInd.indeterminate = true
                self.workLabel.stringValue = "Exporting..."
                self.progInd.startAnimation(self)
                
                var outText = "Name,"
                

                let trequest = NSFetchRequest(entityName: "Trait")

                let tpredicate = NSPredicate(format: "entry.dataset == %@", curDataset)
                trequest.predicate = tpredicate
                

                
                do {
                    let headerTraits : [Trait] = try self.moc!.executeFetchRequest(trequest) as! [Trait]
                    
                    let distinctHeaderTraits = NSSet(array: headerTraits.map { $0.name })
                    

                    for headerTrait in distinctHeaderTraits {
                        outText += headerTrait as! String
                      
                       
                        outText += ","

                    }
                    outText += "\n"
        
                    
                    let entries : [Entry] = curDataset.entry.allObjects as! [Entry]
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
                                k++
                            }
                            
                            if(traitString.count > 1){
                                outText += "\""
                            }


                            outText += ","
                        }


                        outText += "\n"

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
                
                
                
                //now print nodes
               // let outDir = sv.directoryURL?.absoluteString
               // let baseDir = outFile.absoluteString
                

                
                var i = 0
                for node in self.mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode] {
                    self.mainSplitViewController.modelDetailViewController?.nodesController.setSelectionIndex(i)
                    
                    
                    
                    //create a compound of the outFile name and node name
                    let nodeTXTFileName = baseFile! + "-" + node.nodeLink.name + ".csv"
                    let nodeTXTURL = NSURL(string: nodeTXTFileName)
                    //  print(nodeURL)
                    
                    
                    var outText : String = String()
                    outText += node.nodeLink.name
                    outText += "\n"

                        outText += "cptFreq,"
                        outText += String(node.cptFreq)
                        outText += "\n"
                    
                    if node.priorArray != nil {
                        outText += "prior,"
                        let priorArray = NSKeyedUnarchiver.unarchiveObjectWithData(node.valueForKey("priorArray") as! NSData) as! [Int]

                        
                        for thisPrior in priorArray {
                            outText += String(thisPrior)
                            outText += ","
                        }
                        outText += "\n"
                        
                    }
                    if node.postArray != nil {
                        outText += "posterior,"
                        let postArray = NSKeyedUnarchiver.unarchiveObjectWithData(node.valueForKey("postArray") as! NSData) as! [Int]

                        
                        for thisPost in postArray {
                            outText += String(thisPost)
                            outText += ","
                        }
                        outText += "\n"
                        
                    }
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
                    print(nodeURL)
                    
                    let graphView = self.mainSplitViewController.modelDetailViewController?.graphView
                    graphView?.frame = NSMakeRect(0, 0, 792, 612)
                    
                    
                    let graph = self.mainSplitViewController.modelDetailViewController?.graph
                    
                    graph?.frame = NSMakeRect(0, 0, 792, 612)
                    /*
                    let titleStyle = CPTMutableTextStyle()
                    titleStyle.fontName = "SanFrancisco"
                    titleStyle.fontSize = 18.0
                    titleStyle.color = CPTColor.blackColor()
                    graph?.titleTextStyle = titleStyle

                    
                    graph?.title = node.nodeLink.name
                    
                    
                    graph?.paddingTop = 10.0
                    graph?.paddingBottom = 10.0
                    graph?.paddingLeft = 10.0
                    graph?.paddingRight = 10.0
                    
                    let plotSpace : CPTXYPlotSpace = graph?.defaultPlotSpace as! CPTXYPlotSpace
                    plotSpace.allowsUserInteraction = false
                    
                    
                    let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
                    let yRange = plotSpace.yRange.mutableCopy() as! CPTMutablePlotRange
                    
                    xRange.length = 1.1
                    yRange.length = 1.1
                    
                    
                    plotSpace.xRange = xRange
                    plotSpace.yRange = yRange
                    plotSpace.scaleToFitPlots(graph?.allPlots())
                    
                    print ("title \(graph?.title)")
                    
                    
                    for plot in (graph?.allPlots())! {
                        
                        plot.frame = (graph?.bounds)!
                        //print("plot \(plot.identifier) \(plot.frame.size)")
                        //plot.reloadData()
                        
                    }

                    
*/


                    let pdfData = graph?.dataForPDFRepresentationOfLayer()
                    pdfData!.writeToURL(nodeURL!, atomically: true)
                    
                    
                    i++
                }
                
              

                self.window!.endSheet(self.progSheet)
                self.progSheet.orderOut(self)
            }
            
            else { return }
        })
        
    }
    
    @IBAction func importCSV(x:NSToolbarItem){
        var error: NSErrorPointer = nil

        
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
                    
              //      let headerLine = fileLines[0]
                    


                    
                    
                    var delimiterCharacterSet = NSMutableCharacterSet(charactersInString: ",\"")
                    delimiterCharacterSet.formUnionWithCharacterSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

                    
                  
                    

                    


                    
                    
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
                            
                          //  print("\(i) \(thisLine)")
                            
                            if firstLine {  //this is the header line
                                
                                let theHeader : [String] = thisLine.componentsSeparatedByString(",")
                                for thisHeader in theHeader {
                                    if thisHeader == "Name" {
                                        nameColumn = columnCount
                                    }
                                    if thisHeader == "Structure" {
                                        structureColumn = columnCount
                                    }
                                    headers.append(thisHeader.stringByTrimmingCharactersInSet(delimiterCharacterSet))
                                    columnCount++
                                }

                                
                            }

                            else {
                                
                                
                                if(thisLine.stringByTrimmingCharactersInSet(delimiterCharacterSet) != "" ){ //ignore lines that are blank and/or only contain commas
                            
                                    let newEntry : Entry = Entry(entity: NSEntityDescription.entityForName("Entry", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                                    var theTraits : [String] = thisLine.componentsSeparatedByString(",")

                                    if nameColumn >= 0{
                                        newEntry.setValue(theTraits[nameColumn], forKey: "name")
                                    }
                                    else {
                                        newEntry.setValue(String(i), forKey: "name")
                                    }
                                    
                                    /*
                                    if (structureColumn >= 0 ) {
                                        let theSubStructures : [String] = theTraits[structureColumn].componentsSeparatedByString("\r")
                                        for thisSubStructure in theSubStructures {
                                        
                                            let strerror: NSErrorPointer = nil
                                            let request = NSFetchRequest(entityName: "Structure")
                                            let predicate = NSPredicate(format: "dataset == %@ AND name == %@", inDataset, thisSubStructure)
                                            request.predicate = predicate
                                            let strCount = self.moc.countForFetchRequest(request, error: strerror)
                                            if(strCount == NSNotFound || strCount < 1){ //does not exist, create
                                                let newStructure : Structure = Structure(entity: NSEntityDescription.entityForName("Structure", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                                                newStructure.setValue(thisSubStructure, forKey: "name")
                                                newStructure.setValue(inDataset, forKey: "dataset")
                                                newStructure.addEntryObject(newEntry)
                                                inDataset.addStructureObject(newStructure)
        

                                            }
                                            else { //exists
                                                
                                                do{
                                                    let fetch = try self.moc.executeFetchRequest(request)
                                                    let thisStructure = fetch[0] as! Structure //always hand the first one , should only be one
                                                   // thisStructure.setValue(theTraits[structureColumn], forKey: "name")
                                                   // thisStructure.setValue(inDataset, forKey: "dataset")
                                                    thisStructure.addEntryObject(newEntry)
                                                   // inDataset.addStructureObject(thisStructure)
                                                    
                                                    
                                                } catch let error as NSError {
                                                    print(error)
                                                    
                                                }
                                            }
                                        }
                
                                        
                                    }
*/

                                    
                                    newEntry.setValue("Entry", forKey: "type")
                                    newEntry.setValue(inDataset, forKey: "dataset")
                                    inDataset.addEntryObject(newEntry)

                                    
                                    

                                    columnCount = 0
                                    for thisTrait in theTraits {
                                      //  print(thisTrait)
                                        
                                        if(columnCount != nameColumn && columnCount != structureColumn){
                                        
                                        let theSubTraits : [String] = thisTrait.componentsSeparatedByString("\r")
                                        
                                        for thisSubTrait in theSubTraits {
                                          //  print(thisSubTrait)
                                            if(thisSubTrait.stringByTrimmingCharactersInSet(delimiterCharacterSet) != "" ){//ignore empty
                                                let newTrait : Trait = Trait(entity: NSEntityDescription.entityForName("Trait", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
                                                newTrait.setValue(headers[columnCount], forKey: "name")
                                                newTrait.setValue(thisSubTrait.stringByTrimmingCharactersInSet(delimiterCharacterSet), forKey: "traitValue")
                                                newTrait.setValue(newEntry, forKey: "entry")
                                                
                                                newEntry.addTraitObject(newTrait)
                                            }
                                        }
                                        
                                        
                                        }


                                        
                                        columnCount++
                                        
                                    }
                                }
                            
                            }

       
                            firstLine = false
                            i++


                            
                                batchCount++
                            
                            if(batchCount > 1000){
                                do {
                                    try self.moc.save()
                                } catch let error as NSError {
                                    print(error)
                                } catch {
                                    fatalError()
                                }
                                batchCount = 0
                              //  self.moc.reset()


                                
                            //    inDataset = self.moc.objectWithID(datasetID) as! Dataset

                                
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
