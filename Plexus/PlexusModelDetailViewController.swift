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
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
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

        
        nodeVisView.blendingMode = NSVisualEffectBlendingMode.behindWindow
        nodeVisView.material = NSVisualEffectMaterial.dark
        nodeVisView.state = NSVisualEffectState.active
        

        
        
        scene = PlexusBNScene(size: self.skView.bounds.size)
        scene.scaleMode = SKSceneScaleMode.resizeFill
        self.skView!.presentScene(scene)
        
        
        //Single Node View
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlexusModelDetailViewController.mocDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: moc)
        
        
        
        singleNodeVisView.blendingMode = NSVisualEffectBlendingMode.behindWindow
        singleNodeVisView.material = NSVisualEffectMaterial.dark
        singleNodeVisView.state = NSVisualEffectState.active
        
        nodeDetailVisView.blendingMode = NSVisualEffectBlendingMode.behindWindow
        nodeDetailVisView.material = NSVisualEffectMaterial.dark
        nodeDetailVisView.state = NSVisualEffectState.active
        
        

        
        graph = CPTXYGraph(frame:self.graphView.bounds)
        self.graphView.hostedGraph = graph
        //self.nodeDetailGraphView.hostedGraph = graph
        
        
        let titleStyle = graph.titleTextStyle!.mutableCopy() as! CPTMutableTextStyle
        titleStyle.fontName = "SanFrancisco"
        titleStyle.fontSize = 18.0
        titleStyle.color = CPTColor.white()
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
        axisSet.xAxis!.axisConstraints = CPTConstraints.constraint(withUpperOffset: 1.0)
        axisSet.yAxis!.axisConstraints = CPTConstraints.constraint(withUpperOffset: 1.0)
        axisSet.yAxis!.axisConstraints = CPTConstraints.constraint(withLowerOffset: 0.0)
        axisSet.xAxis!.axisConstraints = CPTConstraints.constraint(withLowerOffset: 0.0)
        axisSet.xAxis!.tickDirection = CPTSign.positive
        axisSet.yAxis!.tickDirection = CPTSign.positive
        
        
        
        axisSet.xAxis!.majorTickLength = 0.5
        axisSet.xAxis!.minorTicksPerInterval = 3
        axisSet.yAxis!.majorTickLength = 0.5
        axisSet.yAxis!.minorTicksPerInterval = 3
        graph.axisSet = axisSet
        
        
        priorPlot = CPTScatterPlot(frame:graph.bounds)
        priorPlot.identifier = "PriorPlot" as (NSCoding & NSCopying & NSObjectProtocol)?
        let priorLineStyle = CPTMutableLineStyle()
        priorLineStyle.miterLimit = 1.0
        priorLineStyle.lineWidth = 2.0
        priorLineStyle.lineColor = CPTColor.lightGray()
        priorPlot.dataLineStyle = priorLineStyle
        
        //priorPlot.interpolation = CPTScatterPlotInterpolation.Linear
        priorPlot.interpolation = CPTScatterPlotInterpolation.stepped
        
        priorPlot.dataSource = self
        priorPlot.delegate = self
        
        
        graph.add(priorPlot)
        
        
        
        let postPlot = CPTScatterPlot(frame:graph.bounds)
        postPlot.identifier = "PostPlot" as (NSCoding & NSCopying & NSObjectProtocol)?
        let postLineStyle = CPTMutableLineStyle()
        postLineStyle.miterLimit = 1.0
        postLineStyle.lineWidth = 2.0
        postLineStyle.lineColor = CPTColor.blue()
        postPlot.dataLineStyle = postLineStyle
        
        postPlot.dataSource = self
        postPlot.delegate = self
        
        
        graph.add(postPlot)
        
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        skView.nodesController = self.nodesController
        skView.modelTreeController = self.modelTreeController
        scene.modelTreeController = self.modelTreeController
        scene.nodesController = self.nodesController
        
        let options: NSKeyValueObservingOptions = [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old]
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
                nodeDetailPriorView.isHidden = true
                nodeDetailCPTView.isHidden = false

                
                graph.add(priorPlot)
                graph.remove(priorPlot)
                
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
                nodeDetailCPTView.isHidden = true
                nodeDetailPriorView.isHidden = false
                
                
                switch priorDist{
                case 0: //point/expert
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = true
                    priorV2Field.isHidden = true
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.linear
                   
                case 2: // gaussian
                    
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = false
                    priorV2Field.isHidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.curved
                    
                    
                case 3: //beta
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = false
                    priorV2Field.isHidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 10.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 10.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.curved
                    

                    
                    
                case 4: //gamma
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = false
                    priorV2Field.isHidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 10.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 10.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.curved
                    
                    
                case 5: //priorpost
                    priorV1Slider.isHidden = true
                    priorV1Field.isHidden = true
                    priorV2Slider.isHidden = true
                    priorV2Field.isHidden = true
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                default:
                    priorV1Slider.isHidden = false
                    priorV1Field.isHidden = false
                    priorV2Slider.isHidden = false
                    priorV2Field.isHidden = false
                    priorV1Slider.minValue = 0.0
                    priorV1Slider.maxValue = 1.0
                    priorV2Slider.minValue = 0.0
                    priorV2Slider.maxValue = 1.0
                    
                    priorPlot.interpolation = CPTScatterPlotInterpolation.histogram
                    
                }

                
                graph.add(priorPlot)
                
            }
            

            
            if curNode.postCount != nil {
                
                let postCount = NSKeyedUnarchiver.unarchiveObject(with: curNode.value(forKey: "postCount") as! Data) as! [Int]
                // println("postCount \(postCount)")
                var postData = [NSNumber]()
                var curtop = 0
                for thisPost in postCount {
                    if (curtop < thisPost) {
                        curtop = thisPost
                    }
                }
                for thisPost : Int in postCount {
                    postData.append((Double(thisPost)/Double(curtop)) as NSNumber)
                }
                
                
                
                self.dataForChart = postData
            }
            else {
                
                self.dataForChart = [Double](repeating: 0.0, count: 100) as [NSNumber]
            }
            
            if curNode.priorCount != nil {
                let priorCount = NSKeyedUnarchiver.unarchiveObject(with: curNode.value(forKey: "priorCount") as! Data) as! [Int]
              //   println("priorCount \(priorCount)")
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
            }
            else {
                
                self.priorDataForChart = [Double](repeating: 0.0, count: 100) as [NSNumber]
            }
            

            
        }
            
        else { //no node, just move graph off view
            

            
            
            priorDist = 0
            V1 = -10000.0
            V2 = -10000.0
            self.dataForChart = [Double](repeating: -10000.0, count: 100) as [NSNumber]
        }
        
        cptTableView.delegate = self
        cptTableView.dataSource = self
        cptTableView.reloadData()
        cptTableContainer.documentView = cptTableView
        cptTableContainer.hasVerticalScroller = true
        cptTableContainer.translatesAutoresizingMaskIntoConstraints = false
        nodeDetailCPTView.addSubview(cptTableContainer)
        let topc = NSLayoutConstraint(item: cptTableContainer, attribute: .top, relatedBy: .equal, toItem: nodeDetailCPTView, attribute: .top, multiplier: 1.0, constant: 0.0)
        let botc = NSLayoutConstraint(item: cptTableContainer, attribute: .bottom, relatedBy: .equal, toItem: nodeDetailCPTView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        let trailc = NSLayoutConstraint(item: cptTableContainer, attribute: .trailing, relatedBy: .equal, toItem: nodeDetailCPTView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let leadc = NSLayoutConstraint(item: cptTableContainer, attribute: .leading, relatedBy: .equal, toItem: nodeDetailCPTView, attribute: .leading, multiplier: 1.0, constant: 0.0)
        
        nodeDetailCPTView.addConstraints([trailc, leadc, topc, botc])
        
        graph.reloadData()
        
        
        
        
    }
    
    
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        
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
                    return gaussian(V1, sigma: V2, x: nidx) as AnyObject?
                    
                case 3: //beta
                    return beta(V1, b: V2, x: nidx) as AnyObject?
                    
                case 4: //gamma
                    
                    
                    return gamma(V1, b:V2, x:nidx) as AnyObject?
                    
                case 5: //priorPost
                    // println(self.priorDataForChart[Int(idx)] as NSNumber)
                    return self.priorDataForChart[Int(idx)] as NSNumber
                    
                default:
                    return 0 as AnyObject?
                }
                
                
                
                
            }
                
            else if(plot.identifier!.isEqual("PostPlot")){
                
                return self.dataForChart[Int(idx)] as NSNumber
            }
        }
        
        
        return 0 as AnyObject?
    }
    

    
    
   
    
    
    //****** distn fxns
    func gaussian(_ mu: Double, sigma: Double, x: Double) -> Double {
        let n : Double = sigma * 2.0 * sqrt(M_PI)
        let p : Double = exp( -pow(x-mu, 2.0) / (2.0 * pow(sigma, 2.0)))
        return p/n
    }
    
    func beta(_ a: Double, b: Double, x: Double) -> Double {
        
        let betanorm : Double = tgamma((a+b))/(tgamma(a)+tgamma(b))
        
        let secondhalf : Double = pow(x, (a-1))*pow((1-x),(b-1))
        
        return betanorm * secondhalf
    }
    
    func gamma(_ a: Double, b: Double, x: Double) -> Double {//gamma distribution, not funciotn
        let numerator = pow(b,a) * pow(x, (a-1)) * pow(M_E,-(x*b))
        return numerator/tgamma(a)
    }
    //******
    

    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
      //  println("observed \(object) \(change) \(context)")
        let keyPathStr : String = keyPath! //FIXME this was added becaiuse in swift 2.0 the fxn was changed so that keyPath was a String?
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
        
        self.reloadData()
    }
    
    
//tableview data source 
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            if (curNode.value(forKey: "cptArray")) == nil {
                curNode.CPT()
            }
            let cptarray = NSKeyedUnarchiver.unarchiveObject(with: curNode.value(forKey: "cptArray") as! Data) as! [cl_float]
            return cptarray.count
        }
        return 0
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        
        if (curNode.value(forKey: "cptArray")) == nil {
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
                let cptarray = NSKeyedUnarchiver.unarchiveObject(with: curNode.value(forKey: "cptArray") as! Data) as! [cl_float]
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
                let revstr = String(str.characters.reversed())
                //and revrse
                
                let index = tableView.tableColumns.index(of: tableColumn!)
                //print ("\(index): \(revstr)")
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
 

}
