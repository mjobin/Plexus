//
//  PlexusModelDetailViewController.swift
//  Plexus
//
//  Created by matt on 6/9/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

import Cocoa
import SpriteKit


class PlexusModelDetailViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, CPTScatterPlotDataSource, CPTScatterPlotDelegate {
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    @IBOutlet dynamic var nodesController : NSArrayController!
    @IBOutlet dynamic var allNodesController : NSArrayController!
    
    //Nodes View
    @IBOutlet weak var nodeVisView: NSVisualEffectView!
    @IBOutlet weak var skView: PlexusBNSKView!
    var scene: PlexusBNScene!
    
    
    //Single Node View
    @IBOutlet weak var singleNodeVisView: NSVisualEffectView!
    @IBOutlet var graphView : CPTGraphHostingView!

    //Detail View
    @IBOutlet weak var nodeDetailView : NSView!
    @IBOutlet weak var nodeDetailVisView: NSVisualEffectView!
    @IBOutlet var nodeDetailGraphView : CPTGraphHostingView!
    @IBOutlet weak var nodeDetailPriorCPTView : NSView!
    @IBOutlet weak var nodeDetailPriorView : NSView!
    @IBOutlet weak var nodeDetailCPTView : NSView!
    
    
    @IBOutlet var priorTypePopup : NSPopUpButton!
    @IBOutlet var priorV1Slider : NSSlider!
    @IBOutlet var priorV1Field : NSTextField!
    @IBOutlet var priorV1Label : NSTextField!
    @IBOutlet var priorV2Slider : NSSlider!
    @IBOutlet var priorV2Field : NSTextField!
    @IBOutlet var priorV2Label : NSTextField!
    @IBOutlet var numericData : NSButton!
    
    var cptReady : [BNNode:Int] = [:]
    
    var priorDist = 0
    var V1 = 0.1
    var V2 = 0.5
    var dataForChart = [NSNumber]()
    var priorDataForChart = [NSNumber]()
    
    var curNode : BNNode!
    var graph : CPTXYGraph!
    var detailGraph : CPTXYGraph!
    var priorPlot : CPTScatterPlot!
    var dpriorPlot : CPTScatterPlot!
    
    var calcCPT = false
    var calcThisCPT = false

    var firstrun = true
    var mocChange = false
    var calcInProgress = false
    
    let defaults = UserDefaults.standard
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        

        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        
        nodeVisView.blendingMode = NSVisualEffectBlendingMode.behindWindow
        nodeVisView.material = NSVisualEffectMaterial.ultraDark
        nodeVisView.state = NSVisualEffectState.active
        

        scene = PlexusBNScene(size: self.skView.bounds.size)
        scene.scaleMode = SKSceneScaleMode.resizeFill
        self.skView!.presentScene(scene)
        
        
        //Single Node View
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: moc)
        NotificationCenter.default.addObserver(self, selector: #selector(PlexusModelDetailViewController.mocDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: moc)
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"nodeDblClick"), object:nil, queue:nil, using:catchNotification)
        
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlexusModelDetailViewController.cptCheck), userInfo: nil, repeats: true)

        
        singleNodeVisView.blendingMode = NSVisualEffectBlendingMode.behindWindow
        singleNodeVisView.material = NSVisualEffectMaterial.ultraDark
        singleNodeVisView.state = NSVisualEffectState.active
        
        nodeDetailVisView.blendingMode = NSVisualEffectBlendingMode.behindWindow
        nodeDetailVisView.material = NSVisualEffectMaterial.ultraDark
        nodeDetailVisView.state = NSVisualEffectState.active
        
        
        
        graph = CPTXYGraph(frame:self.graphView.bounds)
        self.graphView.hostedGraph = graph

        
        detailGraph = CPTXYGraph(frame:self.graphView.bounds)
        self.nodeDetailGraphView.hostedGraph = detailGraph
        
        //Plot space and frame
        graph.plotAreaFrame?.paddingTop = 10.0
        graph.plotAreaFrame?.paddingBottom = 10.0
        graph.plotAreaFrame?.paddingLeft = 10.0
        graph.plotAreaFrame?.paddingRight = 10.0
        graph.paddingTop = 5.0
        graph.paddingBottom = 5.0
        graph.paddingLeft = 5.0
        graph.paddingRight = 5.0
        
        
        detailGraph.plotAreaFrame?.paddingTop = 10.0
        detailGraph.plotAreaFrame?.paddingBottom = 10.0
        detailGraph.plotAreaFrame?.paddingLeft = 10.0
        detailGraph.plotAreaFrame?.paddingRight = 10.0
        detailGraph.paddingTop = 5.0
        detailGraph.paddingBottom = 5.0
        detailGraph.paddingLeft = 5.0
        detailGraph.paddingRight = 5.0
        
        
        let plotSpace : CPTXYPlotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsUserInteraction = false
        let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
        let yRange = plotSpace.yRange.mutableCopy() as! CPTMutablePlotRange
        xRange.length = 1.1
        yRange.length = 1.1
        plotSpace.xRange = xRange
        plotSpace.yRange = yRange
        
        let detailPlotSpace : CPTXYPlotSpace = detailGraph.defaultPlotSpace as! CPTXYPlotSpace
        detailPlotSpace.allowsUserInteraction = false
        let detailXRange = detailPlotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
        let detailYRange = detailPlotSpace.yRange.mutableCopy() as! CPTMutablePlotRange
        detailXRange.length = 1.1
        detailYRange.length = 1.1
        detailPlotSpace.xRange = xRange
        detailPlotSpace.yRange = yRange
        
        
        // Axes
        let axisLineStyle = CPTMutableLineStyle.init()
        axisLineStyle.lineColor = CPTColor.white()
        let axisSet = graph.axisSet as! CPTXYAxisSet
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
        axisTextStyle.color = CPTColor.white()
        
        axisSet.xAxis?.labelTextStyle = axisTextStyle
        axisSet.yAxis?.labelTextStyle = axisTextStyle
        
        
        let daxisSet = detailGraph.axisSet as! CPTXYAxisSet
        daxisSet.xAxis!.axisConstraints = CPTConstraints.constraint(withUpperOffset: 1.0)
        daxisSet.yAxis!.axisConstraints = CPTConstraints.constraint(withUpperOffset: 1.0)
        daxisSet.yAxis!.axisConstraints = CPTConstraints.constraint(withLowerOffset: 0.0)
        daxisSet.xAxis!.axisConstraints = CPTConstraints.constraint(withLowerOffset: 0.0)
        daxisSet.xAxis!.tickDirection = CPTSign.positive
        daxisSet.yAxis!.tickDirection = CPTSign.positive
        daxisSet.xAxis?.axisLineStyle = axisLineStyle
        daxisSet.xAxis?.majorTickLineStyle = axisLineStyle
        daxisSet.yAxis?.majorTickLineStyle = axisLineStyle
        daxisSet.xAxis?.minorTickLineStyle = axisLineStyle
        daxisSet.yAxis?.minorTickLineStyle = axisLineStyle
        daxisSet.yAxis?.axisLineStyle = axisLineStyle
        
        daxisSet.xAxis?.labelTextStyle = axisTextStyle
        daxisSet.yAxis?.labelTextStyle = axisTextStyle
        
        
        axisSet.xAxis!.labelingPolicy = .automatic
        axisSet.yAxis!.labelingPolicy = .automatic
        axisSet.xAxis!.preferredNumberOfMajorTicks = 3
        axisSet.yAxis!.preferredNumberOfMajorTicks = 3
        axisSet.xAxis!.minorTicksPerInterval = 4
        axisSet.yAxis!.minorTicksPerInterval = 4
        graph.axisSet = axisSet
        
        daxisSet.xAxis!.labelingPolicy = .automatic
        daxisSet.yAxis!.labelingPolicy = .automatic
        daxisSet.xAxis!.preferredNumberOfMajorTicks = 3
        daxisSet.yAxis!.preferredNumberOfMajorTicks = 3
        daxisSet.xAxis!.minorTicksPerInterval = 4
        daxisSet.yAxis!.minorTicksPerInterval = 4
        detailGraph.axisSet = daxisSet
        
        
        let titleTextStyle = CPTMutableTextStyle.init()
        titleTextStyle.color = CPTColor.white()
        
        priorPlot = CPTScatterPlot(frame:graph.bounds)
        priorPlot.identifier = "PriorPlot" as (NSCoding & NSCopying & NSObjectProtocol)?
//        priorPlot.title = ""
        let priorstring = "Prior"
        let priorstringrange = (priorstring as NSString).range(of: priorstring)
        let priorAS = NSMutableAttributedString(string: "Prior")
        priorAS.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: priorstringrange)
        priorPlot.attributedTitle = priorAS
        
        
        let priorLineStyle = CPTMutableLineStyle()
        priorLineStyle.miterLimit = 1.0
        priorLineStyle.lineWidth = 2.0
        priorLineStyle.lineColor = CPTColor.lightGray()
        priorPlot.dataLineStyle = priorLineStyle
        priorPlot.interpolation = CPTScatterPlotInterpolation.stepped
        priorPlot.dataSource = self
        priorPlot.delegate = self
        graph.add(priorPlot)
        
        
        dpriorPlot = CPTScatterPlot(frame:graph.bounds)
        dpriorPlot.identifier = "PriorPlot" as (NSCoding & NSCopying & NSObjectProtocol)?
//        dpriorPlot.title = ""
        dpriorPlot.attributedTitle = priorAS
        let dpriorLineStyle = CPTMutableLineStyle()
        dpriorLineStyle.miterLimit = 1.0
        dpriorLineStyle.lineWidth = 2.0
        dpriorLineStyle.lineColor = CPTColor.lightGray()
        dpriorPlot.dataLineStyle = dpriorLineStyle
        dpriorPlot.interpolation = CPTScatterPlotInterpolation.stepped
        dpriorPlot.dataSource = self
        dpriorPlot.delegate = self
        detailGraph.add(dpriorPlot)
        
        
        
        let postPlot = CPTScatterPlot(frame:graph.bounds)
        postPlot.identifier = "PostPlot" as (NSCoding & NSCopying & NSObjectProtocol)?
//        postPlot.title = ""
        let poststring = "Posterior"
        let poststringrange = (poststring as NSString).range(of: poststring)
        let postAS = NSMutableAttributedString(string: "Posterior")
        postAS.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: poststringrange)
        postPlot.attributedTitle = postAS
        
        
        
        
        
        
        //        postPlot.title = "Posterior"
        let postLineStyle = CPTMutableLineStyle()
        postLineStyle.miterLimit = 1.0
        postLineStyle.lineWidth = 2.0
        postLineStyle.lineColor = CPTColor.blue()
        postPlot.dataLineStyle = postLineStyle
        postPlot.dataSource = self
        postPlot.delegate = self
        graph.add(postPlot)
        
        
        let dpostPlot = CPTScatterPlot(frame:graph.bounds)
        dpostPlot.identifier = "PostPlot" as (NSCoding & NSCopying & NSObjectProtocol)?
//        dpostPlot.title = ""
        dpostPlot.attributedTitle = postAS
        let dpostLineStyle = CPTMutableLineStyle()
        dpostLineStyle.miterLimit = 1.0
        dpostLineStyle.lineWidth = 2.0
        dpostLineStyle.lineColor = CPTColor.blue()
        dpostPlot.dataLineStyle = postLineStyle
        dpostPlot.dataSource = self
        dpostPlot.delegate = self
        detailGraph.add(dpostPlot)
        
        
        for plot in (graph?.allPlots())! {
            plot.attributedTitle = nil
            if(plot.identifier!.isEqual("PriorPlot")){
                let priorstring = "Prior"
                let priorstringrange = (priorstring as NSString).range(of: priorstring)
                let priorAS = NSMutableAttributedString(string: "Prior")
                priorAS.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: priorstringrange)
                plot.attributedTitle = priorAS
            }
            else {
                let poststring = "Posterior"
                let poststringrange = (poststring as NSString).range(of: poststring)
                let postAS = NSMutableAttributedString(string: "Posterior")
                postAS.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: poststringrange)
                plot.attributedTitle = postAS
            }
        }
        
        
        graph.legend = CPTLegend(graph: graph)
        graph.legendAnchor = .topRight
        
        detailGraph.legend = CPTLegend(graph: detailGraph)
        detailGraph.legendAnchor = .topRight
        
      
        
    }
    
    func setGraphParams() {
        
        graph.add(priorPlot)
        
        for plot in (graph?.allPlots())! {
            plot.title = nil
            plot.attributedTitle = nil
            if(plot.identifier!.isEqual("PriorPlot")){
                let priorstring = "Prior"
                let priorstringrange = (priorstring as NSString).range(of: priorstring)
                let priorAS = NSMutableAttributedString(string: "Prior")
                priorAS.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: priorstringrange)
                plot.attributedTitle = priorAS
            }
            else {
                let poststring = "Posterior"
                let poststringrange = (poststring as NSString).range(of: poststring)
                let postAS = NSMutableAttributedString(string: "Posterior")
                postAS.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: poststringrange)
                plot.attributedTitle = postAS
            }
        }
       
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        skView.vc = self
        skView.nodesController = self.nodesController
        skView.modelTreeController = self.modelTreeController
        scene.modelTreeController = self.modelTreeController
        scene.nodesController = self.nodesController
        
        let options: NSKeyValueObservingOptions = [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old]
        modelTreeController.addObserver(self, forKeyPath: "selectionIndexPath", options: options, context: nil)
        
        nodesController.addObserver(self, forKeyPath: "selectionIndex", options: options, context: nil)
        
        
    }

    
    override func viewDidDisappear() {
        super.viewDidDisappear()

        
        let leaveOnClose = defaults.bool(forKey: "leaveOnClose")
        if(leaveOnClose != true){
            let curNodes : [BNNode] = allNodesController.arrangedObjects as! [BNNode]
            for curNode in curNodes{
                curNode.setValue(0, forKey: "cptReady")
            }
        }
        else {
            for (key, value) in cptReady{
                key.setValue(value, forKey: "cptReady")
            }
        }
        defaults.set(true, forKey: "leaveOnClose")
        
        do {
            try moc.save()
        } catch let error as NSError {
            print(error)
        }
    }
    
    
    
    func dblClickNode () {
        let curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        let curNode = curNodes[0]
        if(curNode.influencedBy.count > 0) {
            self.performSegue(withIdentifier: "postNode", sender: self)
        }
        else {
           self.performSegue(withIdentifier: "nodeInspect", sender: self)
        }

    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "nodeInspect" {
            let nodePop : PlexusNodePopoverDetail = segue.destinationController as! PlexusNodePopoverDetail
            nodePop.nodesController = nodesController
        }
        
        if segue.identifier == "postNode" {
            let nodePop : PlexusPostPopoverDetail = segue.destinationController as! PlexusPostPopoverDetail
            nodePop.nodesController = nodesController
            nodePop.modelTreeController = modelTreeController
            nodePop.plexusModelDetailViewController = self
        }
        
    }
    
    //******CPTScatterPlotDataSource fxns
    
    func reloadData() {
        
        for view in nodeDetailCPTView.subviews{
            view.removeFromSuperview()
        }
        //Get selected node
        let cptTableContainer = NSScrollView(frame:nodeDetailCPTView.frame)
        numericData.isHidden = false


        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
   
            priorDist = Int(curNode.priorDistType)
            V1 = Double(curNode.priorV1)
            V2 = Double(curNode.priorV2)
//            print ("\(curNode.nodeLink.name) infbys: \(curNode.influencedBy.count)")
            if(curNode.influencedBy.count > 0) {
                nodeDetailPriorView.isHidden = true
                nodeDetailCPTView.isHidden = false

//                numericData.isHidden = false
                graph.add(priorPlot)
                graph.remove(priorPlot)
                
                detailGraph.add(dpriorPlot)
                detailGraph.remove(dpriorPlot)
                
                //Construct CPT
                
                let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
                let curModel : Model = curModels[0]

                
                if((cptReady[curNode] == 2 && calcCPT == false && calcThisCPT == false) || curModel.complete as Bool){
                    let cptTableView = NSTableView(frame:nodeDetailCPTView.frame)
                    for curColumn in cptTableView.tableColumns{
                        cptTableView.removeTableColumn(curColumn)
                    }
                    let theInfBy : [BNNode] = curNode.infBy(self) as! [BNNode]
                    for thisInfBy in theInfBy {
                        let cptcolumn = NSTableColumn(identifier: thisInfBy.nodeLink.name)
                        cptcolumn.headerCell.stringValue = thisInfBy.nodeLink.name
                        cptTableView.addTableColumn(cptcolumn)
                        
                    }
                    let datacolumn = NSTableColumn(identifier: "Data")
                    datacolumn.headerCell.stringValue = "CP"
                    cptTableView.addTableColumn(datacolumn)
                    
                    cptTableView.delegate = self
                    cptTableView.dataSource = self
                    cptTableView.reloadData()
                    cptTableContainer.documentView = cptTableView
                }
                
                else {

                    let cptProgInd = NSProgressIndicator()
                    cptProgInd.usesThreadedAnimation = true
                    cptProgInd.isIndeterminate = true
                    cptProgInd.style = .spinningStyle
                    cptTableContainer.documentView = cptProgInd
                    //FIXME center?
                   // cptTableContainer.addSubview(cptProgInd)
                    cptProgInd.sizeToFit()
                    cptProgInd.startAnimation(self)
                    
 
                }
                

                cptTableContainer.hasVerticalScroller = true
                cptTableContainer.translatesAutoresizingMaskIntoConstraints = false
                nodeDetailCPTView.addSubview(cptTableContainer)
                let topc = NSLayoutConstraint(item: cptTableContainer, attribute: .top, relatedBy: .equal, toItem: nodeDetailCPTView, attribute: .top, multiplier: 1.0, constant: 0.0)
                let botc = NSLayoutConstraint(item: cptTableContainer, attribute: .bottom, relatedBy: .equal, toItem: nodeDetailCPTView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
                let trailc = NSLayoutConstraint(item: cptTableContainer, attribute: .trailing, relatedBy: .equal, toItem: nodeDetailCPTView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
                let leadc = NSLayoutConstraint(item: cptTableContainer, attribute: .leading, relatedBy: .equal, toItem: nodeDetailCPTView, attribute: .leading, multiplier: 1.0, constant: 0.0)
                
                nodeDetailCPTView.addConstraints([trailc, leadc, topc, botc])
                

                
            }
            else {

                nodeDetailCPTView.isHidden = true
                nodeDetailPriorView.isHidden = false
                
//                numericData.isHidden = true
                
                switch priorDist{
                case 0: //point/expert
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = true
                    priorV2Field.isHidden = true
                    priorV2Label.isHidden = true
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.linear
                    dpriorPlot.interpolation = CPTScatterPlotInterpolation.linear
                    
                   
                case 2: // gaussian
                    
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = false
                    priorV2Field.isHidden = false
                    priorV2Label.isHidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    

                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.curved
                    dpriorPlot.interpolation = CPTScatterPlotInterpolation.curved

                    
                case 3: //beta
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = false
                    priorV2Field.isHidden = false
                    priorV2Label.isHidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 10.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 10.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.curved
                    dpriorPlot.interpolation = CPTScatterPlotInterpolation.curved

                    

                    
                    
                case 4: //gamma
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = false
                    priorV2Field.isHidden = false
                    priorV2Label.isHidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 10.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 10.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.curved
                    dpriorPlot.interpolation = CPTScatterPlotInterpolation.curved
                    
                    
                case 5: //priorpost
                    priorV1Slider.isHidden = true
                    priorV1Field.isHidden = true
                    priorV2Slider.isHidden = true
                    priorV2Field.isHidden = true
                    priorV1Label.isHidden = true
                    priorV2Label.isHidden = true
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    priorPlot.interpolation = CPTScatterPlotInterpolation.curved
                    dpriorPlot.interpolation = CPTScatterPlotInterpolation.curved
                    
                default:
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = false
                    priorV2Field.isHidden = false
                    priorV2Label.isHidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.histogram
                    dpriorPlot.interpolation = CPTScatterPlotInterpolation.histogram
                    
                }

                
                graph.add(priorPlot)
                detailGraph.add(dpriorPlot)
                
            }
            

            
            switch priorDist {
                
                case 5: //priorPost
                    let priorCount = NSKeyedUnarchiver.unarchiveObject(with: curNode.value(forKey: "priorCount") as! Data) as! [Int]
                    var priorData = [NSNumber]()
                    var curtop = 0
                    for thisPost in priorCount {
                        if (curtop < thisPost) {
                            curtop = thisPost
                        }
                    }
                    for thisPrior : Int in priorCount {
                        priorData.append((Double(thisPrior)/Double(curtop)) as NSNumber)
                    }
                    
                    
                    self.priorDataForChart = priorData
                    
                default:
                    self.priorDataForChart = [Double](repeating: 0.0, count: 100) as [NSNumber]
            }
            if(curNode.influencedBy.count > 0 && curNode.postCount != nil) {
//            if curNode.postCount != nil {

                let postCount = NSKeyedUnarchiver.unarchiveObject(with: curNode.value(forKey: "postCount") as! Data) as! [Int]
                var postData = [NSNumber]()
                var curtop = 0
                for thisPost in postCount {
//                    print ("thispost \(thisPost)")
                    if (curtop < thisPost) {
                        curtop = thisPost
                    }
                }
                for thisPost : Int in postCount {
                    postData.append((Double(thisPost)/Double(curtop)) as NSNumber)
                    //FIXME this sets the top to 1 always
                }
                
                self.dataForChart = postData
            }
            else {
                self.dataForChart = [Double](repeating: 0.0, count: 100) as [NSNumber]
            }
            
//            if curNode.priorCount != nil {
//                let priorCount = NSKeyedUnarchiver.unarchiveObject(with: curNode.value(forKey: "priorCount") as! Data) as! [Int]
//                var priorData = [NSNumber]()
//                var curtop = 0
//                for thisPost in priorCount {
//                    if (curtop < thisPost) {
//                        curtop = thisPost
//                    }
//                }
//                for thisPrior : Int in priorCount {
//                    priorData.append((Double(thisPrior)/Double(curtop)) as NSNumber)
//                }
//                
//            
//                self.priorDataForChart = priorData
//            }
//            else {
//                
//                self.priorDataForChart = [Double](repeating: 0.0, count: 100) as [NSNumber]
//            }
            
            
        }
            
        else { //no node, just move graph off view
        
            
            priorDist = 0
            V1 = -10000.0
            V2 = -10000.0
            self.dataForChart = [Double](repeating: -10000.0, count: 100) as [NSNumber]
        }
        
        
        graph.reloadData()
        detailGraph.reloadData()
        
        
    }
    
    
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        
        if(plot.identifier!.isEqual("PriorPlot")){
            return UInt(self.priorDataForChart.count)
        }
        return UInt(self.dataForChart.count) //Assume Posterior Plot otherwise
        
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        let numrec = Double(numberOfRecords(for: plot))
        
        if(fieldEnum == 0){//x
            return (Double(idx)/numrec) as AnyObject?
        }
        if(fieldEnum == 1){ //y
            
            if(plot.identifier!.isEqual("PriorPlot")){
                

                let nidx = (Double(idx)/numrec)
                let nnidx = (Double(idx+1)/numrec)
                switch priorDist {
                    
                case 0:  //point/expert
                    if(nidx <= V1 && nnidx > V1){
                        return 1 as AnyObject?
                    }
                    else {
                        return 0 as AnyObject?
                    }
                    
                case 1: //uniform
                    if(nidx >= V1 && nidx < V2){
                        return 1 as AnyObject?
                    }
                    else {
                        return 0 as AnyObject?
                    }
                    
                case 2: //gaussian
//                    print("prior \(gaussian(V1, c: V2, x: nidx))")
                    return gaussian(V1, c: V2, x: nidx) as AnyObject?
//                    return gaussian(V1, sigma: V2, x: nidx) as AnyObject?
                    
                case 3: //beta
                    return beta(V1, b: V2, x: nidx) as AnyObject?
                    
                case 4: //gamma
                    
//                    print("prior \(gamma(V1, b: V2, x: nidx))")
                    return gamma(V1, b:V2, x:nidx) as AnyObject?
                    
                case 5: //priorPost
                    return self.priorDataForChart[Int(idx)] as NSNumber
                    
                default:
                    return 0 as AnyObject?
                }

            }
                
            else if(plot.identifier!.isEqual("PostPlot")){
//                print("post \(idx) \(self.dataForChart[Int(idx)] as NSNumber)")

                return self.dataForChart[Int(idx)] as NSNumber
            }
        }
        
        
        return 0 as AnyObject?
    }
    
    
    //****** distn fxns

    
//    func gaussian(_ mu: Double, sigma: Double, x: Double) -> Double {
//        let n : Double = sigma * 2.0 * sqrt(.pi)
//        let p : Double = exp( -pow(x-mu, 2.0) / (2.0 * pow(sigma, 2.0)))
//        return p/n
//    }
    
    func gaussian(_ b: Double, c: Double, x: Double) -> Double {
        return exp( -pow(x-b, 2.0) / (2.0 * pow(c, 2.0)))
    }
    
    func beta(_ a: Double, b: Double, x: Double) -> Double {
        let betanorm : Double = tgamma((a+b))/(tgamma(a)+tgamma(b))
        let secondhalf : Double = pow(x, (a-1))*pow((1-x),(b-1))
        return betanorm * secondhalf
    }
        
    func gamma(_ a: Double, b: Double, x: Double) -> Double { //(A^R)/Gamma(R) * X^(R-1) * Exp(-A*X)
        return pow(a,b)/tgamma(b) * pow(x, (b-1)) * pow(M_E, -(x*a))
    }
    
    
    

    
    
    
    //******
    

    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let keyPathStr : String = keyPath!
        switch (keyPathStr) {
            case("selectionIndexPath"): //modelTreeController
                scene.reloadData()
            case("selectionIndex"): //nodesController
                self.reloadData()
            default:
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func mocDidChange(_ notification: Notification){
        mocChange = true
        let info = notification.userInfo

        var relD = false

        if let objs = info?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for obj :NSManagedObject in objs {

                let changes = obj.changedValues()
                for (key, _) in changes {

                    if(key == "cptReady"){
                        return
                    }
                    else if(key == "influences" || key == "influencedBy"){
                        calcThisCPT = true
                        relD = true

                    }
                    else if(key == "cptArray" || key == "postArray" || key == "postCount" || key == "postETHigh" || key == "postETLow" || key == "postHPDHigh" || key == "postHPDLow" || key == "postMean" || key == "postSSD" || key == "complete"){
                        
                        return
                    }
                    else {
                        calcCPT = true
                        relD = true
                    }
                }

            }
        }

        if (info?[NSDeletedObjectsKey] as? Set<NSManagedObject>) != nil {
            calcCPT = true
            relD = true
        }
        
        if (info?[NSInsertedObjectsKey] as? Set<NSManagedObject>) != nil {
            calcCPT = true
            relD = true
        }
        
        if relD == true {
            self.reloadData()         }


    }
    

    

    func catchNotification(notification:Notification) -> Void {

        let message  = notification.userInfo!["message"] as? String
        if(message == "nodeDblClick"){
            self.dblClickNode()
        }
 
    }
 
    
//tableview data source
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            if (curNode.value(forKey: "cptArray")) == nil {
                return 0
            }
            if(cptReady[curNode] == 2){


                    let cptarray = NSKeyedUnarchiver.unarchiveObject(with: curNode.value(forKey: "cptArray") as! Data) as! [cl_float]
                    return cptarray.count
                
            }
            else {
                return 0
            }
        }
        return 0
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {

        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
           // print(curNode.nodeLink.name)
            if(tableColumn?.identifier == "Data" ){
                let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
                let curModel : Model = curModels[0]
                if curModel.complete.boolValue {
                    if let cptfData = curNode.value(forKey: "cptFreezeArray") {
                        let cptarray = NSKeyedUnarchiver.unarchiveObject(with: cptfData as! Data) as! [cl_float]
                        return cptarray[row]
                    }
                    
                    else {
                        return nil 
                    }

                }
                else {
                let cptarray = NSKeyedUnarchiver.unarchiveObject(with: curNode.value(forKey: "cptArray") as! Data) as! [cl_float]
                return cptarray[row]
                }
            }
            else{
                let poststr = String(row, radix: 2)
                //add chars to pad out
                let theInfBy = curNode.infBy(self)
                var prestr = String()
                for _ in poststr.characters.count..<theInfBy.count {
                    prestr += "0"
                }
                let str = prestr + poststr
                //print("str \(str)")
                let revstr = String(str.characters.reversed())
                //and revrse
                let index = tableView.tableColumns.index(of: tableColumn!)
                //print ("index \(index): revstr \(revstr)")
                if ( index! > revstr.characters.count) {
                    print ("Error. curNode \(curNode.nodeLink.name) infBy \(theInfBy) index \(index): revstr \(revstr)")
                }
                let index2 = revstr.characters.index(revstr.startIndex, offsetBy: index!)
                if(revstr[index2] == "1"){
                    return "T"
                }
                else if (revstr[index2] == "0"){
                    return "F"
                }
            }
        }

        return nil
    }
 
    func cptCheck()
    {


        if calcInProgress == true {
            return
        }

        if (firstrun){
            
            
            cptReady = [:]
            
            let curNodes : [BNNode] = allNodesController.arrangedObjects as! [BNNode]
            if(curNodes.count>0) {
                for curNode in curNodes{
                    if (curNode.cptReady as Int? == 1){
                        cptReady[curNode] = 0
                    }
                    else {
                        cptReady[curNode] = curNode.cptReady as Int?
                    }
                }
                
            }
            
            let leaveOnOpen = defaults.bool(forKey: "leaveOnOpen")
            if(leaveOnOpen != true){
                let curNodes : [BNNode] = nodesController.arrangedObjects as! [BNNode]
                for curNode in curNodes{
                    cptReady[curNode] = 0
                }
                
                defaults.set(true, forKey: "leaveOnOpen")
            }
            
            firstrun = false
            defaults.set(true, forKey: "leaveOnClose")
            return
        }

        
        var alltwos = true
        var anyones = false
        
        for (key, value) in cptReady{
//        print ("checking on \(key.nodeLink.name): \(value)")
           if(value == 0 && anyones == false) {
                alltwos = false
                self.cptReady[key] = 1 //while processing
                DispatchQueue.global().async {

                  self.cptReady[key] = key.CPT()

                    
                    self.performSelector(onMainThread: #selector(PlexusModelDetailViewController.reloadData), with: nil, waitUntilDone: false)

                }
                break
            }
            else if (value == 1){
                alltwos = false
                anyones = true
            }

        }
        
        if (alltwos) { //If everything is processed and nothing changes, no need to recalculate on startup
            defaults.set(true, forKey: "leaveOnOpen")
            defaults.set(true, forKey: "leaveOnClose")
        }

        
        if(calcThisCPT == true){
            do {
                try moc.save()
            } catch let error as NSError {
                print(error)
            }

            
            let curNodes : [BNNode] = nodesController.arrangedObjects as! [BNNode]
            if(curNodes.count>0) {
                for curNode in curNodes{
                    cptReady[curNode] = 0
                }
            }
            
            calcThisCPT = false
        }
        
        if(calcCPT == true){
            
            do {
                try moc.save()
            } catch let error as NSError {
                print(error)
            }
            

            
            cptReady = [:]
            
            let curNodes : [BNNode] = allNodesController.arrangedObjects as! [BNNode]
            if(curNodes.count>0) {
                for curNode in curNodes{
                    cptReady[curNode] = 0
                }
            }
            
            

            
            defaults.set(false, forKey: "leaveOnOpen")
            defaults.set(false, forKey: "leaveOnClose")

            calcCPT = false
        }
        
        mocChange = false
        
    }


}
