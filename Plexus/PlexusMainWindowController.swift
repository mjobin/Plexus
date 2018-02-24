//
//  PlexusMainWindowController.swift
//  Plexus
//
//  Created by matt on 10/1/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import CoreData
import Metal
import GameKit


class PlexusMainWindowController: NSWindowController, NSWindowDelegate {
    
  
    var moc : NSManagedObjectContext!
    var mainSplitViewController = PlexusMainSplitViewController()
    @IBOutlet var mainToolbar : NSToolbar!
    @IBOutlet var testprog : NSProgressIndicator!
    @IBOutlet var metalDevices = MTLCopyAllDevices()
    
    

    let queue = DispatchQueue(label: "edu.scu.Plexus.metalQueue")

    lazy var device: MTLDevice! = {
        let devices: [MTLDevice] = MTLCopyAllDevices()
        for metalDevice : MTLDevice in devices {
            if metalDevice.isHeadless  && !metalDevice.isLowPower { //Select the best device if there are any choices
                return metalDevice
            }
        }
        return MTLCreateSystemDefaultDevice() //Return default device if no headless
    }()
        
    
    // choose the device NOT used by monitor

    lazy var defaultLibrary: MTLLibrary! = {
        self.device.newDefaultLibrary()
    }()
    lazy var commandQueue: MTLCommandQueue! = {
        print ("Metal device: \(self.device.name!). Headless: \(self.device.isHeadless). Low Power: \(self.device.isLowPower)")
        return self.device.makeCommandQueue()
    }()
    var pipelineState: MTLComputePipelineState!
    
    var progSheet : NSWindow!
    var cancelButton : NSButton!
    

    var progInd : NSProgressIndicator!
    var workLabel : NSTextField!
    var curLabel : NSTextField!
    var ofLabel : NSTextField!
    var maxLabel : NSTextField!

    
    var hProgInd : NSProgressIndicator!
    var hworkLabel : NSTextField!
    var hofLabel : NSTextField!
    var hcurLabel : NSTextField!
    var hmaxLabel : NSTextField!
    
    var rProgInd : NSProgressIndicator!
    var rworkLabel : NSTextField!
    var rofLabel : NSTextField!
    var rcurLabel : NSTextField!
    var rmaxLabel : NSTextField!
     

    
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
        

        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSaveContext:", name: NSManagedObjectContextDidSaveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlexusMainWindowController.contextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(PlexusBNScene.mocDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: moc)
        
        
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        mainSplitViewController = contentViewController as! PlexusMainSplitViewController

 
        modelTreeController = mainSplitViewController.modelViewController?.modelTreeController
        
        queue.async {
            self.setUpMetal()
        }
        

        
    }
    

    func setUpMetal() {
        if let kernelFunction = defaultLibrary.makeFunction(name: "bngibbs") {
            do {
                pipelineState = try device.makeComputePipelineState(function: kernelFunction)
            }
            catch {
                fatalError("Impossible to setup Metal")
            }
        }
    }
    
    @IBAction func  toggleModels(_ x:NSToolbarItem){


        mainSplitViewController.toggleModels(x)
        
    }
    
    @IBAction func  toggleStructures(_ x:NSToolbarItem){

        
        mainSplitViewController.toggleStructures(x)

        
    }
    


    
    func progSetup(_ sender: AnyObject) -> NSWindow {
        var retWin : NSWindow!
        
        //sheet programamticaly
        let sheetRect = NSRect(x: 0, y: 0, width: 400, height: 82)
        retWin = NSWindow(contentRect: sheetRect, styleMask: .titled, backing: NSBackingStoreType.buffered, defer: true)
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
    
    
    func progHillSetup(_ sender: AnyObject) -> NSWindow {
        var retWin : NSWindow!
        
        //sheet programamticaly
        let sheetRect = NSRect(x: 0, y: 0, width: 500, height: 180)
        retWin = NSWindow(contentRect: sheetRect, styleMask: .titled, backing: NSBackingStoreType.buffered, defer: true)
        let contentView = NSView(frame: sheetRect)
        progInd = NSProgressIndicator(frame: NSRect(x: 100, y: 52, width: 250, height: 20))
        progInd.canDrawConcurrently = true
        progInd.isIndeterminate = false
        progInd.usesThreadedAnimation = true
        
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
        
        self.maxLabel = NSTextField(frame: NSRect(x: 428, y: 52, width: 64, height: 20))
        maxLabel.isEditable = false
        maxLabel.drawsBackground = false
        maxLabel.isSelectable = false
        maxLabel.isBezeled = false
        maxLabel.stringValue = String(0)
        
        self.ofLabel = NSTextField(frame: NSRect(x: 404, y: 52, width: 24, height: 20))
        ofLabel.isEditable = false
        ofLabel.drawsBackground = false
        ofLabel.isSelectable = false
        ofLabel.isBezeled = false
        ofLabel.stringValue = "of"
        
        self.curLabel = NSTextField(frame: NSRect(x: 360, y: 52, width: 64, height: 20))
        curLabel.isEditable = false
        curLabel.drawsBackground = false
        curLabel.isSelectable = false
        curLabel.isBezeled = false
        curLabel.stringValue = String(0)
        
        

        
        hProgInd = NSProgressIndicator(frame: NSRect(x: 100, y: 94, width: 250, height: 20))
        hProgInd.canDrawConcurrently = true
        hProgInd.isIndeterminate = false
        hProgInd.usesThreadedAnimation = true
        
        self.hworkLabel = NSTextField(frame: NSRect(x: 10, y: 94, width: 72, height: 20))
        hworkLabel.isEditable = false
        hworkLabel.drawsBackground = false
        hworkLabel.isSelectable = false
        hworkLabel.isBezeled = false
        hworkLabel.stringValue = "Chain"
        
        self.hofLabel = NSTextField(frame: NSRect(x: 404, y: 94, width: 24, height: 20))
        hofLabel.isEditable = false
        hofLabel.drawsBackground = false
        hofLabel.isSelectable = false
        hofLabel.isBezeled = false
        hofLabel.stringValue = "of"
        
        rProgInd = NSProgressIndicator(frame: NSRect(x: 100, y: 136, width: 250, height: 20))
        rProgInd.canDrawConcurrently = true
        rProgInd.isIndeterminate = false
        rProgInd.usesThreadedAnimation = true
        
        self.rworkLabel = NSTextField(frame: NSRect(x: 10, y: 136, width: 72, height: 20))
        rworkLabel.isEditable = false
        rworkLabel.drawsBackground = false
        rworkLabel.isSelectable = false
        rworkLabel.isBezeled = false
        rworkLabel.stringValue = "Hill"
        
        
        contentView.addSubview(workLabel)
        contentView.addSubview(curLabel)
        contentView.addSubview(ofLabel)
        contentView.addSubview(maxLabel)
        contentView.addSubview(progInd)
        contentView.addSubview(cancelButton)
        
        
        contentView.addSubview(hProgInd)
        contentView.addSubview(hworkLabel)
        
        contentView.addSubview(rProgInd)
        contentView.addSubview(rworkLabel)
        
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
        
        let aView : NSView = NSView(frame: NSMakeRect(0.0, 0.0, 324.0, 22.0))
        
        //accessory view to allow addition to current locaiton
        let av:NSButton = NSButton(frame: NSMakeRect(0.0, 0.0, 140.0, 22.0))
        av.setButtonType(NSButtonType.switch)
        av.title = "Add as child"
        av.state = 0
        aView.addSubview(av)
        op.accessoryView = aView
        
        let sc:NSButton = NSButton(frame: NSMakeRect(170.0, 0.0, 140.0, 22.0))
        sc.setButtonType(NSButtonType.switch)
        sc.title = "Create new model"
        sc.state = 1
        aView.addSubview(sc)
        
        op.accessoryView = aView
        
        
       //
        if #available(OSX 10.11, *) {
            op.isAccessoryViewDisclosed = true
        } else {
            op.accessoryView?.isHidden = false
        }
        
        let result = op.runModal()
        

        
        op.close()
        

        
        if (result == NSFileHandlingPanelOKButton) {
            mainSplitViewController.modelDetailViewController?.calcInProgress = true
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
            
            if(sc.state == 1){


                let newModel : Model = Model(entity: NSEntityDescription.entity(forEntityName: "Model", in: self.moc)!, insertInto: self.moc)
                newModel.setValue(curEntry.name, forKey: "name")
                newModel.setValue(curEntry, forKey: "scope")


                
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
                var latitudeColumn = -1
                var longitudeColumn = -1
                var headers = [String]()

                
                self.performSelector(onMainThread: #selector(PlexusMainWindowController.startProgInd), with: nil, waitUntilDone: true)
                
                DispatchQueue.main.async {
                    self.maxLabel.stringValue = String(fileLines.count-1)
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
                            
                            

                            
                            
                            newEntry.setValue("Entry", forKey: "type")
                            
                          //  if(av.state == 1){
                                newEntry.setValue(parentEntry, forKey: "parent")
                                parentEntry.addChildObject(newEntry)
                          //  }

                            

                            
                            columnCount = 0
                            for thisTrait in theTraits {

                                
                                if(columnCount != nameColumn && columnCount != longitudeColumn && columnCount != latitudeColumn){
                                    
                                    let theSubTraits : [String] = thisTrait.components(separatedBy: "\t")
                                    
                                    for thisSubTrait in theSubTraits {
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

                        let mSelPath = self.mainSplitViewController.modelTreeController.selectionIndexPath
                        self.moc.reset()
                        self.mainSplitViewController.entryTreeController.fetch(self)
                        self.mainSplitViewController.structureViewController?.structureController.fetch(self)
                        self.mainSplitViewController.modelTreeController.fetch(self)
                        self.mainSplitViewController.modelTreeController.setSelectionIndexPath(mSelPath)
 
                        self.mainSplitViewController.modelDetailViewController?.calcInProgress = false

                        
                    }
                
                self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
                
                

                
            }
            
            

            
            
            
        }
        

        
    }

    func cancelProg(_ sender: AnyObject){

        self.breakloop = true
    }
    
    func randomChildModel(lastModel : Model, thisMOC : NSManagedObjectContext) -> Model {
        
        let newModel = lastModel.copySelf(thisMOC)
        
        let nodesForTest = newModel.bnnode.allObjects as! [BNNode]
        
        let frompos = (Int(arc4random_uniform(UInt32(nodesForTest.count))))
        
        var topos = frompos
        while(topos == frompos){
            topos = (Int(arc4random_uniform(UInt32(nodesForTest.count))))
        }
        
        let fromNode = nodesForTest[frompos]
        let toNode = nodesForTest[topos]
        
        //Check if there is an arc between them
        var isinfArc = false
        var isinfByArc = false
        let theInfluences : [BNNode] = fromNode.influences.array as! [BNNode]
        for thisInfluences in theInfluences {
            if thisInfluences == toNode {
                isinfArc = true
                break
            }
        }
        
        
        let theInfluencedBy : [BNNode] = fromNode.influencedBy.array as! [BNNode]
        for thisInfluencedBy in theInfluencedBy {
            if thisInfluencedBy == toNode {
                isinfByArc = true
                break
            }
        }
        
        
        if isinfArc == true && isinfByArc == false {
            let cflip = arc4random_uniform(2)
            if(cflip == 0) { // delete arc
                fromNode.removeInfluencesObject(toNode)
            }
            else { // reverse arc
                fromNode.removeInfluencesObject(toNode)
                toNode.addInfluencesObject(fromNode)
            }
        }
        
        else if isinfArc == false && isinfByArc == true {
            let cflip = arc4random_uniform(2)
            if(cflip == 0) { // delete arc
                toNode.removeInfluencesObject(fromNode)
            }
            else { // reverse arc
                toNode.removeInfluencesObject(fromNode)
                fromNode.addInfluencesObject(toNode)
            }
        }
        
        
        else if isinfArc == true && isinfByArc == true {
            fatalError("Error: infleunces in two directions!")
        }
        else { //both false, no arc
            fromNode.addInfluencesObject(toNode)
        }
        

        return newModel
    }
    
    
    
    @IBAction func singleRunPress(_ x:NSToolbarItem) {
    
    mainSplitViewController.modelDetailViewController?.calcInProgress = true
    self.breakloop = false
    
    self.progSheet = self.progSetup(self)
    self.window!.beginSheet(self.progSheet, completionHandler: nil)
    self.progSheet.makeKeyAndOrderFront(self)
    
    let curModels : [Model] = mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
    let firstModel : Model = curModels[0]
    
    let nodesForTest = firstModel.bnnode.allObjects as! [BNNode]
    if (nodesForTest.count < 2){
            return
    }
        
    let calcQueue = DispatchQueue(label: "calcQueue")
    calcQueue.async {
        let fmcrun = self.metalCalc(curModel : firstModel, verbose: true)
        if fmcrun == false {
            fatalError("unlinked network!")
        }


        self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
        
        DispatchQueue.main.async {
            if(self.breakloop == false){
                firstModel.complete = true
            }
            self.mainSplitViewController.modelDetailViewController?.calcInProgress = false
            }
                            //end calcQ
        }
    
}
    
 
    @IBAction func calcButtonPress(_ x:NSToolbarItem){
        mainSplitViewController.modelDetailViewController?.calcInProgress = true
        self.breakloop = false
        
        print(mainSplitViewController.modelDetailViewController?.calcInProgress)
        
        
        let curModels : [Model] = mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let firstModel : Model = curModels[0]
        let firstModelID = firstModel.objectID
        
        self.progSheet = self.progHillSetup(self)
        self.window!.beginSheet(self.progSheet, completionHandler: nil)
        self.hProgInd.maxValue =  Double(firstModel.hillchains)
        self.rProgInd.maxValue =  Double(firstModel.runstarts)
        self.progSheet.makeKeyAndOrderFront(self)
        

        
        let nodesForTest = firstModel.bnnode.allObjects as! [BNNode]
        if (nodesForTest.count < 2){
            return
        }
        
        let calcQueue = DispatchQueue(label: "calcQueue")
        calcQueue.async {

            let cmoc = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
            cmoc.persistentStoreCoordinator = self.moc.persistentStoreCoordinator
            

            do {
                let cfirstModel = try cmoc.existingObject(with: firstModelID) as! Model
                
                var modelPeaks = [Model]()
                
                var lastModel = cfirstModel
                let fmcrun = self.metalCalc(curModel : cfirstModel, verbose: true)
                if fmcrun == false {
                    fatalError("unlinked network!")
                }
//                let firstbic = self.calcLikelihood(curModel: cfirstModel)
                let firstbic = firstModel.score

                
                for _ in 0...Int(cfirstModel.runstarts) {
                
                    var firstrun = true
                    var lastbic = NSNumber.init(value: 0.0)
                    var curbic = NSNumber.init(value: 0.0)
                    
                    for _ in 0...Int(cfirstModel.hillchains) {
                        if(firstrun == true){
                            
                            firstrun = false
                            lastbic = firstbic
                            
                        }
                        else {
                            
                            let curModel = self.randomChildModel(lastModel: lastModel, thisMOC: cmoc)
                            let msrun = self.metalCalc(curModel : curModel, verbose: false)
                            if (msrun == true) {
                                curbic = curModel.score
                                print("\(lastbic) \(curbic)")
                                curModel.setValue(curbic, forKey: "score")
                                if curbic.floatValue > lastbic.floatValue {
                                    lastModel = curModel
                                    lastbic = curbic
                                }
                                else {
                                    cmoc.delete(curModel)
                                    
                                }
                            }
                            else {
                                cmoc.delete(curModel)
                            }
                            
                        }
                        DispatchQueue.main.async {
                            self.hProgInd.increment(by: 1.0)
                        }
                    }
                    
                    if lastModel != cfirstModel {
//                        cfirstModel.addChildObject(lastModel)
                        //and selecty it?
                        modelPeaks.append(lastModel)
                    }
                    DispatchQueue.main.async {
                        self.rProgInd.increment(by: 1.0)
                        self.hProgInd.doubleValue = 0
                    }
                }
                
                //Run through all the random restarts and select highest score
                if(modelPeaks.count > 0){
                    var peakModel = modelPeaks[0]
                    for thisPeak in modelPeaks {
                        if thisPeak.score as! Float > peakModel.score as! Float {
                            peakModel = thisPeak
                        }
                    }
                    
                    for thisPeak in modelPeaks {
                        if thisPeak != peakModel{
                            cmoc.delete(thisPeak)
                        }
                    }
                    
                    if peakModel != cfirstModel {
                        //name it with Best and date
                        var bestname = peakModel.name + "-BEST-"
                        let date = Date()
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd.MM.yyyy"
                        bestname = bestname + formatter.string(from: date)
                        peakModel.setValue(bestname, forKey: "name")
                        cfirstModel.addChildObject(peakModel)
                    }
                    
                }
                

            
                do {
                    try cmoc.save()
                } catch let error as NSError {
                    print(error)
                    fatalError("Could not save models")
                }
                self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
                self.mainSplitViewController.modelDetailViewController?.calcInProgress = false
                
                
            }
            catch {
                fatalError("wtf")
            }
 
            
        }
  
        
    }
    
    

    
    func metalCalc(curModel:Model, verbose:Bool) -> Bool {
        let defaults = UserDefaults.standard
        
        let calcSpeed = defaults.integer(forKey: "calcSpeed")
        
        let kernelFunction: MTLFunction? = defaultLibrary?.makeFunction(name: "bngibbs")
        do {
            pipelineState = try device?.makeComputePipelineState(function: kernelFunction!)
        }
        catch {
            fatalError("Cannot set up Metal")
        }
        
        let teWidth = pipelineState.threadExecutionWidth
        let mTTPT = pipelineState.maxTotalThreadsPerThreadgroup
        

        var maxWSS = 0
        if #available(OSX 10.12, *) {
            maxWSS = Int(device.recommendedMaxWorkingSetSize)
            
        }

        
        var mTML = 0
        if #available(OSX 10.13, *) {
            mTML = Int(device.maxThreadgroupMemoryLength)
            
        }
        if verbose == true {
            print("\n********* BNGibbs Metal run******")
            print ("Thread execution width: \(teWidth)")
            print ("Max threads per group: \(mTTPT)")
            print ("Max working set size: \(maxWSS) bytes")
            print ("Max threadgroup memory length: \(mTML) bytes")
        }
        
        
        let nodesForCalc = curModel.bnnode.allObjects as! [BNNode]
        let nc = nodesForCalc.count
        
        let runstot = curModel.runstot as! Int
        var ntWidth = (mTTPT/teWidth)-1
        if calcSpeed == 0 {
            ntWidth = Int(Double(ntWidth) * 0.5)
        }
        else if calcSpeed == 1 {
            ntWidth = Int(Double(ntWidth) * 0.75)
        }
//        print ("Number of threadgroups: \(ntWidth)")
        let threadsPerThreadgroup : MTLSize = MTLSizeMake(mTTPT, 1, 1)
        let numThreadgroups = MTLSize(width: teWidth, height: 1, depth: 1)
        ntWidth = teWidth * mTTPT
        
        DispatchQueue.main.async {
            
            self.maxLabel.stringValue = String(describing: runstot)
            self.progInd.doubleValue = 0
            self.progInd.maxValue =  Double(runstot)
            self.progInd.isIndeterminate = true
            self.progInd.startAnimation(self)
            self.workLabel.stringValue = "Preparing..."
            

        }

            
        //Setup input and output buffers
        let resourceOptions = MTLResourceOptions()
        
        var threadMemSize = 0
        
        var maxInfSize = 0
        for node in nodesForCalc {
            let theInfluencedBy = node.infBy(self)
            if(theInfluencedBy.count > maxInfSize) {
                maxInfSize = theInfluencedBy.count
            }
        }
        if(maxInfSize<1){
            return false //so that we don't work with completely unlinked graphs
        }
        
        //Maximum CPT size for a node
        let maxCPTSize = Int(pow(2.0, Double(maxInfSize)))
        
        
        //Buffer 0: RNG seeds
        var seeds = [UInt32](repeating: 0, count: ntWidth)
        let seedsbuffer = self.device.makeBuffer(bytes: &seeds, length: seeds.count*MemoryLayout<UInt32>.stride, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        threadMemSize += seeds.count*MemoryLayout<UInt32>.stride
        
        
        //Buffer 1: BN Results
        var bnresults = [Float](repeating: -1.0, count: ntWidth*nodesForCalc.count)
        let bnresultsbuffer = self.device.makeBuffer(bytes: &bnresults, length: bnresults.count*MemoryLayout<Float>.stride, options: resourceOptions)
        threadMemSize += bnresults.count*MemoryLayout<Float>.stride
        
        
        //Buffer 2: Integer Parameters
        var intparams = [UInt32]()
        intparams.append((curModel.runsper as! UInt32) + (curModel.burnins as! UInt32)) //0
        intparams.append(curModel.burnins as! UInt32) //1
        intparams.append(UInt32(nodesForCalc.count)) //2
        intparams.append(UInt32(maxInfSize)) //3
        intparams.append(UInt32(maxCPTSize)) //4
        intparams.append(curModel.thin as! UInt32) //5
        let intparamsbuffer = self.device.makeBuffer(bytes: &intparams, length: intparams.count*MemoryLayout<UInt32>.stride, options: resourceOptions)
        threadMemSize += intparams.count*MemoryLayout<UInt32>.stride
        
        
        //Buffer 3: Prior Distribution Type
        var priordisttypes = [UInt32]()
        for node in nodesForCalc {
            priordisttypes.append(UInt32(node.priorDistType))
        }
        let priordisttypesbuffer = self.device.makeBuffer(bytes: &priordisttypes, length: priordisttypes.count*MemoryLayout<UInt32>.stride, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        threadMemSize += priordisttypes.count*MemoryLayout<UInt32>.stride
        
        
        //Buffer 4: PriorV1
        var priorV1s = [Float]()
        for node in nodesForCalc {
            priorV1s.append(Float(node.priorV1))
        }
        let priorV1sbuffer = self.device.makeBuffer(bytes: &priorV1s, length: priorV1s.count*MemoryLayout<Float>.stride, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        threadMemSize += priorV1s.count*MemoryLayout<Float>.stride
        
        
        //Buffer 5: PriorV2
        var priorV2s = [Float]()
        for node in nodesForCalc {
            priorV2s.append(Float(node.priorV2))
        }
        let priorV2sbuffer = self.device.makeBuffer(bytes: &priorV2s, length: priorV2s.count*MemoryLayout<Float>.stride, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        threadMemSize += priorV2s.count*MemoryLayout<Float>.stride
        
        
        //Buffer 6: Infnet
        var sInfNet = [[Int32]]()
        var infnet = [Int32]()
        for node in nodesForCalc {
            var thisinf = [Int32]()
            let theInfluencedBy = node.infBy(self)
            for thisinfby in theInfluencedBy  {
                let tib = thisinfby as! BNNode
                thisinf.append(Int32(nodesForCalc.index(of: tib)!))
            }
            let leftOver = maxInfSize-thisinf.count
            for _ in 0..<leftOver {
                thisinf.append(Int32(-1.0))
            }
            infnet = infnet + thisinf
            sInfNet.append(thisinf)
        }

        let infnetbuffer = self.device.makeBuffer(bytes: &infnet, length: nodesForCalc.count*maxInfSize*MemoryLayout<Int32>.stride, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        threadMemSize = nodesForCalc.count*maxInfSize*MemoryLayout<Int32>.stride
        
        
        //Buffer 7: Cptnet
        var cptnet = [Float]()
        for node in nodesForCalc {
            let theCPT = node.getCPTArray(self, mocChanged: true, cptReady: 0)
            cptnet = cptnet + theCPT
            let leftOver = maxCPTSize-theCPT.count
            for _ in 0..<leftOver {
                cptnet.append(-1.0)
            }
            
        }
        let cptnetbuffer = self.device.makeBuffer(bytes: &cptnet, length: nodesForCalc.count*maxCPTSize*MemoryLayout<Float>.stride, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        threadMemSize += nodesForCalc.count*maxCPTSize*MemoryLayout<Float>.stride
        
        
        //Buffer 8 Shuffle Buffer
        let shufflebuffer = self.device.makeBuffer(length: ntWidth*nodesForCalc.count*MemoryLayout<UInt32>.stride, options: MTLResourceOptions.storageModePrivate)
        threadMemSize += ntWidth*nodesForCalc.count*MemoryLayout<UInt32>.stride
        
        
        //Buffer 9: BNStates array num notdes * ntWidth
        let bnstatesbuffer = self.device.makeBuffer(length: ntWidth*nodesForCalc.count*MemoryLayout<Float>.stride, options: MTLResourceOptions.storageModePrivate)
        threadMemSize += ntWidth*nodesForCalc.count*MemoryLayout<Float>.stride
        
        
        //Buffer 10: Prior values
        var priors = [Float](repeating: -1.0, count: ntWidth*nodesForCalc.count)
        let priorsbuffer = self.device.makeBuffer(bytes: &priors, length: priors.count*MemoryLayout<Float>.stride, options: resourceOptions)
        threadMemSize += ntWidth*nodesForCalc.count*MemoryLayout<Float>.stride
        
        //Buffer 11: BNStates output array num notdes * ntWidth
        var bnstatesout = [Float](repeating: -1.0, count: ntWidth*nodesForCalc.count)
        let bnstatesoutbuffer = self.device.makeBuffer(length: ntWidth*nodesForCalc.count*MemoryLayout<Float>.stride, options: resourceOptions)
        threadMemSize += ntWidth*nodesForCalc.count*MemoryLayout<Float>.stride

        
        DispatchQueue.main.async {
            self.progInd.isIndeterminate = false
            self.progInd.doubleValue = 0
            self.workLabel.stringValue = "Calculating..."
            self.progInd.startAnimation(self)
        }
        
        //Results array
        var results = [[Float]]()
        for _ in nodesForCalc {
            let thisresult = [Float]()
            results.append(thisresult)
        }
        
        //priors array
        var priorresults = [[Float]]()
        for _ in nodesForCalc {
            let thisprior = [Float]()
            priorresults.append(thisprior)
        }
        

        var bnstatesoutresults = [[Float]]()
        for _ in nodesForCalc {
            let thisbnstate = [Float]()
            bnstatesoutresults.append(thisbnstate)
        }
        
//        print("ThreadMemSize \(threadMemSize)")
        
        //RUN LOOP HERE
        var rc = 0
        var resc = 0
        var pesc = 0
        var besc = 0
        let start = NSDate()
        while (rc<runstot){
            

            let commandBuffer = self.commandQueue.makeCommandBuffer()
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            commandEncoder.setComputePipelineState(self.pipelineState)
            

            seeds = (0..<ntWidth).map{_ in arc4random()}
            seedsbuffer.contents().copyBytes(from: seeds, count: seeds.count * MemoryLayout<UInt32>.stride)
            
            
            commandEncoder.setBuffer(seedsbuffer, offset: 0, at: 0)
            commandEncoder.setBuffer(bnresultsbuffer, offset: 0, at: 1)
            commandEncoder.setBuffer(intparamsbuffer, offset: 0, at: 2)
            commandEncoder.setBuffer(priordisttypesbuffer, offset: 0, at: 3)
            commandEncoder.setBuffer(priorV1sbuffer, offset: 0, at: 4)
            commandEncoder.setBuffer(priorV2sbuffer, offset: 0, at: 5)
            commandEncoder.setBuffer(infnetbuffer, offset: 0, at: 6)
            commandEncoder.setBuffer(cptnetbuffer, offset: 0, at: 7)
            commandEncoder.setBuffer(shufflebuffer, offset: 0, at: 8)
            commandEncoder.setBuffer(bnstatesbuffer, offset: 0, at: 9)
            commandEncoder.setBuffer(priorsbuffer, offset: 0, at: 10)
            commandEncoder.setBuffer(bnstatesoutbuffer, offset: 0, at: 11)

            
            commandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
            
            commandEncoder.endEncoding()
            commandBuffer.enqueue()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            
            let bnresultsdata = NSData(bytesNoCopy: bnresultsbuffer.contents(), length: bnresults.count*MemoryLayout<Float>.stride, freeWhenDone: false)
            bnresultsdata.getBytes(&bnresults, length:bnresults.count*MemoryLayout<Float>.stride)
            var ri = 0
            for to in bnresults {
                
//                if(to != to || to < 0.0 || to > 1.0) {//fails if nan
//                    print("bare results problem detected. \(to)")
//                }
                
                if resc >= runstot {
                    break
                }
                results[ri].append(to)
//              print(to, terminator:"\t")
                ri = ri + 1
                if ri >= nc {
                    ri = 0
//              print ("\n")
                    resc = resc + 1
                }
            }
            

            let priorsdata = NSData(bytesNoCopy: priorsbuffer.contents(), length: priors.count*MemoryLayout<Float>.stride, freeWhenDone: false)
            priorsdata.getBytes(&priors, length:priors.count*MemoryLayout<Float>.stride)
            ri = 0
            for to in priors {
                
//                if(to != to && to <= 0.0 && to >= 1.0) {//fails if nan
//                    print("bare priors problem detected. \(to)")
//                }
                
                if pesc >= runstot {
                    break
                }
                priorresults[ri].append(to)
//                print(to, terminator:"\t")
                ri = ri + 1
                if ri >= nc {
                    ri = 0
//                print ("\n")
                pesc = pesc + 1
                }
            }
            


            let bnstatesoutdata = NSData(bytesNoCopy: bnstatesoutbuffer.contents(), length: bnstatesout.count*MemoryLayout<Float>.stride, freeWhenDone: false)
            bnstatesoutdata.getBytes(&bnstatesout, length:bnstatesout.count*MemoryLayout<Float>.stride)
            ri = 0
            for to in bnstatesout {
                
                if besc >= runstot {
                    break
                }
//                print(to, terminator:"\t")
                bnstatesoutresults[ri].append(to)

                ri = ri + 1
                if ri >= nc {
                    ri = 0
//                                    print ("\n")
                    besc = besc + 1
                }
            }
            
            rc = rc + ntWidth
            
            DispatchQueue.main.async {
                self.progInd.increment(by: Double(ntWidth))
                self.curLabel.stringValue = String(resc)
            }
            
            // End rc loop
        }
        
        if verbose == true {
            print("Time to run: \(NSDate().timeIntervalSince(start as Date)) seconds.")
        }
        
        var bins = Int(pow(Float(curModel.runstot), 0.5))
        
        if(bins < 100) {
            bins = 100
        }
        
        let binQuotient = 1.0/Float(bins)
        
        var fi = 0
        for priorresult in priorresults {
            let inNode : BNNode = nodesForCalc[fi]
//            print(inNode.nodeLink.name)
//            print(priorresult)
            
            let archivedPriorArray = NSKeyedArchiver.archivedData(withRootObject: priorresult)
            inNode.setValue(archivedPriorArray, forKey: "priorArray")
            
//            let theInfluencedBy : [BNNode] = inNode.influencedBy.array as! [BNNode]
//            if theInfluencedBy.count > 0 { //if dependent node
//                let dummyPrior = [Float](repeating: 0.0, count: priorresult.count)
//                let archivedPriorArray = NSKeyedArchiver.archivedData(withRootObject: dummyPrior)
//                inNode.setValue(archivedPriorArray, forKey: "priorArray")
//            }
//            else {
//
//                let archivedPriorArray = NSKeyedArchiver.archivedData(withRootObject: priorresult)
//                inNode.setValue(archivedPriorArray, forKey: "priorArray")
//
//            }
            
            

            fi = fi + 1
            
        }
        
        fi = 0
        for result in results {

            var postCount = [Int](repeating: 0, count: bins)
            let inNode : BNNode = nodesForCalc[fi]

            let theInfluencedBy : [BNNode] = inNode.influencedBy.array as! [BNNode]
            if theInfluencedBy.count > 0 { //if dependent node
            
                var gi = 0
                var flinetot : Float = 0.0
                var flinecount : Float = 0.0
                for gNode : Float in result {
                    
                    if(gNode == gNode && gNode >= 0.0 && gNode <= 1.0) {//fails if nan
                        
                        var x = (Int)(floor(gNode/binQuotient))
                        if x == bins {
                            x = x - 1
                        }
                        postCount[x] += 1
                        flinetot += gNode
                        flinecount += 1.0
                        
                    }
                    
//                    else{
//                         print("problem detected. gNode is \(gNode)")
//                    }
                    
                    gi += 1
                }
                
                let archivedPostCount = NSKeyedArchiver.archivedData(withRootObject: postCount)
                inNode.setValue(archivedPostCount, forKey: "postCount")
                
                //Stats on post Array
                //Mean
                let flinemean = flinetot / flinecount
                inNode.setValue(flinemean, forKey: "postMean")
                
                //Sample Standard Deviation
                var sumsquares : Float = 0.0
                flinecount = 0.0
                for gNode : Float in result {
                    
                    if(gNode == gNode && gNode >= 0.0 && gNode <= 1.0) {//ignores if nan
                        sumsquares +=  pow(gNode - flinemean, 2.0)
                        flinecount += 1.0
                    }
                }
                
                let ssd = sumsquares / (flinecount - 1.0)
                inNode.setValue(ssd, forKey: "postSSD")
                
                let sortfline = result.sorted()
                let lowTail = sortfline[Int(Float(sortfline.count)*0.05)]
                let highTail = sortfline[Int(Float(sortfline.count)*0.95)]
                
                inNode.setValue(lowTail, forKey: "postETLow")
                inNode.setValue(highTail, forKey: "postETHigh")
                
                //Highest Posterior Density Interval. Alpha = 0.05
                //Where n = sortfline.count (i.e. last entry)
                //Compute credible intervals for j = 0 to j = n - ((1-0.05)n)
                let alpha : Float = 0.05
                let jmax = Int(Float(sortfline.count) - ((1.0-alpha) * Float(sortfline.count)))
                
                var firsthpd = true
                var interval : Float = 0.0
                var low = 0
                var high = (sortfline.count - 1)
                for hpdi in 0..<jmax {
                    let highpos = hpdi + Int(((1.0-alpha)*Float(sortfline.count)))
                    if(firsthpd || (sortfline[highpos] - sortfline[hpdi]) < interval){
                        firsthpd = false
                        interval = sortfline[highpos] - sortfline[hpdi]
                        low = hpdi
                        high = highpos
                    }
                    
                }
                inNode.setValue(sortfline[low], forKey: "postHPDLow")
                inNode.setValue(sortfline[high], forKey: "postHPDHigh")
                
                
                
                let archivedPostArray = NSKeyedArchiver.archivedData(withRootObject: result)
                inNode.setValue(archivedPostArray, forKey: "postArray")
                
                inNode.setValue(inNode.cptArray, forKey: "cptFreezeArray")
            
            }
            
            else {
                let dummyPost = [Float](repeating: 0.0, count: result.count)
                let archivedPostArray = NSKeyedArchiver.archivedData(withRootObject: dummyPost)
                inNode.setValue(archivedPostArray, forKey: "postArray")
                let archivedPostCount = NSKeyedArchiver.archivedData(withRootObject: postCount)
                inNode.setValue(archivedPostCount, forKey: "postCount")
                inNode.setValue(inNode.cptArray, forKey: "cptFreezeArray")
            }
            
            fi = fi + 1
            
            if self.breakloop == true {
                return false
            }
                
        }
        
        let score = self.calcMarginalLikelihood(curModel: curModel, nodesForCalc: nodesForCalc, infnet : sInfNet, results : results, priorresults : priorresults, bnstatesoutresults : bnstatesoutresults)
//                let lscore = self.calcLikelihood(curModel: curModel, nodesForCalc: nodesForCalc)
//        print("score \(score)")
//        print("bic \(lscore)")
        curModel.setValue(score, forKey: "score")
        
            DispatchQueue.main.async {
                curModel.complete = true
                
                
        }
        self.performSelector(onMainThread: #selector(PlexusMainWindowController.betweenRuns), with: nil, waitUntilDone: true)
        if verbose == true {
            print("Full run: \(NSDate().timeIntervalSince(start as Date)) seconds.")
        }
        return true
    }
    
    
  
    

    
    @IBAction func lockToggle(_ x:NSToolbarItem){

        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        if(curModel.complete == true){
           print ("locked")
        }
        else {

            //delete all posterior data
            let curNodes  = curModel.bnnode.allObjects as! [BNNode]
            for curNode : BNNode in curNodes {
                curNode.setValue(nil, forKey: "cptFreezeArray")
                curNode.setValue(nil, forKey: "postArray")
                curNode.setValue(nil, forKey: "postCount")
                curNode.setValue(nil, forKey: "postMean")
                curNode.setValue(nil, forKey: "postETLow")
                curNode.setValue(nil, forKey: "postETHigh")
                curNode.setValue(nil, forKey: "postHPDLow")
                curNode.setValue(nil, forKey: "postHPDHigh")
            }
            
        }
    
    
    }
    
    @IBAction func exportCSV(_ x:NSToolbarItem){



        
        let curModels : [Model] = self.mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        
        let defaults = UserDefaults.standard
        let pTypes = defaults.array(forKey: "PriorTypes") as! [String]
        
        let sv:NSSavePanel = NSSavePanel()
        sv.nameFieldStringValue = curModel.name
        
        
        let result = sv.runModal()
        sv.close()
        
        if (result == NSFileHandlingPanelOKButton) {
            mainSplitViewController.modelDetailViewController?.calcInProgress = true
           
            var baseFile  = sv.url?.absoluteString
            let baseDir = sv.directoryURL
            
            do {
                try FileManager.default.removeItem(at: sv.url!)
            }  catch _ as NSError {
                //print(error.description)
            }
            
            
            do {
                try FileManager.default.createDirectory(at: baseDir!.appendingPathComponent(sv.nameFieldStringValue), withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.description)
                return
            }
 
            baseFile = baseFile! + "/" + sv.nameFieldStringValue.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
            
            let outFileName = baseFile! + "-data.csv"

            let outURL = URL(string: outFileName)
            

            DispatchQueue.global().async {


                    
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
                    let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
                    let moc = appDelegate.managedObjectContext
                    
                    let request = NSFetchRequest<Entry>(entityName: "Entry")
                    do {
                        theEntries = try moc.fetch(request)
                    } catch let error as NSError {
                        print (error)
                        return
                    }
                    
                }
                
                var allScopedTraits  = [Trait]()
                for thisEntry in theEntries {
                    for thisTrait in thisEntry.trait {
                        let curTrait = thisTrait as! Trait
                        allScopedTraits.append(curTrait)
                    }
                }
                
                let distinctHeaderTraits = NSSet(array: allScopedTraits.map { $0.name })
                

                
                // #
              //  let entries : [Entry] = try self.moc!.fetch(request)
                self.performSelector(onMainThread: #selector(PlexusMainWindowController.startProgInd), with: nil, waitUntilDone: true)

                self.maxLabel.stringValue = String(theEntries.count)
                self.progInd.isIndeterminate = true
                self.workLabel.stringValue = "Exporting Entries..."
                self.progInd.doubleValue = 0
                
                self.progInd.startAnimation(self)
                
                
                self.progInd.maxValue =  Double(theEntries.count)
                
                
                self.progInd.startAnimation(self)
                
                var outText = "Name,"
                
                
                var i = 0

                for headerTrait in distinctHeaderTraits {
                    outText += headerTrait as! String
                    
                    outText += ","
                    
                }
                outText += "\n"
                
                self.progInd.isIndeterminate = false
                
                for entry : Entry in theEntries {
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
                                outText += ","
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
                    

                DispatchQueue.main.async {
                
                    self.progInd.isIndeterminate = true
                    self.progInd.startAnimation(self)
                    self.workLabel.stringValue = "Exporting Nodes..."
                    
                    var i = 0
                    
                    let nodeTXTFileName = baseFile! + "-nodes.csv"
                    let nodeTXTURL = URL(string: nodeTXTFileName)
                    var outText : String = String()
                    
                    var longestColumn = 0
                    
                    var postBins = [[Double]]()
                    var postCounts = [[Int]]()
                    var postArrays = [[Double]]()
                    
                    for node in self.mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode] {
                        self.mainSplitViewController.modelDetailViewController?.nodesController.setSelectionIndex(i)
                        
                        outText += node.nodeLink.name
                        outText += "-PriorType,"
                        
                        outText += node.nodeLink.name
                        outText += "-PriorV1,"
                        
                        outText += node.nodeLink.name
                        outText += "-PriorV2,"
                        


                        
                        outText += node.nodeLink.name
                        outText += "-PostCount,"
                        
                         let postCount = NSKeyedUnarchiver.unarchiveObject(with: node.value(forKey: "postCount") as! Data) as! [Int]
                        if (postCount.count > longestColumn){
                            longestColumn = postCount.count
                        }
                        postCounts.append(postCount)
                        
                        let postCountDub = Double(postCount.count)
                        
                        var postBin = [Double]()
                        var binc = 0.0
                        for _ in postCount {
                            postBin.append(binc/postCountDub)
                            binc = binc + 1
                        }
                        if (postBin.count > longestColumn){
                            longestColumn = postBin.count
                        }
                        postBins.append(postBin)
                        
                        outText += node.nodeLink.name
                        outText += "-PostBins,"
                        
                        
                        outText += node.nodeLink.name
                        outText += "-PostDist,"
                        let postArray = NSKeyedUnarchiver.unarchiveObject(with: node.value(forKey: "postArray") as! Data) as! [Double]
                        if (postArray.count > longestColumn){
                            longestColumn = postArray.count
                        }
                        postArrays.append(postArray)
                        
                        
                        
                    }
                    
                    outText += "\n"
                    for j in 0...longestColumn{
                        var k = 0
                        for node in self.mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode] {
                            self.mainSplitViewController.modelDetailViewController?.nodesController.setSelectionIndex(i)
                            if(j==0){
                                outText += pTypes[node.priorDistType as! Int]
                                outText += ","
                                outText += String(describing: node.priorV1)
                                outText += ","
                                outText += String(describing: node.priorV2)
                                outText += ","
                            }
                            else {
                                outText += ",,,"
                            }
                            if(j<postCounts[k].count){
                                outText += String(postCounts[k][j])
                            }
                            outText += ","
                            
                            if(j<postBins[k].count){
                                outText += String(postBins[k][j])
                            }
                            outText += ","
                            
                            if(j<postArrays[k].count){
                                outText += String(postArrays[k][j])
                            }
                            
                            
                            outText += ","
                            
                            
                        }
                        
                        k = k + 1
                        outText += "\n"
  
                    }
                    
 
                    do {
                        try outText.write(to: nodeTXTURL!, atomically: true, encoding: String.Encoding.utf8)
                    }
                    catch let error as NSError {
                        print(error)
                    } catch {
                        fatalError()
                    }
                    
                    

                    for node in self.mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode] {
                        self.mainSplitViewController.modelDetailViewController?.nodesController.setSelectionIndex(i)


                        
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
                        

                        let titleStyle = CPTMutableTextStyle()
                        titleStyle.fontName = "Helvetica-Bold"
                        titleStyle.fontSize = 18.0
                        titleStyle.color = CPTColor.black()
                        graph?.titleTextStyle = titleStyle
                        graph?.title = node.nodeLink.name
                        
                        let titleTextStyle = CPTMutableTextStyle.init()
                        titleTextStyle.color = CPTColor.white()
                        
                        

                        for plot in (graph?.allPlots())! {
                            plot.attributedTitle = nil
                            if(plot.identifier!.isEqual("PriorPlot")){
                                plot.title = "Prior"

                            }
                            else {
                                plot.title = "Posterior"

                            }
                        }
                        


                        

                        

                        
                        let axisSet = graph?.axisSet as! CPTXYAxisSet
                        let axisLineStyle = CPTMutableLineStyle.init()
                        axisLineStyle.lineColor = CPTColor.black()
                        axisSet.xAxis!.axisConstraints = CPTConstraints.constraint(withUpperOffset: 1.0)
                        axisSet.yAxis!.axisConstraints = CPTConstraints.constraint(withUpperOffset: 1.0)
                        axisSet.yAxis!.axisConstraints = CPTConstraints.constraint(withLowerOffset: 0.0)
                        axisSet.xAxis!.axisConstraints = CPTConstraints.constraint(withLowerOffset: 0.0)
                        axisSet.xAxis!.tickDirection = CPTSign.positive
                        axisSet.yAxis!.tickDirection = CPTSign.positive
                        axisSet.xAxis?.axisLineStyle = axisLineStyle
                        axisSet.xAxis?.majorTickLineStyle = axisLineStyle
                        axisSet.yAxis?.majorTickLineStyle = axisLineStyle
                        axisSet.xAxis?.minorTickLineStyle = axisLineStyle
                        axisSet.yAxis?.minorTickLineStyle = axisLineStyle
                        axisSet.yAxis?.axisLineStyle = axisLineStyle

                        

                        
                        let axisTextStyle = CPTMutableTextStyle.init()
                        axisTextStyle.color = CPTColor.black()
                        
                        axisSet.xAxis?.labelTextStyle = axisTextStyle
                        axisSet.yAxis?.labelTextStyle = axisTextStyle
                        
                        axisSet.xAxis!.labelingPolicy = .automatic
                        axisSet.yAxis!.labelingPolicy = .automatic
                        axisSet.xAxis!.preferredNumberOfMajorTicks = 3
                        axisSet.yAxis!.preferredNumberOfMajorTicks = 3
                        axisSet.xAxis!.minorTicksPerInterval = 4
                        axisSet.yAxis!.minorTicksPerInterval = 4
                        graph?.axisSet = axisSet

                        


                        let pdfData = graph?.dataForPDFRepresentationOfLayer()
                        try? pdfData!.write(to: nodeURL!, options: [.atomic])
                        
                        graph?.title = ""
                        
                        i += 1
                    }
                
 

                    DispatchQueue.main.async {
                        self.mainSplitViewController.modelDetailViewController?.calcInProgress = false
                    }
                    self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)

                    
                }
            
            }

        }
        else { return }
        
        
    }
    
    
    func startProgInd(){
        self.progSheet = self.progSetup(self)
        self.window!.beginSheet(self.progSheet, completionHandler: nil)
        self.progSheet.makeKeyAndOrderFront(self)
    }
    
    
    func betweenRuns(){
        
        if(self.progSheet != nil){

        }
        mainSplitViewController.modelDetailViewController?.setGraphParams()
        mainSplitViewController.modelDetailViewController?.reloadData()
        
    }
    
    
    func endProgInd(){

        if(self.progSheet != nil){
            self.progSheet.orderOut(self)
            self.window!.endSheet(self.progSheet)
        }
        
        do {
            try self.moc.save()
        } catch let error as NSError {
            print(error)
            fatalError("Could not save models")
        }
        
        mainSplitViewController.modelDetailViewController?.setGraphParams()
        mainSplitViewController.modelDetailViewController?.reloadData()
        
    }
 
    

    
/*************************** Likelihood functions  ****/
    
    func calcLikelihood(curModel:Model, nodesForCalc:[BNNode]) -> Float {
        
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        let moc = appDelegate.managedObjectContext

        var subsamp = curModel.runsper as! Int
        if subsamp < 1000  {
            subsamp = 1000
        }
        if subsamp > curModel.runstot as! Int {
            subsamp = curModel.runstot as! Int
        }
        // Get the yes-no's within the scope of the data
        let theEntries = self.entriesInScope(curModel: curModel)

        var dataratios = [Float]()
        var matches = [Float]()
        var tots = [Float]()
        
        for calcNode in nodesForCalc {
            let calcTrait = calcNode.nodeLink as! Trait
            let calcValue = calcTrait.traitValue
            
            var theTraits = [Trait]()
            let predicate = NSPredicate(format: "entry IN %@ && name == %@", theEntries, calcNode.nodeLink.name)
            let request = NSFetchRequest<Trait>(entityName: "Trait")
            request.predicate = predicate
            do {
                theTraits = try moc.fetch(request)
            } catch let error as NSError {
                print (error)
                return -999
            }
            
            
            var mTraits = [Trait]()
            
            if calcNode.numericData == true {
                let calcNumVal = Double(calcValue)
                let tol = calcNode.tolerance as! Double
                let lowT = calcNumVal! * (1.0 - (tol/2.0))
                let highT = calcNumVal! * (1.0 + (tol/2.0))
                
                for chkTrait in theTraits {
                    if ((Double(chkTrait.traitValue)!) < highT || (Double(chkTrait.traitValue)!) > lowT) {
                        mTraits.append(chkTrait)
                    }
                }
                
            }
            else {
                let mpredicate = NSPredicate(format: "entry IN %@ && name == %@ && traitValue == %@", theEntries, calcNode.nodeLink.name, calcValue)
                let mrequest = NSFetchRequest<Trait>(entityName: "Trait")
                mrequest.predicate = mpredicate
                do {
                    mTraits = try moc.fetch(mrequest)
                } catch let error as NSError {
                    print (error)
                    return -999
                }
            }
            matches.append(Float(mTraits.count))
            tots.append(Float(theTraits.count))
            dataratios.append(Float(mTraits.count) / Float(theTraits.count))
        
        }
        
        //Check that all post arrays are same length
        //Subsample from the posteriors
        var firstnode = true
        var postlength = -1
        var sampS = [Int]()
        var posts = [[Float]]()
        
        for calcNode in nodesForCalc {
            let postArray = NSKeyedUnarchiver.unarchiveObject(with: calcNode.value(forKey: "postArray") as! Data) as! [Float]
            if(firstnode == true){
                firstnode = false
                postlength = postArray.count
                for _ in 0...postlength {
                    sampS.append(Int(arc4random_uniform(UInt32(postlength))))
                }
            }
            else {
                if postlength != postArray.count{
                    print("post array lengths do not match!")
                    
                }
            }
            var thisposts = [Float]()
            for sp in sampS{
                thisposts.append(postArray[sp])
            }
            posts.append(thisposts)
        }
        
        //Pick index where likelihood of the posterior is the highest
        var maxlike = Float(0.0)
        var maxpos = -1
        var firsttime = true
        for s in 0...(postlength-1) {
            var likes = [Float]()
            for r in 0...(nodesForCalc.count-1){
                likes.append( pow(posts[r][s], matches[r]) * pow(1-(posts[r][s]), (tots[r]-matches[r])))
                let likelihood = log(likes.reduce(1, *)) // Should not the likelihood of the data be the product of the likelihoods of the parzmeters assumig they ate indepent?
                if firsttime == true {
                    maxlike = likelihood
                    maxpos = s
                    firsttime = false
                }
                    else{
                    if (likelihood > maxlike) {
                        maxlike = likelihood
                        maxpos = s
                    }
                }
                

            }
        }
        
        return maxlike - ((Float(nodesForCalc.count) / 2.0) * log(Float(postlength)))
        
    }

    
    func calcMarginalLikelihood(curModel:Model, nodesForCalc:[BNNode], infnet:[[Int32]], results : [[Float]], priorresults : [[Float]], bnstatesoutresults : [[Float]]) -> Float {
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        let moc = appDelegate.managedObjectContext
        
        var subsamp = curModel.runsper as! Int
        if subsamp < 1000  {
            subsamp = 1000
        }
        if subsamp > curModel.runstot as! Int {
            subsamp = curModel.runstot as! Int
        }
        // Get the yes-no's within the scope of the data
        let theEntries = self.entriesInScope(curModel: curModel)
        
        var dataratios = [Float]()
        var matches = [Float]()
        var tots = [Float]()
        
        for calcNode in nodesForCalc {
            let calcTrait = calcNode.nodeLink as! Trait
            let calcValue = calcTrait.traitValue
            
            var theTraits = [Trait]()
            let predicate = NSPredicate(format: "entry IN %@ && name == %@", theEntries, calcNode.nodeLink.name)
            let request = NSFetchRequest<Trait>(entityName: "Trait")
            request.predicate = predicate
            do {
                theTraits = try moc.fetch(request)
            } catch let error as NSError {
                print (error)
                return -999
            }
            
            
            var mTraits = [Trait]()
            
            if calcNode.numericData == true {
                let calcNumVal = Double(calcValue)
                let tol = calcNode.tolerance as! Double
                let lowT = calcNumVal! * (1.0 - (tol/2.0))
                let highT = calcNumVal! * (1.0 + (tol/2.0))
                
                for chkTrait in theTraits {
                    if ((Double(chkTrait.traitValue)!) < highT || (Double(chkTrait.traitValue)!) > lowT) {
                        mTraits.append(chkTrait)
                    }
                }
                
            }
            else {
                let mpredicate = NSPredicate(format: "entry IN %@ && name == %@ && traitValue == %@", theEntries, calcNode.nodeLink.name, calcValue)
                let mrequest = NSFetchRequest<Trait>(entityName: "Trait")
                mrequest.predicate = mpredicate
                do {
                    mTraits = try moc.fetch(mrequest)
                } catch let error as NSError {
                    print (error)
                    return -999
                }
            }
            matches.append(Float(mTraits.count))
            tots.append(Float(theTraits.count))
            dataratios.append(Float(mTraits.count) / Float(theTraits.count))
            
        }
//        print(dataratios)
        //Check that all post arrays are same length
        //Subsample from the posteriors
        var firstnode = true
        var postlength = -1
        var priorlength = -1
        var sampS = [Int]()
        var posts = [[Float]]()
        var priors = [[Float]]()
        var nc = 0
        
        for nodeForCalc in nodesForCalc {
//            print (nodeForCalc.nodeLink.name)
            let postArray = results[nc]
            let priorArray = priorresults[nc]
            if(firstnode == true){
                firstnode = false
                postlength = postArray.count
                priorlength = priorArray.count
                if priorlength != postlength {
                    fatalError("priorlength and postlength shoudl be same!")
                }
                for _ in 0...postlength {
                    sampS.append(Int(arc4random_uniform(UInt32(postlength))))
                }
            }
            else {
                if postlength != postArray.count{
                    fatalError("post array lengths do not match!")
                }
                if postlength != priorArray.count{
                    fatalError("prior array lengths do not match!")
                }
            }
            var thisposts = [Float]()
            var thispriors = [Float]()
            for sp in sampS{
                thisposts.append(postArray[sp])
                thispriors.append(priorArray[sp])
            }
//            print("PRIOR")
//            print(thispriors)
//            print("POST")
//            print(thisposts)
            posts.append(thisposts)
            priors.append(thispriors)
            nc =  nc + 1
        }
        

        
        //Pick index where likelihood of the posterior is the highest
        var maxlike = Float(0.0)
        var maxpos = -1
        var firsttime = true
        for s in 0...(postlength-1) {
            var likes = [Float]()
            for r in 0...(nodesForCalc.count-1){
//                print(nodesForCalc[r].nodeLink.name)
                if(tots[r]>0) { // to avoid hidden or data-free nodes in likelihood calc
//                    print(posts[r][s])
//                    print(matches[r])
//                    print(1-(posts[r][s]))
//                    print(tots[r]-matches[r])
//                    print(pow(posts[r][s], matches[r]))
//                    print(pow(1-(posts[r][s]), (tots[r]-matches[r])))
//                    print(pow(posts[r][s], matches[r]) * pow(1-(posts[r][s]), (tots[r]-matches[r])))
//                    var ml = [Float]()
//                    for _ in 0...Int(matches[r]){
//                        ml.append(posts[r][s])
//                    }
//                    for _ in 0...Int(tots[r]-matches[r]){
//                        ml.append(1-posts[r][s])
//                    }
//                    print(ml)
//                    let newlike = ml.reduce(1, *)
//                    print(newlike)
//                    likes.append(pow(posts[r][s], matches[r]) * pow(1-(posts[r][s]), (tots[r]-matches[r]))) //This is likelihood of data given the POSTERIOR
                    likes.append(pow(matches[r], posts[r][s]) * pow((tots[r]-matches[r]), 1-(posts[r][s]))) //This is likelihood of posterior given the data
                }
            
//                print(likes)
                let likelihood = log(likes.reduce(1, *)) // Joint
                if firsttime == true {
                    maxlike = likelihood
                    maxpos = s
                    firsttime = false
                }
                else{
                    if (likelihood > maxlike) {
                        maxlike = likelihood
                        maxpos = s
                    }
                }
            }
        }
        
        
//        print("\n maxpos \(maxpos)" )
        var postvals = [Float]()
        for r in 0...(nodesForCalc.count-1){
            postvals.append(posts[r][maxpos])
        }
        let postterm = (postvals.reduce(1, *))
//        print("π(ϴ|y) \(postterm)")
        
        
        //Prior
        var priorProds = [Float]()
        nc = 0
        var binsum = Float(0.0)
        var binx = 0
        for r in 0...(nodesForCalc.count-1){
            let thisinfnet = infnet[nc]
            let infBy = nodesForCalc[r].influencedBy
            if infBy.count > 0 { //dependent
                binsum = 0.0
                binx = 0
                for thisinf in thisinfnet{
                    if(thisinf<0){
                        break
                    }
                    binsum = binsum + bnstatesoutresults[nc][binx] * pow(2, Float(binx))
                    binx = binx + 1
                }
                let binfinal = Int(binsum)
                let cptarray = NSKeyedUnarchiver.unarchiveObject(with: nodesForCalc[r].value(forKey: "cptArray") as! Data) as! [cl_float] //FIXME easier to pull this at top of funciton
                priorProds.append(cptarray[binfinal])

            }
            else { //independent
                priorProds.append(priors[r][maxpos])
            }
            nc = nc + 1
        }

//        print(priorProds)
        let priorterm = (priorProds.reduce(1, *))
//        print("π(ϴ) \(priorterm)")

        
        var likes = [Float]()
        for r in 0...(nodesForCalc.count-1){
            
        
            if(tots[r]>0) { // to avoid hidden or data-free nodes in likelihood calc
//                print("\nname: \(nodesForCalc[r].nodeLink.name)")
//                print("prior: \(priorProds[r])")
//                print("matches: \(matches[r])")
//                print("1-prior: \(1-(priorProds[r]))")
//                print("nomatches: \(tots[r]-matches[r])")
//                print("prior^matches \(pow(priorProds[r], matches[r]))")
//                print((pow(1-(priorProds[r]), (tots[r]-matches[r]))))
//                print(log(pow(priorProds[r], matches[r]) * pow(1-(priorProds[r]), (tots[r]-matches[r]))))
                likes.append(log(pow(priorProds[r], matches[r]) * pow(1-(priorProds[r]), (tots[r]-matches[r])))) //This is likelihood of data given the Priors
            }
            
        }
//        print (likes)
        let likelihood = likes.reduce(1, +)
//        print("f(y|ϴ) \(likelihood)")
        
        
//        //Posterior
//        var postProds = [Float]()
//        for calcNode in nodesForCalc {
//            let infBy = calcNode.influencedBy
//            if infBy.count > 0 { //depednet
//                let postArray = NSKeyedUnarchiver.unarchiveObject(with: calcNode.value(forKey: "postArray") as! Data) as! [Float]
//                postProds.append(postArray[maxpos])
//            }
//            else { //independent
//                let priorArray = NSKeyedUnarchiver.unarchiveObject(with: calcNode.value(forKey: "priorArray") as! Data) as! [Float]
//                postProds.append(priorArray[maxpos])
//            }
//
//        }
//
//        print(postProds)
        
//        let postterm = (postProds.reduce(1, *))
//        print("pi theta | y \(postterm)")
        

        return log(priorterm) + likelihood - log(postterm)
        
    }
    
    func entriesInScope(curModel:Model) -> [Entry] {
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
            } catch let error as NSError {
                fatalError()
            }
            
        }
        return theEntries
    }
    
   
    
    func contextDidSave(_ notification: Notification) {
        let savedContext = notification.object as! NSManagedObjectContext
        if(savedContext == self.moc) { // ignore change notifications for the main MOC
            return
        }
        DispatchQueue.main.sync {
            self.moc.mergeChanges(fromContextDidSave: notification)
        }
        

    }
}
