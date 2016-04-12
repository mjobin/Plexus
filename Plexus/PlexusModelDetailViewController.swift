//
//  PlexusModelDetailViewController.swift
//  Plexus
//
//  Created by matt on 6/9/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa
import SpriteKit

class PlexusModelDetailViewController: NSViewController, NSTableViewDelegate, CPTScatterPlotDataSource, CPTScatterPlotDelegate {
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    @IBOutlet dynamic var nodesController : NSArrayController!
    @IBOutlet dynamic var childNodesController : NSArrayController!
    @IBOutlet dynamic var parentNodesController : NSArrayController!
    
    
    //Nodes View
    @IBOutlet weak var nodeVisView: NSVisualEffectView!
    @IBOutlet weak var skView: PlexusBNSKView!
    var scene: PlexusBNScene!
    
    
    //Single Node View
    @IBOutlet weak var singleNodeVisView: NSVisualEffectView!
    @IBOutlet var graphView : CPTGraphHostingView!
    
    @IBOutlet weak var priorControlsView : NSView!
    @IBOutlet weak var cptControlsView : NSView!
    
    
    @IBOutlet var priorTypePopup : NSPopUpButton!
    @IBOutlet var priorV1Slider : NSSlider!
    @IBOutlet var priorV1Field : NSTextField!
    @IBOutlet var priorV2Slider : NSSlider!
    @IBOutlet var priorV2Field : NSTextField!
    
    @IBOutlet var scopeLabel : NSTextField!
    @IBOutlet var scopePopup : NSPopUpButton!
    @IBOutlet var numericButton : NSButton!
    @IBOutlet var numericField : NSTextField!
    @IBOutlet var dataLabel : NSTextField!
    @IBOutlet var dataPopup : NSPopUpButton!
    @IBOutlet var dataSubPopup : NSPopUpButton!
    
    var priorDist = 0
    var V1 = 0.1
    var V2 = 0.5
    var dataForChart = [NSNumber]()
    var priorDataForChart = [NSNumber]()
    
    var curNode : BNNode!
    var graph : CPTXYGraph!
    var priorPlot : CPTScatterPlot!
    
    @IBOutlet var childPredicate : NSPredicate!
        @IBOutlet weak var childTableView : NSTableView!
    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        

        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let  childPredicate = NSPredicate(format: "isParent = %i", 0)
        childNodesController.filterPredicate = childPredicate
        
        let  parentPredicate = NSPredicate(format: "isParent = %i", 1)
        parentNodesController.filterPredicate = parentPredicate
        

        
        nodeVisView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
        nodeVisView.material = NSVisualEffectMaterial.Dark
        nodeVisView.state = NSVisualEffectState.Active
        

        
        
        scene = PlexusBNScene(size: self.skView.bounds.size)
        scene.scaleMode = SKSceneScaleMode.ResizeFill
        self.skView!.presentScene(scene)
        
        
        //Single Node View
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlexusModelDetailViewController.mocDidChange(_:)), name: NSManagedObjectContextObjectsDidChangeNotification, object: moc)
        
        
        
        singleNodeVisView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
        singleNodeVisView.material = NSVisualEffectMaterial.Dark
        singleNodeVisView.state = NSVisualEffectState.Active
        
        
        
        
        graph = CPTXYGraph(frame:self.graphView.bounds)
        self.graphView.hostedGraph = graph
        
        
        let titleStyle = graph.titleTextStyle!.mutableCopy() as! CPTMutableTextStyle
        titleStyle.fontName = "SanFrancisco"
        titleStyle.fontSize = 18.0
        titleStyle.color = CPTColor.whiteColor()
        graph.titleTextStyle = titleStyle
        
        graph.title = ""
        
        graph.paddingTop = 10.0
        graph.paddingBottom = 10.0
        graph.paddingLeft = 10.0
        graph.paddingRight = 10.0
        
        let plotSpace : CPTXYPlotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsUserInteraction = false
        
        
        let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
        let yRange = plotSpace.yRange.mutableCopy() as! CPTMutablePlotRange
        
        xRange.length = 1.1
        yRange.length = 1.1
        
        
        plotSpace.xRange = xRange
        plotSpace.yRange = yRange
        
        
        
        // Axes
        
        // var axisSet = CPTXYAxisSet(frame:self.graphView.bounds)
        let axisSet = graph.axisSet as! CPTXYAxisSet
        axisSet.xAxis!.axisConstraints = CPTConstraints.constraintWithUpperOffset(1.0)
        axisSet.yAxis!.axisConstraints = CPTConstraints.constraintWithUpperOffset(1.0)
        axisSet.yAxis!.axisConstraints = CPTConstraints.constraintWithLowerOffset(0.0)
        axisSet.xAxis!.axisConstraints = CPTConstraints.constraintWithLowerOffset(0.0)
        axisSet.xAxis!.tickDirection = CPTSign.Positive
        axisSet.yAxis!.tickDirection = CPTSign.Positive
        
        
        
        axisSet.xAxis!.majorTickLength = 0.5
        axisSet.xAxis!.minorTicksPerInterval = 3
        axisSet.yAxis!.majorTickLength = 0.5
        axisSet.yAxis!.minorTicksPerInterval = 3
        graph.axisSet = axisSet
        
        
        priorPlot = CPTScatterPlot(frame:graph.bounds)
        priorPlot.identifier = "PriorPlot"
        let priorLineStyle = CPTMutableLineStyle()
        priorLineStyle.miterLimit = 1.0
        priorLineStyle.lineWidth = 2.0
        priorLineStyle.lineColor = CPTColor.lightGrayColor()
        priorPlot.dataLineStyle = priorLineStyle
        
        //priorPlot.interpolation = CPTScatterPlotInterpolation.Linear
        priorPlot.interpolation = CPTScatterPlotInterpolation.Stepped
        
        priorPlot.dataSource = self
        priorPlot.delegate = self
        
        
        graph.addPlot(priorPlot)
        
        
        
        let postPlot = CPTScatterPlot(frame:graph.bounds)
        postPlot.identifier = "PostPlot"
        let postLineStyle = CPTMutableLineStyle()
        postLineStyle.miterLimit = 1.0
        postLineStyle.lineWidth = 2.0
        postLineStyle.lineColor = CPTColor.blueColor()
        postPlot.dataLineStyle = postLineStyle
        
        postPlot.dataSource = self
        postPlot.delegate = self
        
        
        graph.addPlot(postPlot)
        
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        skView.nodesController = self.nodesController
        skView.modelTreeController = self.modelTreeController
        scene.modelTreeController = self.modelTreeController
        scene.nodesController = self.nodesController
        
        let options: NSKeyValueObservingOptions = [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old]
        modelTreeController.addObserver(self, forKeyPath: "selectionIndexPath", options: options, context: nil)
        

        nodesController.addObserver(self, forKeyPath: "selectionIndex", options: options, context: nil)
        
        
    }
    /*
    override func viewDidLayout() {
     //   println("mdvc views bounds widths: \(view.bounds.width) \(visView.bounds.width) \(skView.bounds.width)")
        scene.redrawNodes()
        
    }
    */
    
    //******CPTScatterPlotDataSource fxns
    
    func reloadData() {
        
        let allNodes : [BNNode] = nodesController.arrangedObjects as! [BNNode]

        for chkNode : BNNode in allNodes {
            // print("chknode \(chkNode.nodeLink.name) isParent \(chkNode.isParent)")
            if(chkNode.influencedBy.count > 0) { //child
                if(chkNode.isParent != 0){
                    chkNode.setValue(0, forKey: "isParent")


                }
                
            }
            else {
                if(chkNode.isParent != 1){
                    chkNode.setValue(1, forKey: "isParent")

                }
            }
            
            parentNodesController.rearrangeObjects()
            childNodesController.rearrangeObjects()
            
        }

        
        
        
        //Get selected node
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]

            priorDist = Int(curNode.priorDistType)
            V1 = Double(curNode.priorV1)
            V2 = Double(curNode.priorV2)
            
            if(curNode.influencedBy.count > 0) {
                priorControlsView.hidden = true
                cptControlsView.hidden = false
                
                graph.addPlot(priorPlot)
                graph.removePlot(priorPlot)
                
                //collect data for the CPT controls
                self.collectData()
            }
            else {
                priorControlsView.hidden = false
                cptControlsView.hidden = true
                
                
                switch priorDist{
                case 0: //point/expert
                    priorV1Slider.hidden = false
                    priorV1Field.hidden = false
                    priorV2Slider.hidden = true
                    priorV2Field.hidden = true
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.Linear
                   
                case 2: // gaussian
                    
                    priorV1Slider.hidden = false
                    priorV1Field.hidden = false
                    priorV2Slider.hidden = false
                    priorV2Field.hidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.Curved
                    
                    
                case 3: //beta
                    priorV1Slider.hidden = false
                    priorV1Field.hidden = false
                    priorV2Slider.hidden = false
                    priorV2Field.hidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 10.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 10.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.Curved
                    

                    
                    
                case 4: //gamma
                    priorV1Slider.hidden = false
                    priorV1Field.hidden = false
                    priorV2Slider.hidden = false
                    priorV2Field.hidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 10.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 10.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.Curved
                    
                    
                case 5: //priorpost
                    priorV1Slider.hidden = true
                    priorV1Field.hidden = true
                    priorV2Slider.hidden = true
                    priorV2Field.hidden = true
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                default:
                    priorV1Slider.hidden = false
                    priorV1Field.hidden = false
                    priorV2Slider.hidden = false
                    priorV2Field.hidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.Histogram
                    
                }

                
                graph.addPlot(priorPlot)
                
            }
            /*
            if(curNode.influencedBy.count > 0) {
                
                
                priorTypePopup.hidden = true
                priorV1Slider.hidden = true
                priorV2Slider.hidden = true
                priorV1Field.hidden = true
                priorV2Field.hidden = true
                
                
                scopeLabel.hidden = false
                scopePopup.hidden = false
                numericButton.hidden = false
                dataLabel.hidden = false
                
                dataPopup.hidden = false
                dataSubPopup.hidden = false
                
                graph.addPlot(priorPlot)
                graph.removePlot(priorPlot)
                
                //     println("in reloadData datanames: \(curNode.dataName) \(curNode.dataSubName)")
                
                //collect data for the CPT controls
                self.collectData()
                
            }
            else {
                
                
                priorTypePopup.hidden = false
                switch priorDist{
                case 0: //point/expert
                    priorV2Slider.hidden = true
                    priorV2Field.hidden = true
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                case 3: //beta
                    
                    priorV2Slider.hidden = false
                    priorV2Field.hidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 10.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 10.0
                    
                case 4: //gamma
                    
                    priorV2Slider.hidden = false
                    priorV2Field.hidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 10.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 10.0
                default:
                    priorV2Slider.hidden = false
                    priorV2Field.hidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                }
                priorV1Slider.hidden = false
                priorV1Field.hidden = false
                
                
                
                scopeLabel.hidden = true
                scopePopup.hidden = true
                numericButton.hidden = true
                dataLabel.hidden = true
                
                dataPopup.hidden = true
                dataSubPopup.hidden = true
                
                graph.addPlot(priorPlot)
                
            }
            */
            
            
            if curNode.postCount != nil {
                
                let postCount = NSKeyedUnarchiver.unarchiveObjectWithData(curNode.valueForKey("postCount") as! NSData) as! [Int]
                // println("postCount \(postCount)")
                var postData = [NSNumber]()
                var curtop = 0
                for thisPost in postCount {
                    if (curtop < thisPost) {
                        curtop = thisPost
                    }
                }
                for thisPost : Int in postCount {
                    postData.append(Double(thisPost)/Double(curtop))
                }
                
                
                
                self.dataForChart = postData
            }
            else {
                
                self.dataForChart = [Double](count: 100, repeatedValue: 0.0)
            }
            
            if curNode.priorCount != nil {
                let priorCount = NSKeyedUnarchiver.unarchiveObjectWithData(curNode.valueForKey("priorCount") as! NSData) as! [Int]
              //   println("priorCount \(priorCount)")
                var priorData = [NSNumber]()
                var curtop = 0
                for thisPost in priorCount {
                    if (curtop < thisPost) {
                        curtop = thisPost
                    }
                }
                for thisPrior : Int in priorCount {
                    priorData.append(Double(thisPrior)/Double(curtop))
                }
                
            
                self.priorDataForChart = priorData
            }
            else {
                
                self.priorDataForChart = [Double](count: 100, repeatedValue: 0.0)
            }
            
            
        }
            
        else { //no node, just move graph off view
            
            priorControlsView.hidden = false
            cptControlsView.hidden = true
            
            /*
            priorTypePopup.hidden = true
            priorV1Slider.hidden = true
            priorV2Slider.hidden = true
            priorV1Field.hidden = true
            priorV2Field.hidden = true
            
            scopeLabel.hidden = true
            scopePopup.hidden = true
            numericButton.hidden = true
            dataLabel.hidden = true
            
            dataPopup.hidden = true
            dataSubPopup.hidden = true
            */
            
            
            priorDist = 0
            V1 = -10000.0
            V2 = -10000.0
            self.dataForChart = [Double](count: 100, repeatedValue: -10000.0)
        }
        
        
        
        graph.reloadData()
        
        
        
        
    }
    
    
    
    func numberOfRecordsForPlot(plot: CPTPlot) -> UInt {
        
        if(plot.identifier!.isEqual("PriorPlot")){
            switch priorDist {

            case 5: //priorPost
                return UInt(self.priorDataForChart.count)
                
            default:
                return UInt(self.dataForChart.count)
            }
        }
        
        return UInt(self.dataForChart.count)
        
    }
    
    
    func numberForPlot(plot: CPTPlot, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject? {
        let numrec = Double(numberOfRecordsForPlot(plot))
        
        if(fieldEnum == 0){//x
            return (Double(idx)/numrec)
        }
        if(fieldEnum == 1){ //y
            
            if(plot.identifier!.isEqual("PriorPlot")){
                
                
                let nidx = (Double(idx)/numrec)
                let nnidx = (Double(idx+1)/numrec)
                
                switch priorDist {
                    
                case 0:  //point/expert
                    if(nidx <= V1 && nnidx > V1){
                        return 1
                    }
                    else {
                        return 0
                    }
                    
                case 1: //uniform
                    if(nidx >= V1 && nidx < V2){
                        return 1
                    }
                    else {
                        return 0
                    }
                    
                case 2: //gaussian
                    return gaussian(V1, sigma: V2, x: nidx)
                    
                case 3: //beta
                    return beta(V1, b: V2, x: nidx)
                    
                case 4: //gamma
                    
                    
                    return gamma(V1, b:V2, x:nidx)
                    
                case 5: //priorPost
                   // println(self.priorDataForChart[Int(idx)] as NSNumber)
                    return self.priorDataForChart[Int(idx)] as NSNumber
                    
                default:
                    return 0
                }
                
                
                
                
            }
                
            else if(plot.identifier!.isEqual("PostPlot")){
                
                return self.dataForChart[Int(idx)] as NSNumber
            }
        }
        
        
        return 0
    }
    
    
    
    
    //******
    
    
    
    func collectData() {
    //    let errorPtr : NSErrorPointer = nil
        
        self.dataPopup.removeAllItems()
        self.dataSubPopup.removeAllItems()
        self.dataPopup.enabled = true
        self.dataSubPopup.enabled = true
        self.dataPopup.hidden = false
        self.dataSubPopup.hidden = false
        var dataNames = [String]()
        var dataSubNames = [String]()

        

        
        
      //  let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
       // let curModel : Model = curModels[0]
      //  let curDataset : Dataset = curModel.dataset
        
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            
        //    let request = NSFetchRequest(entityName: "Trait")
       //     var predicate = NSPredicate()
            

            
            dataNames = curNode.getDataNames()
            

            
            
            switch(curNode.dataScope) {
            case 0://global // ALL entities matching this one's name
                
                //   println("global \(curNode.nodeLink.name)")
                //dataNames.append(curNode.nodeLink.name)
                self.dataPopup.enabled = false
                self.dataPopup.hidden = true
                self.dataSubPopup.enabled = false
                self.dataSubPopup.hidden = true
                
                
            case 1:// self
                //    println("self \(curNode.nodeLink.name)")
                
                //from that object, select only the names of what is directly connected to it
                if(curNode.nodeLink.entity.name == "Entry"){
                    //  println("entry")
                    /*
                    let curEntry = curNode.nodeLink as! Entry
                    let theTraits = curEntry.trait
                    for thisTrait in theTraits {
                        dataNames.append(thisTrait.name)
                    }
*/
                    
                }
                else if (curNode.nodeLink.entity.name == "Trait"){//if you select trait here, you can only mean this trait
                 //   dataNames.append(curNode.nodeLink.name)
                    self.dataPopup.enabled = false
                    self.dataPopup.hidden = true
                    self.dataSubPopup.enabled = false
                    self.dataSubPopup.hidden = true
                }
                    
                else if (curNode.nodeLink.entity.name == "Structure"){    //The traits whose entries are part of this structure
                    /*
                    let curStructure = curNode.nodeLink as! Structure
                    let curEntries = curStructure.entry
                    for curEntry in curEntries {
                        let curTraits = curEntry.trait
                        for curTrait in curTraits{
                            dataNames.append(curTrait.name)
                        }
                    }
*/
                    
                }
                else {
                    //dataNames = [String]()
                }
                
             /*
            case 2: //children
                //   println("children \(curNode.nodeLink.name)")
                
                
                if(curNode.nodeLink.entity.name == "Entry"){ //take this entry's children and look at it's children
                    
                    
                    //If it is connected to this entry, then it is autmatically in that entry's only possible dataset
                    predicate = NSPredicate(format: "entry.parent == %@", curNode.nodeLink)
                    
                    
                    request.resultType = .DictionaryResultType
                    request.predicate = predicate
                    request.returnsDistinctResults = true
                    request.propertiesToFetch = ["name"]
                    
                    do {
                        let fetch = try moc.executeFetchRequest(request)
                        //  println("in entry to trait children fetch \(fetch)")
                        for obj  in fetch {
                            //println(obj.valueForKey("name"))
                            dataNames.append(obj.valueForKey("name") as! String)
                            
                        }
                    } catch let error as NSError {
                        errorPtr.memory = error
                    }
                    
                }
                else if (curNode.nodeLink.entity.name == "Trait" || curNode.nodeLink.entity.name == "Structure"){ //traits and structures have no children
                    curNode.dataScope = 0
                    dataNames = [String]()
                    return
                    
                    
                    
                }
                else {
                    dataNames = [String]()
                    
                }
                */
                
                
            default:
                
                print("collectData out of bounds")
                dataNames = [String]()
                
            }
            
            //  println("dataNames \(dataNames)")
            
            self.dataPopup.addItemsWithTitles(dataNames)
            
            
            if(self.dataPopup.itemArray.count > 0){
                self.dataPopup.selectItemWithTitle(curNode.dataName)
            }
            
            
            // println("curNode.dataName \(curNode.dataName)")
            
            dataSubNames = curNode.getDataSubNames()
            self.dataSubPopup.addItemsWithTitles(dataSubNames)
            

            
            /*

            //if the currentdataName can be found in the list, it is selected and them subNames can be found, otherwise just return
            if dataNames.contains(curNode.dataName){
                predicate = NSPredicate()
                
                //now create pickable list of trait values
                switch(curNode.dataScope) {
                case 0://global list of all possible values of all traits with this name
                    
                    // println("dataSubNames global")
                    
                    if(curNode.nodeLink.entity.name == "Entry"){//Traits whose names match the name of this entry
                        //  println("entry")
                        predicate = NSPredicate(format: "entry.dataset == %@ AND name == %@", curDataset, curNode.nodeLink.name)
                        
                        
                    }
                    else if (curNode.nodeLink.entity.name == "Trait"){ //you obviously want this trait's own value, then
                        //  println("trait")
                        predicate = NSPredicate(format: "entry.dataset == %@ AND name == %@", curDataset, curNode.nodeLink.name)
                    }
                    
                case 1: //self
                    //  println("dataSubNames self")
                    
                    if(curNode.nodeLink.entity.name == "Entry"){
                        //     println("entry")
                        predicate = NSPredicate(format: "entry == %@ AND name == %@", curNode.nodeLink, curNode.dataName)
                        
                        
                    }
                        
                    else if (curNode.nodeLink.entity.name == "Trait"){ //you obviously want this trait's own value, then
                        //  println("trait")
                        predicate = NSPredicate(format: "entry == %@", curNode.nodeLink)
                        
                        
                        
                    }
                    
                case 2: //children
                    //   println("dataSubNames children")
                    if(curNode.nodeLink.entity.name == "Entry"){ //take this entry's children and look at it's children
                        //     println("entry")
                        predicate = NSPredicate(format: "entry.parent == %@ AND name == %@", curNode.nodeLink, curNode.dataName)
                        
                    }
                        
                    else if (curNode.nodeLink.entity.name == "Trait"){ //traits cannot have children
                        //   println("trait")
                    }
                    
                default:
                    print("out of bounds")
                    
                }
                
                request.resultType = .DictionaryResultType
                request.predicate = predicate
                request.returnsDistinctResults = true
                request.propertiesToFetch = ["traitValue"]
                
                do {
                    let fetch = try moc.executeFetchRequest(request)
                    // println("sub fetch \(fetch)")
                    for obj  in fetch {
                        //   println(obj.valueForKey("traitValue"))
                        dataSubNames.append(obj.valueForKey("traitValue") as! String)
                        
                    }
                } catch let error as NSError {
                    errorPtr.memory = error
                }
                
                
                self.dataSubPopup.addItemsWithTitles(dataSubNames)
                if(self.dataSubPopup.itemArray.count > 0){
                    self.dataSubPopup.selectItemWithTitle(curNode.dataSubName)
                }
                
                
                
                
            }
                
                //because we are sleetcing froma  live list, ok to select first option if exisitng is not found
                
            else {
                dataSubNames = [String]()
                //                println("no contains")
                
                
                
            }
            
            */
            
            //          println("and after \(curNode.dataName) \(curNode.dataSubName)")
            
        }
            
        else {
            self.dataPopup.hidden = true
            self.dataSubPopup.hidden = true
        }
        
        
    }
    
    
    //****** distn fxns
    func gaussian(mu: Double, sigma: Double, x: Double) -> Double {
        let n : Double = sigma * 2.0 * sqrt(M_PI)
        let p : Double = exp( -pow(x-mu, 2.0) / (2.0 * pow(sigma, 2.0)))
        return p/n
    }
    
    func beta(a: Double, b: Double, x: Double) -> Double {
        
        let betanorm : Double = tgamma((a+b))/(tgamma(a)+tgamma(b))
        
        let secondhalf : Double = pow(x, (a-1))*pow((1-x),(b-1))
        
        return betanorm * secondhalf
    }
    
    func gamma(a: Double, b: Double, x: Double) -> Double {//gamma distribution, not funciotn
        let numerator = pow(b,a) * pow(x, (a-1)) * pow(M_E,-(x*b))
        return numerator/tgamma(a)
    }
    //******
    

    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
      //  println("observed \(object) \(change) \(context)")
        let keyPathStr : String = keyPath! //FIXME this was added becaiuse in swift 2.0 the fxn was changed so that keyPath was a String?
        switch (keyPathStr) {
            case("selectionIndexPath"): //modelTreeController
                scene.reloadData()
                
            case("selectionIndex"): //nodesController
                self.reloadData()
                
            default:
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func mocDidChange(notification: NSNotification){
        
          //println("model detail moc changed")
        self.reloadData()
        
        
    }
    
    
    
    
    //NSTableView delegate methods
    
    func tableView(tableView: NSTableView, dataCellForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        
        
        if(tableView == childTableView){
            
            let curNodes : [BNNode] = childNodesController.arrangedObjects as! [BNNode]
            let curNode : BNNode = curNodes[row]
            
            if(tableColumn?.identifier == "DataName" ){
                
                let cell = tableColumn?.dataCellForRow(row) as! NSPopUpButtonCell
                cell.removeAllItems()
                
                
                cell.bordered = false
                
                
                let dataNames : [String] = curNode.getDataNames()
                
                
                
                cell.addItemsWithTitles(dataNames)
                
                /*
                print("row \(row) dataName: \(curNode.dataName)")
                for item in cell.itemArray {
                    print(item)
                }
                print("----------------------")
*/

                
                //cell.selectItemWithTitle(curNode.dataName)
                
                return cell
            }
                
            else if (tableColumn?.identifier == "DataSubName" ){
                //let cell = NSPopUpButtonCell()
                let cell = tableColumn?.dataCellForRow(row) as! NSPopUpButtonCell
                cell.removeAllItems()
                
                cell.bordered = false
                
                let dataSubNames : [String] = curNode.getDataSubNames()
                
                cell.addItemsWithTitles(dataSubNames)
                
                cell.selectItemWithTitle(curNode.dataSubName)
                
                if(cell.itemArray.count < 1){
                    cell.enabled = false
                    cell.editable = false
                }
                else {
                    cell.enabled = true
                    cell.editable = false
                }

                /*
                
                print("row \(row) dataSubName: \(curNode.dataSubName) enabled \(cell.enabled)")
                for item in cell.itemArray {
                    print(item)
                }
                print("----------------------")
*/
                
                /*
                switch(curNode.dataScope) {
                case 0:
                    switch(curNode.nodeLink.entity.name!) {
                    case "Entry":
                        cell.enabled = false
                        
                    default:
                        cell.enabled = true
                    }
                    
                default:
                    cell.enabled = true
                    
                }
                */
                
                return cell
                
            }
            
        }
        return nil
    }
}
