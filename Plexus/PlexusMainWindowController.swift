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
 
                        

                        
                    }
                
                self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
                
                
                
                
            }
            
            

            
            
            
        }
        

        
    }

    func cancelProg(_ sender: AnyObject){

        self.breakloop = true
    }
    
    @IBAction func calcMetal(_ x:NSToolbarItem){
        
        
        let defaults = UserDefaults.standard

        
        let calcSpeed = defaults.integer(forKey: "calcSpeed")
        
        let mocChange = mainSplitViewController.modelDetailViewController?.mocChange
        mainSplitViewController.modelDetailViewController?.calcInProgress = true
        
        let kernelFunction: MTLFunction? = defaultLibrary?.makeFunction(name: "bngibbs")
        do {
            pipelineState = try device?.makeComputePipelineState(function: kernelFunction!)
        }
        catch {
            fatalError("Cannot set up Metal")
        }

        
        let teWidth = pipelineState.threadExecutionWidth
        let mTTPT = pipelineState.maxTotalThreadsPerThreadgroup
        print ("Thread execution width: \(teWidth)")
        print ("Max threads per group: \(mTTPT)")
        var maxWSS = 0
        if #available(OSX 10.12, *) {
            maxWSS = Int(device.recommendedMaxWorkingSetSize)

        }
        print ("Max working set size: \(maxWSS) bytes")



        let nodesForCalc : [BNNode] = mainSplitViewController.modelDetailViewController?.nodesController.arrangedObjects as! [BNNode]
        let curModels : [Model] = mainSplitViewController.modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        let nc = nodesForCalc.count

        let runstot = curModel.runstot as Int
        var ntWidth = (mTTPT/teWidth)-1
        if calcSpeed == 0 {
            ntWidth = Int(Double(ntWidth) * 0.5)
        }
        else if calcSpeed == 1 {
            ntWidth = Int(Double(ntWidth) * 0.75)
        }
        print ("Number of threadgroups: \(ntWidth)")
        let threadsPerThreadgroup : MTLSize = MTLSizeMake(teWidth, 1, 1)
        let numThreadgroups = MTLSize(width: ntWidth, height: 1, depth: 1)

        
        
        self.progSheet = self.progSetup(self)
        self.maxLabel.stringValue = String(describing: runstot)
        self.window!.beginSheet(self.progSheet, completionHandler: nil)
        self.progInd.doubleValue = 0
        self.progInd.maxValue =  Double(runstot)
        self.progSheet.makeKeyAndOrderFront(self)
        self.progInd.isIndeterminate = true
        self.progInd.startAnimation(self)
        self.workLabel.stringValue = "Preparing..."
        
        DispatchQueue.global().async {
        

            
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
                return //so that we don't work with completely unlinked graphs
            }
            
            //Maximum CPT size for a node
            let maxCPTSize = Int(pow(2.0, Double(maxInfSize)))
            
        

            
            //Buffer 2: Integer Parameters
            var intparams = [UInt32]()
            intparams.append(curModel.runsper as UInt32) //0
            intparams.append(curModel.burnins as UInt32) //1
            intparams.append(UInt32(nodesForCalc.count)) //2
            intparams.append(UInt32(maxInfSize)) //3
            intparams.append(UInt32(maxCPTSize)) //4


            //Buffer 3: Prior Distribution Type
            var priordisttypes = [UInt32]()
            for node in nodesForCalc {
                priordisttypes.append(UInt32(node.priorDistType))
            }
            let priordisttypesbuffer = self.device.makeBuffer(bytes: &priordisttypes, length: priordisttypes.count*MemoryLayout<UInt32>.size, options: MTLResourceOptions.cpuCacheModeWriteCombined)
            threadMemSize += priordisttypes.count*MemoryLayout<UInt32>.size

            
            //Buffer 4: PriorV1
            var priorV1s = [Float]()
            for node in nodesForCalc {
                priorV1s.append(Float(node.priorV1))
            }
            let priorV1sbuffer = self.device.makeBuffer(bytes: &priorV1s, length: priorV1s.count*MemoryLayout<Float>.size, options: MTLResourceOptions.cpuCacheModeWriteCombined)
            threadMemSize += priorV1s.count*MemoryLayout<Float>.size

            
            
            //Buffer 5: PriorV2
            var priorV2s = [Float]()
            for node in nodesForCalc {
                priorV2s.append(Float(node.priorV2))
            }
            let priorV2sbuffer = self.device.makeBuffer(bytes: &priorV2s, length: priorV2s.count*MemoryLayout<Float>.size, options: MTLResourceOptions.cpuCacheModeWriteCombined)
            threadMemSize += priorV2s.count*MemoryLayout<Float>.size


            //Buffer 6: Infnet
    //        var maxCPTSize = 0
    //        var infnet = [UInt32]()
    //        for node in nodesForCalc {
    //            var thisinf = [UInt32](repeating: 0, count: nodesForCalc.count)
    //             let theInfluencedBy = node.infBy(self)
    //            if(theInfluencedBy.count > maxCPTSize) {
    //                maxCPTSize = theInfluencedBy.count
    //            }
    //            for thisinfby in theInfluencedBy  {
    //                let tib = thisinfby as! BNNode
    //                let loc = nodesForCalc.index(of: tib)!
    //                thisinf[loc] = 1
    //            }
    //            infnet = infnet + thisinf
    //            
    //        }
    //        print (infnet)
    //        let infnetbuffer = device.makeBuffer(bytes: &infnet, length: nodesForCalc.count*nodesForCalc.count*MemoryLayout<UInt32>.size, options: MTLResourceOptions.cpuCacheModeWriteCombined)
    //        commandEncoder.setBuffer(infnetbuffer, offset: 0, at: 6)
            

            
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
                
            }
            let infnetbuffer = self.device.makeBuffer(bytes: &infnet, length: nodesForCalc.count*maxInfSize*MemoryLayout<Int32>.size, options: MTLResourceOptions.cpuCacheModeWriteCombined)
            threadMemSize = nodesForCalc.count*maxInfSize*MemoryLayout<Int32>.size


            //Buffer 7: Cptnet
            var cptnet = [Float]()
            for node in nodesForCalc {
                let cptReady = self.mainSplitViewController.modelDetailViewController?.cptReady[node]!
                let theCPT = node.getCPTArray(self, mocChanged: mocChange!, cptReady: cptReady!)
                cptnet = cptnet + theCPT
                let leftOver = maxCPTSize-theCPT.count
                for _ in 0..<leftOver {
                    cptnet.append(-1.0)
                }
                
            }
            let cptnetbuffer = self.device.makeBuffer(bytes: &cptnet, length: nodesForCalc.count*maxCPTSize*MemoryLayout<Float>.size, options: MTLResourceOptions.cpuCacheModeWriteCombined)
            threadMemSize += nodesForCalc.count*maxCPTSize*MemoryLayout<Float>.size
            //Buffer 8: Shuffled Array
    //        var shufflenodes = [UInt32]()
    //        var shufflearray = [UInt32]()
    //        for i in 0..<nodesForCalc.count {
    //            shufflearray.append(UInt32(i))
    //        }
    //        for _ in 0..<runstot {
    //            shufflenodes += shufflearray
    //        }
    //        print (shufflenodes)
            let shufflebuffer = self.device.makeBuffer(length: ntWidth*nodesForCalc.count*MemoryLayout<UInt32>.size, options: MTLResourceOptions.storageModePrivate)
            threadMemSize += ntWidth*nodesForCalc.count*MemoryLayout<UInt32>.size

            
             //Buffer 9: BNStates array num notdes * ntWidth
            let bnstatesbuffer = self.device.makeBuffer(length: ntWidth*nodesForCalc.count*MemoryLayout<Float>.size, options: MTLResourceOptions.storageModePrivate)
            threadMemSize += ntWidth*nodesForCalc.count*MemoryLayout<Float>.size
            

            
            //Buffer 10: postPrior
            
            //Work out maximum number of postPriors to assign
            var maxPPmem = 10000 //Default of max WSS not accessible
            if maxWSS > 0 {
                let maxtest = Int((Double(maxWSS) / Double(nodesForCalc.count)) * 0.01) - threadMemSize
                if maxtest > maxPPmem {
                    maxPPmem = maxtest
                }
            }
            
            
            var postPriorSetup = [[Float]]()
            var maxPP = 0
            
            for node in nodesForCalc {

                if let postData = node.value(forKey: "priorArray"){
                    let priorArray = NSKeyedUnarchiver.unarchiveObject(with: postData as! Data) as! [Float]
                    let shuffledPriorArray = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: priorArray)
                    let firstTT = shuffledPriorArray.prefix(maxPPmem)
                    if firstTT.count > 1 {
                        postPriorSetup.append(Array(firstTT) as! [Float])
                        if(firstTT.count > maxPP){
                            maxPP = firstTT.count
                        }
                    }
                    else {
                        postPriorSetup.append([Float(0.0)])
                        if(1 > maxPP){
                            maxPP = 1
                        }
                    }
                }
                else {
                    postPriorSetup.append([Float(0.0)])
                    if(1 > maxPP){
                        maxPP = 1
                    }
                }

            }
//           Pad each out to maxPP if necessary
            var postPriors = [Float]()
            for pp in postPriorSetup{
                postPriors += pp
                for _ in pp.count..<maxPP {
                    postPriors.append(-1.0)
                }
            }
            

            
            let postpriorbuffer = self.device.makeBuffer(bytes: &postPriors, length: nodesForCalc.count*maxPP*MemoryLayout<Float>.size, options: MTLResourceOptions.cpuCacheModeWriteCombined)
            threadMemSize += nodesForCalc.count*maxPP*MemoryLayout<Float>.size

            //Buffer 2: Integer Parameters Setting buffer here
            intparams.append(UInt32(maxPP)) //5
            let intparamsbuffer = self.device.makeBuffer(bytes: &intparams, length: intparams.count*MemoryLayout<UInt32>.size, options: resourceOptions)
            threadMemSize += intparams.count*MemoryLayout<UInt32>.size
            

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
            


            //RUN LOOP HERE
            var rc = 0
            var resc = 0
            let start = NSDate()
            while (rc<runstot){
                
                
                let commandBuffer = self.commandQueue.makeCommandBuffer()
                let commandEncoder = commandBuffer.makeComputeCommandEncoder()
                commandEncoder.setComputePipelineState(self.pipelineState)
            
                //Buffer 0: RNG seeds
                var seeds = (0..<ntWidth).map{_ in arc4random()}
                let seedsbuffer = self.device.makeBuffer(bytes: &seeds, length: seeds.count*MemoryLayout<UInt32>.size, options: MTLResourceOptions.cpuCacheModeWriteCombined)
                commandEncoder.setBuffer(seedsbuffer, offset: 0, at: 0)
                
                //Buffer 1: BN Results
                var bnresults = [Float](repeating: -1.0, count: ntWidth*nodesForCalc.count)
                let bnresultsbuffer = self.device.makeBuffer(bytes: &bnresults, length: bnresults.count*MemoryLayout<Float>.size, options: resourceOptions)
                
                commandEncoder.setBuffer(bnresultsbuffer, offset: 0, at: 1)
                commandEncoder.setBuffer(intparamsbuffer, offset: 0, at: 2)
                commandEncoder.setBuffer(priordisttypesbuffer, offset: 0, at: 3)
                commandEncoder.setBuffer(priorV1sbuffer, offset: 0, at: 4)
                commandEncoder.setBuffer(priorV2sbuffer, offset: 0, at: 5)
                commandEncoder.setBuffer(infnetbuffer, offset: 0, at: 6)
                commandEncoder.setBuffer(cptnetbuffer, offset: 0, at: 7)
                commandEncoder.setBuffer(shufflebuffer, offset: 0, at: 8)
                commandEncoder.setBuffer(bnstatesbuffer, offset: 0, at: 9)
                commandEncoder.setBuffer(postpriorbuffer, offset: 0, at: 10)
                
                

                
                commandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
                
                commandEncoder.endEncoding()
                commandBuffer.enqueue()
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()


                let bnresultsdata = NSData(bytesNoCopy: bnresultsbuffer.contents(), length: bnresults.count*MemoryLayout<Float>.size, freeWhenDone: false)
                bnresultsdata.getBytes(&bnresults, length:bnresults.count*MemoryLayout<Float>.size)
                

                var ri = 0
                for to in bnresults {
                    if resc >= runstot {
                        break
                    }
                    results[ri].append(to)
                    ri = ri + 1
                    
                    if ri >= nc {
                        ri = 0
                        resc = resc + 1
                    }
                }
                


                
                rc = rc + ntWidth

                DispatchQueue.main.async {
                    self.progInd.increment(by: Double(ntWidth))
                    self.curLabel.stringValue = String(resc)
                }
                

            }
            
            print("Time to run: \(NSDate().timeIntervalSince(start as Date)) seconds.")
            

            
            var bins = Int(pow(Float(curModel.runstot), 0.5))
            
            if(bins < 100) {
                bins = 100
            }
            
            let binQuotient = 1.0/Float(bins)
            
            bins = bins + 1 //one more bin for anything that is a 1.0
            
            var fi = 0
            for result in results {

                
                var postCount = [Int](repeating: 0, count: bins)
                
                let inNode : BNNode = nodesForCalc[fi]
                
                var gi = 0
                var flinetot : Float = 0.0
                var flinecount : Float = 0.0
                for gNode : Float in result {
                    
                    
                    if(gNode == gNode && gNode >= 0.0 && gNode <= 1.0) {//fails if nan
                        
                        let x = (Int)(floor(gNode/binQuotient))
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
                
                
                
                
                fi = fi + 1

            }

            self.performSelector(onMainThread: #selector(PlexusMainWindowController.endProgInd), with: nil, waitUntilDone: true)
            
            DispatchQueue.main.async {
                curModel.complete = true
                self.mainSplitViewController.modelDetailViewController?.calcInProgress = false
                
                
                
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
                                outText += pTypes[node.priorDistType as Int]
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

                        
                        
                        /*

                        
                        

                        
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
                        
                        graph?.title = ""
                        
                        i += 1
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
    
    func endProgInd(){

        if(self.progSheet != nil){
            self.progSheet.orderOut(self)
            self.window!.endSheet(self.progSheet)
        }
        mainSplitViewController.modelDetailViewController?.setGraphParams()
        mainSplitViewController.modelDetailViewController?.reloadData()
        
    }
 


}
