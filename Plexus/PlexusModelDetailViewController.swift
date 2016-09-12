//
//  PlexusModelDetailViewController.swift
//  Plexus
//
//  Created by matt on 6/9/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa
import SpriteKit

class PlexusModelDetailViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, CPTScatterPlotDataSource, CPTScatterPlotDelegate {
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    @IBOutlet dynamic var nodesController : NSArrayController!

    
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
    @IBOutlet var priorV2Slider : NSSlider!
    @IBOutlet var priorV2Field : NSTextField!
    

    
    var priorDist = 0
    var V1 = 0.1
    var V2 = 0.5
    var dataForChart = [NSNumber]()
    var priorDataForChart = [NSNumber]()
    
    var curNode : BNNode!
    var graph : CPTXYGraph!
    var detailGraph : CPTXYGraph!
    var priorPlot : CPTScatterPlot!
    
    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        

        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        
        

        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            curNode.CPT()
        }

        
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
        
        nodeDetailVisView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
        nodeDetailVisView.material = NSVisualEffectMaterial.Dark
        nodeDetailVisView.state = NSVisualEffectState.Active
        
        

        
        graph = CPTXYGraph(frame:self.graphView.bounds)
        self.graphView.hostedGraph = graph
        //self.nodeDetailGraphView.hostedGraph = graph
        
        
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
        
        
        //Get selected node
        let cptTableContainer = NSScrollView(frame:nodeDetailCPTView.frame)
        let cptTableView = NSTableView(frame:nodeDetailCPTView.frame)
        for curColumn in cptTableView.tableColumns{
            cptTableView.removeTableColumn(curColumn)
        }
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            
           // curNode.CPT() //FIXME thus called every time MOC changes?

            priorDist = Int(curNode.priorDistType)
            V1 = Double(curNode.priorV1)
            V2 = Double(curNode.priorV2)
            
            if(curNode.influencedBy.count > 0) {
                nodeDetailPriorView.hidden = true
                nodeDetailCPTView.hidden = false

                
                graph.addPlot(priorPlot)
                graph.removePlot(priorPlot)
                
                //Construct CPT tree
                

                let theInfBy : [BNNode] = curNode.infBy(self) as! [BNNode]
                for thisInfBy in theInfBy {
                    let cptcolumn = NSTableColumn(identifier: thisInfBy.nodeLink.name)
                    cptcolumn.headerCell.stringValue = thisInfBy.nodeLink.name
                    cptTableView.addTableColumn(cptcolumn)

                }
                let datacolumn = NSTableColumn(identifier: "Data")
                datacolumn.headerCell.stringValue = "CP"
                cptTableView.addTableColumn(datacolumn)

                
            }
            else {
                nodeDetailCPTView.hidden = true
                nodeDetailPriorView.hidden = false
                
                
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
            

            
            
            priorDist = 0
            V1 = -10000.0
            V2 = -10000.0
            self.dataForChart = [Double](count: 100, repeatedValue: -10000.0)
        }
        
        cptTableView.setDelegate(self)
        cptTableView.setDataSource(self)
        cptTableView.reloadData()
        cptTableContainer.documentView = cptTableView
        cptTableContainer.hasVerticalScroller = true
        cptTableContainer.translatesAutoresizingMaskIntoConstraints = false
        nodeDetailCPTView.addSubview(cptTableContainer)
        let topc = NSLayoutConstraint(item: cptTableContainer, attribute: .Top, relatedBy: .Equal, toItem: nodeDetailCPTView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        let botc = NSLayoutConstraint(item: cptTableContainer, attribute: .Bottom, relatedBy: .Equal, toItem: nodeDetailCPTView, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        let trailc = NSLayoutConstraint(item: cptTableContainer, attribute: .Trailing, relatedBy: .Equal, toItem: nodeDetailCPTView, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        let leadc = NSLayoutConstraint(item: cptTableContainer, attribute: .Leading, relatedBy: .Equal, toItem: nodeDetailCPTView, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        
        nodeDetailCPTView.addConstraints([trailc, leadc, topc, botc])
        
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
        
        self.reloadData()
    }
    
    
//tableview data source 
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            if (curNode.valueForKey("cptArray")) == nil {
                curNode.CPT()
            }
            let cptarray = NSKeyedUnarchiver.unarchiveObjectWithData(curNode.valueForKey("cptArray") as! NSData) as! [cl_float]
            return cptarray.count
        }
        return 0
    }
    
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        
        if (curNode.valueForKey("cptArray")) == nil {
            var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
            if(curNodes.count>0) {
                curNode = curNodes[0]
                curNode.CPT()
            }
        }

        
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            if(tableColumn?.identifier == "Data" ){
                let cptarray = NSKeyedUnarchiver.unarchiveObjectWithData(curNode.valueForKey("cptArray") as! NSData) as! [cl_float]
                return cptarray[row]
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
                let revstr = String(str.characters.reverse())
                //and revrse
                
                let index = tableView.tableColumns.indexOf(tableColumn!)
                //print ("\(index): \(revstr)")
                let index2 = revstr.startIndex.advancedBy(index!)
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
 
    
    
   
    
    @IBAction func calcCPT(sender : AnyObject){
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            curNode.CPT()
        }
    }
}
