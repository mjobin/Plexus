//
//  PlexusMainWindowController.swift
//  Plexus
//
//  Created by matt on 10/1/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Cocoa
import CoreData
import Metal

class PlexusMainWindowController: NSWindowController, NSWindowDelegate {
    
  
    var moc : NSManagedObjectContext!
    var mainSplitViewController = PlexusMainSplitViewController()
    @IBOutlet var mainToolbar : NSToolbar!
    @IBOutlet var testprog : NSProgressIndicator!
    @IBOutlet var metalDevices = MTLCopyAllDevices()
    @IBOutlet dynamic var devicesController : NSArrayController!


    let queue = DispatchQueue(label: "com.plexus.Plexus.metalQueue")


    var device : MTLDevice!
    var pipelineState : MTLComputePipelineState!
    var kernelFunction : MTLFunction!
    
    lazy var defaultLibrary: MTLLibrary! = {
        self.device.newDefaultLibrary()
    }()
    lazy var commandQueue: MTLCommandQueue! = {
        print ("Metal device: \(self.device.name!). Headless: \(self.device.isHeadless). Low Power: \(self.device.isLowPower)")
        return self.device.makeCommandQueue()
    }()
    
    
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
    

    var timeLabel : NSTextField!
    var timeOfLabel : NSTextField!
    var timeMaxLabel : NSTextField!
     

    
    var breakloop = false
    
    

    

    dynamic var modelTreeController : NSTreeController!
    

    
    override func windowWillLoad() {
        
        //let errorPtr : NSErrorPointer = nil

        //Get MOC from App delegate
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.persistentContainer.viewContext
        
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
            newModel.setValue(NSNumber.init(floatLiteral: -Double.infinity), forKey: "score")
            do {
                try moc.save()
            } catch let error as NSError {
                print(error)
            }

        }
        


//        NotificationCenter.default.addObserver(self, selector: #selector(PlexusMainWindowController.contextDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(PlexusMainWindowController.contextWillSave(_:)), name: Notification.Name.NSManagedObjectContextWillSave, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlexusMainWindowController.contextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        
        
        
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        mainSplitViewController = contentViewController as! PlexusMainSplitViewController

 
        modelTreeController = mainSplitViewController.modelViewController?.modelTreeController
        
//        queue.async {
//            self.setUpMetal()
//        }
        

        
    }
    


    
    @IBAction func  toggleModels(_ x:NSToolbarItem){


        mainSplitViewController.toggleModels(x)
        
    }
    

    
    func secondsConvert(secs : Double, retUnit:Bool) -> String {
        var retString = String()
        if secs > 43200 {
            retString += String(secs.rounded()/43200.00)
            if retUnit {
                retString += " days"
            }
            
        }
        else if secs > 3600 {
            retString += String(secs.rounded()/3600.00)
            if retUnit {
                retString += " hours"
            }
        }
        else if secs > 60 {
            retString += String(secs.rounded()/60.00)
            if retUnit {
                retString += " minutes"
            }
        }
        else {
            retString += String(secs.rounded())
            if retUnit {
                retString += " seconds"
            }
        }
        
        if retUnit {
        retString += "."
        }
        return retString
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
        
        self.timeLabel = NSTextField(frame: NSRect(x: 10, y: 12, width: 24, height: 20))
        timeLabel.isEditable = false
        timeLabel.drawsBackground = false
        timeLabel.isSelectable = false
        timeLabel.isBezeled = false
        timeLabel.stringValue = String(0.0)
        
        self.timeOfLabel = NSTextField(frame: NSRect(x: 34, y: 12, width: 24, height: 20))
        timeOfLabel.isEditable = false
        timeOfLabel.drawsBackground = false
        timeOfLabel.isSelectable = false
        timeOfLabel.isBezeled = false
        timeOfLabel.stringValue = "of"
        
        
        self.timeMaxLabel = NSTextField(frame: NSRect(x: 54, y: 12, width: 128, height: 20))
        timeMaxLabel.isEditable = false
        timeMaxLabel.drawsBackground = false
        timeMaxLabel.isSelectable = false
        timeMaxLabel.isBezeled = false
        timeMaxLabel.stringValue = String(0.0)
        
        contentView.addSubview(workLabel)
        contentView.addSubview(curLabel)
        contentView.addSubview(ofLabel)
        contentView.addSubview(maxLabel)
        contentView.addSubview(progInd)
        contentView.addSubview(cancelButton)
        
        contentView.addSubview(timeLabel)
        contentView.addSubview(timeOfLabel)
        contentView.addSubview(timeMaxLabel)
        
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
        
        
        self.timeLabel = NSTextField(frame: NSRect(x: 10, y: 12, width: 24, height: 20))
        timeLabel.isEditable = false
        timeLabel.drawsBackground = false
        timeLabel.isSelectable = false
        timeLabel.isBezeled = false
        timeLabel.stringValue = String(0.0)
        
        self.timeOfLabel = NSTextField(frame: NSRect(x: 34, y: 12, width: 24, height: 20))
        timeOfLabel.isEditable = false
        timeOfLabel.drawsBackground = false
        timeOfLabel.isSelectable = false
        timeOfLabel.isBezeled = false
        timeOfLabel.stringValue = "of"
        
    
        self.timeMaxLabel = NSTextField(frame: NSRect(x: 54, y: 12, width: 128, height: 20))
        timeMaxLabel.isEditable = false
        timeMaxLabel.drawsBackground = false
        timeMaxLabel.isSelectable = false
        timeMaxLabel.isBezeled = false
        timeMaxLabel.stringValue = String(0.0)
        
        
        contentView.addSubview(workLabel)
        contentView.addSubview(curLabel)
        contentView.addSubview(ofLabel)
        contentView.addSubview(maxLabel)
        contentView.addSubview(progInd)
        contentView.addSubview(cancelButton)
        
        contentView.addSubview(timeLabel)
        contentView.addSubview(timeOfLabel)
        contentView.addSubview(timeMaxLabel)
        
        contentView.addSubview(hProgInd)
        contentView.addSubview(hworkLabel)
        
        contentView.addSubview(rProgInd)
        contentView.addSubview(rworkLabel)
        
        retWin.contentView = contentView
        
        
        return retWin
    }
    
    
    @IBAction func  importCSV(_ x:NSToolbarItem){


        self.mainSplitViewController.entryController.fetch(self)
        self.breakloop = false
        
        
        //Open panel for .csv files only
        let op:NSOpenPanel = NSOpenPanel()
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true
        op.allowedFileTypes = ["csv"]
        
//        let aView : NSView = NSView(frame: NSMakeRect(0.0, 0.0, 324.0, 22.0))
//        
//        //accessory view to allow addition to current locaiton
//        let av:NSButton = NSButton(frame: NSMakeRect(0.0, 0.0, 140.0, 22.0))
//        av.setButtonType(NSButtonType.switch)
//        av.title = "Add as child"
//        av.state = 0
//        aView.addSubview(av)
//        op.accessoryView = aView
//        
//        let sc:NSButton = NSButton(frame: NSMakeRect(170.0, 0.0, 140.0, 22.0))
//        sc.setButtonType(NSButtonType.switch)
//        sc.title = "Create new model"
//        sc.state = 1
//        aView.addSubview(sc)
//        
//        op.accessoryView = aView
//        
//        
//       //
//        if #available(OSX 10.11, *) {
//            op.isAccessoryViewDisclosed = true
//        } else {
//            op.accessoryView?.isHidden = false
//        }
        
        let result = op.runModal()
        

        
        op.close()
        

        
        if (result == NSFileHandlingPanelOKButton) {
            mainSplitViewController.modelDetailViewController?.calcInProgress = true
            var i = 1
            var firstLine = true
            let inFile  = op.url
            let inFileBase = inFile?.deletingPathExtension()


            DispatchQueue.global().async {
                
                let inMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                inMOC.undoManager = nil
                inMOC.persistentStoreCoordinator = self.moc.persistentStoreCoordinator
                
                let newModel : Model = Model(entity: NSEntityDescription.entity(forEntityName: "Model", in: self.moc)!, insertInto: inMOC)
                newModel.setValue(inFileBase?.lastPathComponent, forKey: "name")
                newModel.setValue(NSNumber.init(floatLiteral: -Double.infinity), forKey: "score")
                
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
                            

                            
                            newModel.addAnEntryObject(newEntry)
                            newEntry.addAModelObject(newModel)

                            



                            

                            
                            columnCount = 0
                            for thisTrait in theTraits {

                                
                                if(columnCount != nameColumn){
                                    
                                    let theSubTraits : [String] = thisTrait.components(separatedBy: "\t")
                                    
                                    for thisSubTrait in theSubTraits {
                                        if(thisSubTrait.trimmingCharacters(in: delimiterCharacterSet as CharacterSet) != "" ){//ignore empty
                                            let newTrait : Trait = Trait(entity: NSEntityDescription.entity(forEntityName: "Trait", in: inMOC)!, insertInto: inMOC)
                                            newTrait.setValue(headers[columnCount], forKey: "name")
                                            newTrait.setValue(thisSubTrait.trimmingCharacters(in: delimiterCharacterSet as CharacterSet), forKey: "value")
                                            newTrait.setValue(newEntry, forKey: "entry")
                                            
                                            newEntry.addATraitObject(newTrait)
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
                        self.mainSplitViewController.entryController.fetch(self)
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
    
    /**
     Creates a copied, then randomly altered Model based on an exisitng Model.
     
     - Parameters:
     - lastModel: Initial Model to be altered.
     - allTraits: List of all Traits connected to the Model. Here for convenience, since he Traits will not change model to model.
     - inituserTraitNames: List of Trait names already in the Model, to avoid duplication.
     - thisMOC: Currently used Managed Object context. Can be nil.
     
     - Returns: A copy of lastModel, randomly altered.
     */
    func randomChildModel(lastModel : Model, allTraits: [Trait], initusedTraitNames: Set<String>, thisMOC : NSManagedObjectContext?) -> Model {
        var usedTraitNames = initusedTraitNames
        let newModel = lastModel.copySelf(moc: thisMOC ?? nil, withEntries: true)
        
        let nodesForTest = newModel.bnnode.allObjects as! [BNNode]
        if nodesForTest.count < 2 {
            return lastModel //This should not happen, but if the intila model already has less than two nodes, do not proceed. This allows the random node selection below to work.
        }
        

        var nochange = true
        
        while nochange {
            
            let fromPos = Int.random(in: 0..<nodesForTest.count)
            var toPos = fromPos
            
            while toPos == fromPos {
                toPos = Int.random(in: 0..<nodesForTest.count)
            }
            
            let fromNode = nodesForTest[fromPos]
            let toNode = nodesForTest[toPos]
            

            
            //Check if there is an arc between them
            var isinfArc = false
            var isinfByArc = false
            
            for thisDownNode in fromNode.downNodes(self) {
                if thisDownNode == toNode {
                    isinfArc = true
                    break
                }
            }
            
            for thisUpNode in fromNode.upNodes(self) {
                if thisUpNode == toNode {
                    isinfByArc = true
                    break
                }
            }
            
            let switchup = Int.random(in: 1 ... 5)
            switch switchup {
                //Change an ifthen if the from node has no data
                case 1:
                    let request = NSFetchRequest<Trait>(entityName: "Trait")
                    let predicate = NSPredicate(format: "entry IN %@ && name == %@", argumentArray: [newModel.entry, fromNode.name])
                    request.predicate = predicate
                    do {
                        let allCount = try moc.count(for: request)
                        if allCount < 1 {
                            if let interNode = fromNode.getDownInterBetween(downNode: toNode){
                                interNode.ifthen =  NSNumber(value: Float.random(in: 0 ... 1))
                                nochange = false
                            }
                        }
                        
                    } catch {
                        fatalError("Failed request.")
                }
                //Add a hidden node wih no data pointing at toNode, or if it is hidden, remove it
                case 2:
                    if toNode.hidden == true {
//                        print("Removing hidden")
                        newModel.removeABNNodeObject(toNode)
                        toNode.removeSelfFromNeighbors(moc: thisMOC)
                        thisMOC?.delete(toNode)
                        nochange = false
                    }
                    
                    else {
                        var hashidden = false
                        for thisUpNode in toNode.upNodes(self){
                            if thisUpNode.hidden == true {
                                hashidden = true
                            }
                        }
                        
                        if hashidden == false {
//                            print("Adding hidden")
                            let newNode : BNNode = BNNode(entity: BNNode.entity(), insertInto: thisMOC)
                            newNode.name = "hidden"
                            newNode.hidden = true
                            newModel.addABNNodeObject(newNode)
                            newNode.model = newModel
                            newNode.priorDistType = 1 //Set uniform prior
                            newNode.priorV1 = 0.0
                            newNode.priorV2 = 1.0
                            
                            let newInter = newNode.addADownObject(downNode: toNode, moc: thisMOC)
                            newInter.ifthen = 0.5
                            nochange = false
                        }
                    }
                
                case 3: // Change the direction of an existing arrow
//                    print("Changing arrow")
                    if fromNode.hidden == false && toNode.hidden == false { //Do not remove or reverse arrows for hidden nodes
                        if isinfArc == true && isinfByArc == false {

                            if Bool.random() { // delete arc
                                fromNode.removeADownObject(downNode: toNode, moc: thisMOC)
                            }
                            else { // reverse arc
                                fromNode.removeADownObject(downNode: toNode, moc: thisMOC)
                                _ = toNode.addADownObject(downNode: fromNode, moc: thisMOC)
                            }
                        }
                            
                        else if isinfArc == false && isinfByArc == true {
                            if Bool.random() { // delete arc
                                toNode.removeADownObject(downNode: fromNode, moc: thisMOC)

                            }
                            else { // reverse arc
                                toNode.removeADownObject(downNode: fromNode, moc: thisMOC)
                                _ = fromNode.addADownObject(downNode: toNode, moc: thisMOC)
                            }
                        }
                            
                        else if isinfArc == true && isinfByArc == true {
                            fatalError("Error: infleunces in two directions!")
                        }
                        else { //both false, no arc
                            _ = fromNode.addADownObject(downNode: toNode, moc: thisMOC)
                    }
                        nochange = false
                }
                
            //Change the traitvalue to another. If numeric, change tolerance
            case 4:
//                print("Changing value")
                if  toNode.hidden == false {
                    if toNode.numericData {
                        toNode.tolerance = NSNumber(value: Float.random(in: 0 ... 1))
                    }
                    else {
                        let theEntries = lastModel.entry
                        let predicate = NSPredicate(format: "entry IN %@ && name == %@", theEntries, toNode.name)
                        let request = NSFetchRequest<Trait>(entityName: "Trait")
                        request.predicate = predicate
                        request.propertiesToFetch = ["value"]
                        do {
                            let theValues = try moc.fetch(request)
                            if let picked = theValues.randomElement() {
                                toNode.value = picked.value
                            }
                        } catch let error as NSError {
                            print (error)
                        }
                    }
                    
                    nochange = false
                }
                
            //Add a trait in the model that is not yet used, or remove an instance of it if it is
            case 5:
                let pickedTrait = allTraits.randomElement() as! Trait
                let pickedTraitName = pickedTrait.name
                if usedTraitNames.contains(pickedTraitName) { //Exists, remove an instance
                    if nodesForTest.count > 2 {//Do not reduce the number of nodes to less than 2
                        var neverdeleted = true
                        var numwithname = 0
                        for chkNode in nodesForTest {
                            if chkNode.name == pickedTraitName {
                                numwithname += 1
                                if neverdeleted == true {
//                                    print("Removing a node")
                                    neverdeleted = false
                                    newModel.removeABNNodeObject(chkNode)
                                    chkNode.removeSelfFromNeighbors(moc: thisMOC)
                                    thisMOC?.delete(chkNode)
                                    numwithname = numwithname - 1
                                    nochange = false
                                }
                                
                            }
                        }
                        if numwithname < 1 {
                                usedTraitNames.remove(pickedTraitName)
                        }
                    }
                }
                //Add node, point it to or from toNode
                else{
//                    print("Adding a node")
                    let newNode : BNNode = BNNode(entity: BNNode.entity(), insertInto: thisMOC)
                    newNode.name = pickedTraitName
                    newNode.value = pickedTrait.value
                    newNode.hidden = false
                    newModel.addABNNodeObject(newNode)
                    newNode.model = newModel
                    newNode.priorDistType = 1 //Set uniform prior
                    newNode.priorV1 = 0.0
                    newNode.priorV2 = 1.0
                    
                    if Bool.random() {
                        _ = newNode.addADownObject(downNode: toNode, moc: thisMOC)

                    }
                    else {
                        _ = newNode.addAnUpObject(upNode: toNode, moc: thisMOC)
                    }
                    usedTraitNames.insert(pickedTraitName)
                    nochange = false

                    
                }
                
            default:
//                    fatalError("Error: illegal random model alteration!")

                nochange = false //FIXME remove
            }
        }
        
         //Now make sure the CPT's are recalced
        let afterNodes = newModel.bnnode.allObjects as! [BNNode]
        var testCPT = 2
//        print("\nrandom done")
        for testNode in afterNodes {
//            print("FOR: \(testNode.name)")
            for testDownNode in testNode.downNodes(self){
//                print(" -> \(testDownNode.name)")
              let iN = testNode.addADownObject(downNode: testDownNode, moc: thisMOC)
//                print ("      \(iN.ifthen)   \(iN.isFault)")
            }
            testCPT = testNode.CPT(fake: false)
        }
//        print(" ")
        if testCPT != 2 {
            fatalError("Error creating CPT in randomChildModel.")
        }

        return newModel
    }
    
    
    
    @IBAction func singleRunPress(_ x:NSToolbarItem) {
        
        let devices = devicesController?.selectedObjects as! [MTLDevice]
        device = devices[0]
        kernelFunction  = defaultLibrary?.makeFunction(name: "bngibbs")
        do {
            pipelineState = try device.makeComputePipelineState(function: kernelFunction!)
        }
        catch {
            fatalError("Cannot set up Metal")
        }
        
        mainSplitViewController.modelDetailViewController?.calcInProgress = true
        self.breakloop = false
        
        self.progSheet = self.progSetup(self)
        self.window!.beginSheet(self.progSheet, completionHandler: nil)
        self.progSheet.makeKeyAndOrderFront(self)
        
        let curModels : [Model] = mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let firstModel : Model = curModels[0]
        let theEntries = firstModel.entry
        
        let nodesForTest = firstModel.bnnode.allObjects as! [BNNode]
        if (nodesForTest.count < 2){
            let cancelAlert = NSAlert()
            cancelAlert.alertStyle = .informational
            cancelAlert.messageText = "Need at least two nodes with at least one connection between them."
            cancelAlert.addButton(withTitle: "OK")
            _ = cancelAlert.runModal()

            
                self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
                self.mainSplitViewController.modelDetailViewController?.calcInProgress = false
                return
        }
        
        let calcQueue = DispatchQueue(label: "calcQueue")
        calcQueue.async {
            
            let fmcrun = self.metalCalc(curModel : firstModel,  fake : false, verbose: true)

            self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
            
            DispatchQueue.main.async {
                
                if self.breakloop == true {
                    firstModel.score = NSNumber.init(floatLiteral: -Double.infinity)
                    let cancelAlert = NSAlert()
                    cancelAlert.alertStyle = .informational
                    cancelAlert.messageText = "Run cancelled."
                    cancelAlert.addButton(withTitle: "OK")
                    _ = cancelAlert.runModal()
                    self.breakloop = false
                }
                
                else {
                    if(fmcrun == true){
                        firstModel.complete = true
                    }
                    
                    let scoreAlert = NSAlert()
                    scoreAlert.alertStyle = .informational
                    scoreAlert.messageText = "Model \(firstModel.name) scored \(firstModel.score)"
                    scoreAlert.addButton(withTitle: "OK")
                    _ = scoreAlert.runModal()
                    
                }
                
                self.mainSplitViewController.modelDetailViewController?.calcInProgress = false
                }
                                //end calcQ
            }
        
}
    
 
    @IBAction func hillClimbing(_ x:NSToolbarItem){
        let start = DispatchTime.now()

        let devices = devicesController?.selectedObjects as! [MTLDevice]
        device = devices[0]
        kernelFunction  = defaultLibrary?.makeFunction(name: "bngibbs")
        do {
            pipelineState = try device.makeComputePipelineState(function: kernelFunction!)
        }
        catch {
            fatalError("Cannot set up Metal")
        }
        
        mainSplitViewController.modelDetailViewController?.calcInProgress = true
        self.breakloop = false
        
        
        let curModels : [Model] = mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let firstModel : Model = curModels[0]
        let firstModelID = firstModel.objectID
        var finalModel = firstModel
        
        self.progSheet = self.progHillSetup(self)
        self.window!.beginSheet(self.progSheet, completionHandler: nil)
        self.hProgInd.maxValue =  Double(firstModel.hillchains)
        self.rProgInd.maxValue =  Double(firstModel.runstarts)
        self.progSheet.makeKeyAndOrderFront(self)
        
        let runstarts = firstModel.runstarts
        let hillchains = firstModel.hillchains
        
        let allHillRuns = runstarts.doubleValue * hillchains.doubleValue
        

        var usedTraitNames = Set<String>()
        let nodesForTest = firstModel.bnnode.allObjects as! [BNNode]
        if (nodesForTest.count < 2){
            let cancelAlert = NSAlert()
            cancelAlert.alertStyle = .informational
            cancelAlert.messageText = "Need at least two nodes with at least one connection between them."
            cancelAlert.addButton(withTitle: "OK")
            _ = cancelAlert.runModal()
            self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
            self.mainSplitViewController.modelDetailViewController?.calcInProgress = false
            return
        }
        for firstNode in nodesForTest {
            usedTraitNames.insert(firstNode.name)
        }
        

        //The Traits and Entries involved in a run do not change, so they can be fetched just once
        var allTraits = [Trait]()
        let request = NSFetchRequest<Trait>(entityName: "Trait")
        let predicate = NSPredicate(format: "entry IN %@", argumentArray: [firstModel.entry])
        request.predicate = predicate
        do {
            allTraits = try moc.fetch (request)
            
        } catch {
            fatalError("Failed request searching for all Traits of \(firstModel).")
        }

        var hcount = 0
        let calcQueue = DispatchQueue(label: "calcQueue")
        calcQueue.async {

            let cmoc = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
//            cmoc.persistentStoreCoordinator = self.moc.persistentStoreCoordinator
            cmoc.parent = self.moc
            

            do {
                let cfirstModel = try cmoc.existingObject(with: firstModelID) as! Model
                
                let theEntries = cfirstModel.entry
                
                
                let faultpredicate = NSPredicate(format:"self IN %@", theEntries) //This should fire the faults for all the entries in the model
                let faultrequest = NSFetchRequest<Entry>(entityName: "Entry")
                faultrequest.predicate = faultpredicate
                faultrequest.returnsObjectsAsFaults = false
                do {
                    _ = try cmoc.fetch(faultrequest)
                    
                } catch let error as NSError {
                    print (error)
                }
                
                

                
                if cfirstModel.score.floatValue <= -Float.infinity {
                    _ = self.metalCalc(curModel: cfirstModel, fake : false, verbose: true)
                }

                var lastModel = cfirstModel
                

                let firstbic = cfirstModel.score
//                print ("firstbic \(firstbic)")

                    var modelPeaks = [Model]()
                
                let rstart = DispatchTime.now()

                for rs in 0...Int(runstarts)-1 {
                    
                    if(self.breakloop){
                        break
                    }
                    
                
                    var firstrun = true
                    var lastbic = NSNumber.init(value: 0.0)
                    var curbic = NSNumber.init(value: 0.0)
                    
                    for hc in 0...Int(hillchains)-1 {
                        
                        if(self.breakloop){
                            break
                        }
                        
                        if(firstrun == true){
                            
                            firstrun = false
                            lastbic = firstbic
                            
                        }
                        else {
    
                            
                            
                            let curModel = self.randomChildModel(lastModel: lastModel, allTraits: allTraits, initusedTraitNames: usedTraitNames, thisMOC: nil)
                            var discardModel = curModel
                            

                            
                            
                            var cycleChk = false
                            let newNodes = curModel.bnnode
                            for newNode in newNodes {
                                let curNode = newNode as! BNNode
                                cycleChk = curNode.DFTcyclechk([curNode])
                            }

                            
                            var curname = cfirstModel.name + "-"
                            curname =  curname + String(rs)
                            curname = curname + "-"
                            curname = curname + String(hc)
                            curModel.name = curname

                            if cycleChk == false { //If the new model is a cycle, ignore it
                            
                                let msrun = self.metalCalc(curModel : curModel, fake : false, verbose: false)
                                if (msrun == true) {
                                    curbic = curModel.score
//                                    print("\(lastbic) \(curbic)")
                                    curModel.setValue(curbic, forKey: "score")
                                    if curbic.floatValue > lastbic.floatValue {
                                        discardModel = lastModel
//                                        print ("keeping: \(curModel.name) and discarding \(discardModel.name)")
                                        lastModel = curModel
                                        lastbic = curbic
    //                                    if discardModel != cfirstModel {
    //                                        cmoc.delete(discardModel)
    //                                    }
                                        
                                        usedTraitNames = Set<String>()
                                        let lastNodes = lastModel.bnnode.allObjects as! [BNNode]
                                        for lastNode in lastNodes {
                                            usedTraitNames.insert(lastNode.name)
                                        }
                                        

                                        
                                        
                                    }
                                    else {
//                                        print ("discarding: \(curModel.name)")
    //                                    cmoc.delete(curModel)
                                        discardModel = curModel
                                        
                                    }
                                }
                                else {
//                                    print ("error: \(curModel.name)")
    //                                cmoc.delete(curModel)
                                }
                            }
                            else {
//                                print ("\(curModel.name) is cyclic. Ignoring")
                            }
                            
                            
                            //Delete the discarded model unless it is the first model
                            if discardModel != cfirstModel {
                                for theEntry in theEntries.allObjects as! [Entry] {
                                    theEntry.removeAModelObject(discardModel)
                                }
                            }
                            
                            
                        }
                        DispatchQueue.main.async {
                            self.hProgInd.increment(by: 1.0)
                            let rstep = DispatchTime.now()
                            let rRunTime = Double(rstep.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
                            hcount += 1
                            let howLongPer = rRunTime / Double(hcount)
                            let estTimeTotal = allHillRuns * howLongPer
                            self.timeLabel.stringValue = self.secondsConvert(secs: rRunTime, retUnit: false)
                            self.timeMaxLabel.stringValue = self.secondsConvert(secs: estTimeTotal, retUnit: true)
                        }
                        
                        
                    }
                    
                    if lastModel != cfirstModel {
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
                            
                            if thisPeak != cfirstModel {
                                for theEntry in theEntries.allObjects as! [Entry] {
                                    theEntry.removeAModelObject(thisPeak)
                                }
                            }
                            
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
                        finalModel = peakModel
                    }
                    
                }
                
                else {
                    finalModel = firstModel
                }
                

                
                
                self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
                
                DispatchQueue.main.sync {
                    
                    if self.breakloop == true {
                        firstModel.score = NSNumber.init(floatLiteral: -Double.infinity)
                        let cancelAlert = NSAlert()
                        cancelAlert.alertStyle = .informational
                        cancelAlert.messageText = "Run cancelled."
                        cancelAlert.addButton(withTitle: "OK")
                        _ = cancelAlert.runModal()
                        self.breakloop = false
                    }
                    
                    else {
                        let scoreAlert = NSAlert()
                        scoreAlert.alertStyle = .informational
                        scoreAlert.messageText = "Highest scoring model: \(finalModel.name) with score \(finalModel.score)"
                        if finalModel != firstModel {
                            scoreAlert.informativeText = "Plexus will select the new model."

                            self.moc.insert(finalModel)
                            for insNode in finalModel.bnnode {
                                let thisinsNode : BNNode = insNode as! BNNode

                                self.moc.insert(thisinsNode)
                                //Select the new winning node int he tree
                                for thisDown in thisinsNode.downNodes(self){

                                    if let thisDI = thisinsNode.getDownInterBetween(downNode: thisDown){

                                        self.moc.insert(thisDI)
                                    }

                                }

                            }
                            
                            
                            let firstEntries = firstModel.entry

                            for theEntry in firstEntries.allObjects as! [Entry] {
//                                print("entry name \(theEntry.name) entry moc: \(theEntry.managedObjectContext)    model moc : \(finalModel.managedObjectContext)")
                                theEntry.addAModelObject(finalModel)
                                finalModel.addAnEntryObject(theEntry)
                            }
                            
                            
//                            for theEntry in firstEntries.allObjects as! [Entry] {
//                                print("entry name \(theEntry.name) entry moc: \(theEntry.managedObjectContext)    model moc : \(finalModel.managedObjectContext)  model entry count: \(finalModel.entry.count)")
//
//                            }
                            
//                            print("check check")

                            
                            do {
                                try self.moc.save()
                            } catch let error as NSError {
                                print(error)
                                fatalError("ERROR saving to primary MOC.")
                            }
                            
                            firstModel.addAChildObject(finalModel)
                            let finalIndexPath = self.mainSplitViewController.modelTreeController.indexPathOfModel(model:finalModel)
                            self.mainSplitViewController.modelTreeController.setSelectionIndexPath(finalIndexPath! as IndexPath)
 
                        
                        
                        }
                        else {
                         scoreAlert.informativeText = "No model scored higher than the original."
                        }
                        self.mainSplitViewController.modelDetailViewController?.calcInProgress = false
                        scoreAlert.addButton(withTitle: "OK")
                        _ = scoreAlert.runModal()
                    }
                }
                
            }
            catch {
                fatalError("Error in calcQueue.")
            }
 
        } // end calcQueue.async dispatch
        
    }
    
  
    
    
    
    func metalCalc(curModel:Model, fake: Bool, verbose:Bool) -> Bool {
//                let start = DispatchTime.now()
//                print ("\n\n**********START")
        
        let defaults = UserDefaults.standard
        
        let calcSpeed = defaults.integer(forKey: "calcSpeed")

        let teWidth = pipelineState.threadExecutionWidth
        let mTTPT = pipelineState.maxTotalThreadsPerThreadgroup
        

        var maxWSS = 0
        if #available(OSX 10.12, *) {
            maxWSS = Int(device.recommendedMaxWorkingSetSize)
            
        }

        

        let theEntries = curModel.entry
        
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
            let theUpNodes = node.upNodes(self)
            if(theUpNodes.count > maxInfSize) {
                maxInfSize = theUpNodes.count
            }
        }
        
        //So that we don't work with completely unlinked graphs
        if(maxInfSize<1){ //FIXME
            return false
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
            let theUpNodes = node.upNodes(self)
            for thisUpNode in theUpNodes  {
                thisinf.append(Int32(nodesForCalc.index(of: thisUpNode)!))
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
            let theCPT = node.getCPTArray(self, mocChanged: moc.hasChanges, fake : fake)
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
        
        //Buffer 11: BNStates output array num nodes * ntWidth
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
        
//            var end = DispatchTime.now()
//            var cptRunTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
//            print ("**********END Buffer creation  \(cptRunTime) seconds.")
        
        //RUN LOOP HERE
        var rc = 0
        var resc = 0
        var pesc = 0
        var besc = 0
//        let start = NSDate()
        while (rc<runstot){
            

            let commandBuffer = self.commandQueue.makeCommandBuffer()
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            commandEncoder.setComputePipelineState(self.pipelineState)
            
//let randomArray = Array(0..<30).map { _ in generateUniqueInt() }
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
            
            
//            end = DispatchTime.now()
//            cptRunTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
//            print ("**********END a kernel run  \(cptRunTime) seconds.")
            
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
            if self.breakloop == true {
                return false
            }
            
            DispatchQueue.main.async {
                self.progInd.increment(by: Double(ntWidth))
                self.curLabel.stringValue = String(resc)
            }
            
//            end = DispatchTime.now()
//            cptRunTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
//            print ("**********END rc loop  \(cptRunTime) seconds.")
            // End rc loop
        }
        
//        if verbose == true {
//            print("Time to run: \(NSDate().timeIntervalSince(start as Date)) seconds.")
//        }
        
        var bins = Int(pow(Float(curModel.runstot), 0.5))
        
        if(bins < 100) {
            bins = 100
        }
        
        let binQuotient = 1.0/Float(bins)
        
        var fi = 0
        for priorresult in priorresults {
            let inNode : BNNode = nodesForCalc[fi]
            
            inNode.priorArray = priorresult
            
            
    
            fi = fi + 1
            
        }
        
        
        fi = 0
        for bnstateoutresult in bnstatesoutresults {
            let inNode : BNNode = nodesForCalc[fi]
            inNode.finalStates = bnstateoutresult
            fi += 1
        }
        
        

        
        fi = 0
        for result in results {

            var postCount = [Int](repeating: 0, count: bins)
            let inNode : BNNode = nodesForCalc[fi]

            let theUpNodes = inNode.upNodes(self)
            //If a dependent node
            if theUpNodes.count > 0 {
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
                
                inNode.postCount = postCount
                
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
                
                
                inNode.postArray = result
                inNode.cptFreezeArray = inNode.cptArray
                
            
            }
            
            else {


                inNode.postArray = [Float](repeating: 0.0, count: result.count)
                inNode.postCount = postCount
                inNode.cptFreezeArray = inNode.cptArray
            }
            
            fi = fi + 1
            

                
        }
        
        let score = self.calcMarginalLikelihood(curModel: curModel, inEntries: theEntries, nodesForCalc: nodesForCalc, infnet : sInfNet, results : results, priorresults : priorresults, bnstatesoutresults : bnstatesoutresults)
        curModel.setValue(score, forKey: "score")
        
            DispatchQueue.main.async {
                curModel.complete = true
                
                
        }
        self.performSelector(onMainThread: #selector(PlexusMainWindowController.betweenRuns), with: nil, waitUntilDone: true)
//        if verbose == true {
//            print("Full run: \(NSDate().timeIntervalSince(start as Date)) seconds.")
//        }
        
//        var end = DispatchTime.now()
//        var cptRunTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000
//        print ("**********END RUN  \(cptRunTime) seconds.")
        
        return true
        

    }
    
    
  @IBAction func genRandData(_ x:NSToolbarItem){
    
    let devices = devicesController?.selectedObjects as! [MTLDevice]
    device = devices[0]
    kernelFunction  = defaultLibrary?.makeFunction(name: "bngibbs")
    do {
        pipelineState = try device.makeComputePipelineState(function: kernelFunction!)
    }
    catch {
        fatalError("Cannot set up Metal")
        
    }
    
    mainSplitViewController.modelDetailViewController?.calcInProgress = true
    self.breakloop = false
    
    self.progSheet = self.progSetup(self)
    self.window!.beginSheet(self.progSheet, completionHandler: nil)
    self.progSheet.makeKeyAndOrderFront(self)
    
    
    let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
    let curModel : Model = curModels[0]
    
    let newModel = curModel.copySelf(moc: self.moc, withEntries: false)
    var simname = curModel.name
    simname += "-randomdata"
    newModel.name = simname
    
    
    let allNodes = newModel.bnnode.allObjects as! [BNNode]
    

    var nodecounter = 1
    //Prepare the independnt nodes
    for thisNode in allNodes {
        thisNode.name = String(nodecounter)
        thisNode.value = "yes"
        let upNodes = thisNode.upNodes(self)
        if upNodes.count < 1 { //Independent nodes need to
            
            thisNode.priorDistType =  NSNumber.init(integerLiteral: Int.random(in: 0 ... 4))
            thisNode.priorV1 = NSNumber.init(floatLiteral: Double.random(in: 0.0 ... 1.0))
            thisNode.priorV2 = NSNumber.init(floatLiteral: Double.random(in: 0.0 ... 1.0))
            
        }
        else {
            for upNode in upNodes {
            
                if let thisInter = thisNode.getUpInterBetween(upNode: upNode){
                    thisInter.ifthen = NSNumber.init(floatLiteral: Double.random(in: 0.0 ... 1.0))
                }
            }
        }
        
        nodecounter += 1
    }
    
    
    let okok = self.metalCalc(curModel: newModel, fake : true, verbose: true)
    
    
    if okok == true {
        
        newModel.setValue(NSNumber.init(floatLiteral: -Double.infinity), forKey: "score")
        
        
        for thisNode in allNodes {
                let blankCount = [Int]()
                let blankArray = [Float]()
                thisNode.postCount = blankCount
                thisNode.postArray = blankArray
                thisNode.priorCount = blankCount
                thisNode.priorArray = blankArray
        }
        
        
        for i in 0..<curModel.runstot.intValue{
            let newEntry : Entry = Entry(entity: NSEntityDescription.entity(forEntityName: "Entry", in: self.moc)!, insertInto: self.moc)
            newEntry.name = String(i)

            for thisNode in allNodes {

                let newTrait : Trait = Trait(entity: NSEntityDescription.entity(forEntityName: "Trait", in: self.moc)!, insertInto: self.moc)
                newTrait.name = thisNode.name
                let final = thisNode.finalStates

                if i < final.count{
                    if final[i] >= 1.0 {
                        newTrait.value = "yes"
                    }
                    else {
                        newTrait.value = "no"
                    }
                }
                else {
                    fatalError("Error in genRand. Either there are no finalStates for \(thisNode.name) or \(i) is larger than \(thisNode.finalStates.count).")
                }
                newEntry.addATraitObject(newTrait)
                newTrait.entry = newEntry
            }
            
            newModel.addAnEntryObject(newEntry)
            newEntry.addAModelObject(newModel)
            
            self.progInd.increment(by: 1)
            self.curLabel.stringValue = String(i)
            
        }
        
        do {
            try self.moc.save()
        } catch let error as NSError {
            print(error)
            fatalError("ERROR saving to primary MOC.")
        }
        
        for thisNode in allNodes {
            _ = thisNode.CPT(fake: false)
        
        }
        do {
            try self.moc.save()
        } catch let error as NSError {
            print(error)
            fatalError("ERROR saving to primary MOC.")
        }

        
        curModel.addAChildObject(newModel)
        let newIndexPath = self.mainSplitViewController.modelTreeController.indexPathOfModel(model:newModel)
        self.mainSplitViewController.modelTreeController.setSelectionIndexPath(newIndexPath! as IndexPath)
    
    }
    
    self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
    self.mainSplitViewController.modelDetailViewController?.calcInProgress = false
    
    } //end genRandData
    

    
    @IBAction func lockToggle(_ x:NSToolbarItem){

        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        if(curModel.complete == true){
//           print ("locked")
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

        self.breakloop = false

        
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
                
                var allScopedTraits  = [Trait]()
                let theEntries = curModel.entry
                for thisEntry in theEntries {
                    let curEntry = thisEntry as! Entry
                    for thisTrait in curEntry.trait {
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
                
                for thisEntry in theEntries {
                    let entry = thisEntry as! Entry
                    outText += entry.name
                    outText += ","
                    
                    let tTraits = entry.trait
                    for headerTrait in distinctHeaderTraits {
                        let hKey = headerTrait as! String
                        
                        
                        
                        var traitString = [String]()
                        for tTrait in tTraits{
                            let tKey = (tTrait as AnyObject).value(forKey: "name") as! String
                            if hKey == tKey{
                                //outText += tTrait.valueForKey("value") as! String
                                //outText += "\t"
                                traitString.append((tTrait as AnyObject).value(forKey: "value") as! String)
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
                    var postArrays = [[Float]]()
                    
                    for node in self.mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode] {
                        self.mainSplitViewController.modelDetailViewController?.nodesController.setSelectionIndex(i)
                        
                        outText += node.name
                        outText += "-PriorType,"
                        
                        outText += node.name
                        outText += "-PriorV1,"
                        
                        outText += node.name
                        outText += "-PriorV2,"
                        


                        
                        outText += node.name
                        outText += "-PostCount,"
                        
                         let postCount = node.postCount
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
                        
                        outText += node.name
                        outText += "-PostBins,"
                        
                        
                        outText += node.name
                        outText += "-PostDist,"
                        let postArray = node.postArray
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
                        let nodePDFFileName = baseFile! + "-" + node.name + ".pdf"
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
                        titleStyle.fontName = "SFProDisplay-Bold"
                        titleStyle.fontSize = 18.0
                        titleStyle.color = CPTColor.black()
                        graph?.titleTextStyle = titleStyle
                        graph?.title = node.name
                        
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
    
  
    func calcMarginalLikelihood(curModel:Model, inEntries: NSSet, nodesForCalc:[BNNode], infnet:[[Int32]], results : [[Float]], priorresults : [[Float]], bnstatesoutresults : [[Float]]) -> Float {
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        let moc = appDelegate.persistentContainer.viewContext
        
        var subsamp = curModel.runsper as! Int
        if subsamp < 1000  {
            subsamp = 1000
        }
        if subsamp > curModel.runstot as! Int {
            subsamp = curModel.runstot as! Int
        }
        // Get the yes-no's within the scope of the data

        let theEntries = inEntries
        
        var dataratios = [Float]()
        var matches = [Float]()
        var tots = [Float]()
        
        for calcNode in nodesForCalc {

            let calcValue = calcNode.value
            
            var theTraits = [Trait]()
            let predicate = NSPredicate(format: "entry IN %@ && name == %@", theEntries, calcNode.name)
            let request = NSFetchRequest<Trait>(entityName: "Trait")
            request.predicate = predicate
            do {
                theTraits = try moc.fetch(request)
            } catch let error as NSError {
                print (error)
                return -999
            }
            
//            print ("\(calcNode.name)  \(theTraits.count)")
            
            var mTraits = [Trait]()
            
            if calcNode.numericData == true {
                let calcNumVal = Double(calcValue)
                let tol = calcNode.tolerance as! Double
                let lowT = calcNumVal! * (1.0 - (tol/2.0))
                let highT = calcNumVal! * (1.0 + (tol/2.0))
                
                for chkTrait in theTraits {
                    if ((Double(chkTrait.value)!) < highT || (Double(chkTrait.value)!) > lowT) {
                        mTraits.append(chkTrait)
                    }
                }
                
            }
            else {
                let mpredicate = NSPredicate(format: "entry IN %@ && name == %@ && value == %@", theEntries, calcNode.name, calcValue)
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
        
        for _ in nodesForCalc {
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
        


        //Pick index where likelihood of the posterior given the data is the highest
        var maxlike = Float(0.0)
        var maxpos = -1
        var firsttime = true
        for s in 0...(postlength-1) {
            var likes = [Float]()
            for r in 0...(nodesForCalc.count-1){
//                print(nodesForCalc[r].node.name)
                if(tots[r]>0) { // to avoid hidden or data-free nodes in likelihood calc
//                    print(posts[r][s])
//                    print(matches[r])
//                    print(1-(posts[r][s]))
//                    print(tots[r]-matches[r])
//                    print(pow(posts[r][s], matches[r]))
//                    let logmatch = matches[r] * log(posts[r][s]) //log of m^k  = k log m
//                                    print ("logmatch \(logmatch)")
//                    print(pow(1-(posts[r][s]), (tots[r]-matches[r])))
//                    let lognomatch = (tots[r]-matches[r]) * log(1-(posts[r][s])) //log of m^k  = k log m
//
//                    print ("lognomatch \(lognomatch)")
//                    let logsum = logmatch + lognomatch //log M*N = log M + log N
//                    print ("logsum \(logsum)")

                    //This is likelihood of posterior given the data
            
                    
                    likes.append((matches[r] * log(posts[r][s])) + ((tots[r]-matches[r]) * log(1-(posts[r][s]))))//log of m^k  = k log m
                    
                    

                    
                }
                
            }
            

                let loglikelihood = likes.reduce(1, +) //This is likelihood of posterior given the data

                if firsttime == true {
                    maxlike = loglikelihood
                    maxpos = s
                    firsttime = false
                }
                else{
                    if (loglikelihood > maxlike) {
                        maxlike = loglikelihood
                        maxpos = s
                    }
                }
            
        }
        
        
//        print("\n maxpos \(maxpos)\n" )
//        print("Posterior terms:")
        var postvals = [Float]()
        for r in 0...(nodesForCalc.count-1){
            postvals.append(posts[r][maxpos])
//            print(posts[r][maxpos])
        }
        let postterm = (postvals.reduce(1, *)) //This is the posterior
//        print("π(ϴ|y) \(postterm)")
        
        
        //Prior
        var priorProds = [Float]()
        var binsum = Float(0.0)
        var binx = 0
        for r in 0...(nodesForCalc.count-1){
//            print("Node: \(nodesForCalc[r].name)")
            let thisinfnet = infnet[r]
            let upNodes = nodesForCalc[r].upNodes(self)
            if upNodes.count > 0 { //dependent. Use the conditional probability of this node given the states of the nodes at maxpos. So say T, T, T is binary 111 or decimal 7
                let cptarray = nodesForCalc[r].cptArray //FIXME easier to pull this at top of funciton


                
                binsum = 0.0
                binx = 0
                for thisinf in thisinfnet{ //
                    if(thisinf<0){
                        break
                    }

                    let tii = Int(thisinf) //FIXME convert this earlier
//                    print ("influenced by \(tii) whose state is \(bnstatesoutresults[tii][maxpos])  * \(pow(2, Float(binx)) )")
                    binsum = binsum + bnstatesoutresults[tii][maxpos] * pow(2, Float(binx)) //add (final state of this node's  * 2 ^ this influencer's position in list of influencers
                    binx = binx + 1
                }
                let binfinal = Int(binsum) //shoudl always be exact float to int

//                print ("node: \(nodesForCalc[r].name) binfinal: \(binfinal) cptarray size: \(cptarray.count) entry \(cptarray[binfinal])")
                priorProds.append(cptarray[binfinal]) //FIXME crashing here

            }
            else { //independent
                priorProds.append(priors[r][maxpos])
            }
        }

//        print(priorProds)
        let priorterm = (priorProds.reduce(1, *)) //This is the prior term
//        print("π(ϴ) \(priorterm)")

        
        var likes = [Float]()
        for r in 0...(nodesForCalc.count-1){
//            print ("\(nodesForCalc[r].name)")
            
            if(tots[r]>0) { // to avoid hidden or data-free nodes in likelihood calc
//                print("\nname: \(nodesForCalc[r].name)")
//                print("prior: \(priorProds[r])")
//                print("matches: \(matches[r])")
//                print("1-prior: \(1-(priorProds[r]))")
//                print("nomatches: \(tots[r]-matches[r])")
//                print("prior^matches \(pow(priorProds[r], matches[r]))") //FIXME zero becasue e.g. 0.5 ^ 290 comes back as a zero
//                let logmatch = matches[r] * log(priorProds[r]) //log of m^k  = k log m
//                print ("logmatch \(logmatch)")
//
//                print((pow(1-(priorProds[r]), (tots[r]-matches[r]))))
//                let lognomatch = (tots[r]-matches[r]) * log(1-(priorProds[r])) //log of m^k  = k log m
//
//                print ("lognomatch \(lognomatch)")
//
//                let logsum = logmatch + lognomatch //log M*N = log M + log N
//
//                print ("logsum \(logsum)")
//                print((matches[r] * log(priorProds[r])) + ((tots[r]-matches[r]) * log(1-(priorProds[r]))))
//                likes.append(log(pow(priorProds[r], matches[r]) * pow(1-(priorProds[r]), (tots[r]-matches[r])))) //This is likelihood of data given the Priors
//                print("SCORE: \((matches[r] * log(priorProds[r])) + ((tots[r]-matches[r]) * log(1-(priorProds[r]))))")
                likes.append((matches[r] * log(priorProds[r])) + ((tots[r]-matches[r]) * log(1-(priorProds[r]))))
                

            }
            
        }

        let likelihood = likes.reduce(1, +) //This is the likelihood of the data given the priors
//        print("f(y|ϴ) \(likelihood)")
        
        
//        print (log(priorterm) + likelihood - log(postterm))
//        print ("score: \(log(priorterm) + likelihood - log(postterm))")
        return log(priorterm) + likelihood - log(postterm)
        
    }
    

    
    
//    func contextDidChange(_ notification: Notification) {
//        let savedContext = notification.object as! NSManagedObjectContext
//        if(savedContext == self.moc) { // ignore change notifications for the main MOC
//            return
//        }
//
//        print(savedContext)
//
//
//        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
//            print(insertedObjects)
//        }
////                if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
////                    print(updatedObjects)
////                }
////                if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletedObjects.isEmpty {
////                    print(deletedObjects)
////                }
////                if let refreshedObjects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>, !refreshedObjects.isEmpty {
////                    print(refreshedObjects)
////                }
////                if let invalidatedObjects = notification.userInfo?[NSInvalidatedObjectsKey] as? Set<NSManagedObject>, !invalidatedObjects.isEmpty {
////                    print(invalidatedObjects)
////                }
////                if let areInvalidatedAllObjects = notification.userInfo?[NSInvalidatedAllObjectsKey] as? Bool {
////                    print(areInvalidatedAllObjects)
////                }
//
//        DispatchQueue.main.sync {
//            self.moc.mergeChanges(fromContextDidSave: notification)
//        }
//
//
//    }
//
//
//    func contextWillSave(_ notification: Notification) {
//        let savedContext = notification.object as! NSManagedObjectContext
//        if(savedContext == self.moc) { // ignore change notifications for the main MOC
//            return
//        }
//
//        print(savedContext)
//
//
//        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
//            print(insertedObjects)
//        }
////        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
////            print(updatedObjects)
////        }
////        if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletedObjects.isEmpty {
////            print(deletedObjects)
////        }
////        if let refreshedObjects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>, !refreshedObjects.isEmpty {
////            print(refreshedObjects)
////        }
////        if let invalidatedObjects = notification.userInfo?[NSInvalidatedObjectsKey] as? Set<NSManagedObject>, !invalidatedObjects.isEmpty {
////            print(invalidatedObjects)
////        }
////        if let areInvalidatedAllObjects = notification.userInfo?[NSInvalidatedAllObjectsKey] as? Bool {
////            print(areInvalidatedAllObjects)
////        }
//
//        DispatchQueue.main.sync {
//            self.moc.mergeChanges(fromContextDidSave: notification)
//        }
//
//
//    }
    
    
    func contextDidSave(_ notification: Notification) {
        let savedContext = notification.object as! NSManagedObjectContext
        if(savedContext == self.moc) { // ignore change notifications for the main MOC
            return
        }
        
        
//        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
//            print(insertedObjects)
//        }
//        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
//            print(updatedObjects)
//        }
//        if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletedObjects.isEmpty {
//            print(deletedObjects)
//        }
//        if let refreshedObjects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>, !refreshedObjects.isEmpty {
//            print(refreshedObjects)
//        }
//        if let invalidatedObjects = notification.userInfo?[NSInvalidatedObjectsKey] as? Set<NSManagedObject>, !invalidatedObjects.isEmpty {
//            print(invalidatedObjects)
//        }
//        if let areInvalidatedAllObjects = notification.userInfo?[NSInvalidatedAllObjectsKey] as? Bool {
//            print(areInvalidatedAllObjects)
//        }
        
        DispatchQueue.main.sync {
            self.moc.mergeChanges(fromContextDidSave: notification)
        }
        

    }
}
