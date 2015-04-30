//
//  PlexusBNSingleNodeViewController.swift
//  Plexus
//
//  Created by matt on 1/4/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa



class PlexusBNSingleNodeViewController: NSViewController, CPTScatterPlotDataSource, CPTScatterPlotDelegate {
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    dynamic var nodesController : NSArrayController!
    
    
    var curNode : BNNode!
    var graph : CPTXYGraph!
    var priorPlot : CPTScatterPlot!
    
    @IBOutlet var graphView : CPTGraphHostingView!
    @IBOutlet weak var visView: NSVisualEffectView!
    
    @IBOutlet var priorTypePopup : NSPopUpButton!
    @IBOutlet var priorV1Slider : NSSlider!
    @IBOutlet var priorV1Field : NSTextField!
    @IBOutlet var priorV2Slider : NSSlider!
    @IBOutlet var priorV2Field : NSTextField!
    
    @IBOutlet var scopeLabel : NSTextField!
    @IBOutlet var scopePopup : NSPopUpButton!
    @IBOutlet var numericButton : NSButton!
    @IBOutlet var dataLabel : NSTextField!
    @IBOutlet var dataPopup : NSPopUpButton!
    @IBOutlet var dataSubPopup : NSPopUpButton!
    
    var priorDist = 0
    var V1 = 0.1
    var V2 = 0.5
    var dataForChart = [NSNumber]()
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
  
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "mocDidChange:", name: NSManagedObjectContextObjectsDidChangeNotification, object: moc)


        
        visView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
        visView.material = NSVisualEffectMaterial.Dark
        visView.state = NSVisualEffectState.Active
        


        
        graph = CPTXYGraph(frame:self.graphView.bounds)
        self.graphView.hostedGraph = graph
        
        
        var titleStyle = graph.titleTextStyle.mutableCopy() as! CPTMutableTextStyle
        titleStyle.fontName = "HelveticaNeue-Bold"
        titleStyle.fontSize = 18.0
        titleStyle.color = CPTColor.whiteColor()
        graph.titleTextStyle = titleStyle
        
        graph.title = ""

        graph.paddingTop = 10.0
        graph.paddingBottom = 10.0
        graph.paddingLeft = 10.0
        graph.paddingRight = 10.0
        
        var plotSpace : CPTXYPlotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsUserInteraction = false
        
        
        var xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
        var yRange = plotSpace.yRange.mutableCopy() as! CPTMutablePlotRange
        
        xRange.length = 1.1
        yRange.length = 1.1


        plotSpace.xRange = xRange
        plotSpace.yRange = yRange
        

        
        // Axes

       // var axisSet = CPTXYAxisSet(frame:self.graphView.bounds)
        var axisSet = graph.axisSet as! CPTXYAxisSet
        axisSet.xAxis.axisConstraints = CPTConstraints.constraintWithUpperOffset(1.0)
        axisSet.yAxis.axisConstraints = CPTConstraints.constraintWithUpperOffset(1.0)
        axisSet.yAxis.axisConstraints = CPTConstraints.constraintWithLowerOffset(0.0)
        axisSet.xAxis.axisConstraints = CPTConstraints.constraintWithLowerOffset(0.0)
        axisSet.xAxis.tickDirection = CPTSign.Positive
        axisSet.yAxis.tickDirection = CPTSign.Positive


        
        axisSet.xAxis.majorTickLength = 0.5
        axisSet.xAxis.minorTicksPerInterval = 3
        axisSet.yAxis.majorTickLength = 0.5
        axisSet.yAxis.minorTicksPerInterval = 3
        graph.axisSet = axisSet
        
        
        priorPlot = CPTScatterPlot(frame:graph.bounds)
        priorPlot.identifier = "PriorPlot"
        var priorLineStyle = CPTMutableLineStyle()
        priorLineStyle.miterLimit = 1.0
        priorLineStyle.lineWidth = 2.0
        priorLineStyle.lineColor = CPTColor.lightGrayColor()
        priorPlot.dataLineStyle = priorLineStyle
        
        priorPlot.interpolation = CPTScatterPlotInterpolation.Linear
        
        priorPlot.dataSource = self
        priorPlot.delegate = self
        
        
        graph.addPlot(priorPlot)
        

        
        var postPlot = CPTScatterPlot(frame:graph.bounds)
        postPlot.identifier = "PostPlot"
        var postLineStyle = CPTMutableLineStyle()
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
        
        let options = NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old
        nodesController.addObserver(self, forKeyPath: "selectionIndex", options: options, context: nil)
      

    }
    
    func reloadData() {
        //Get selected node
        
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            println("\n\n*********\nreloadData \(curNode.nodeLink.name)")
            
            graph.title = curNode.nodeLink.name
            
            priorDist = Int(curNode.priorDistType)
            V1 = Double(curNode.priorV1)
            V2 = Double(curNode.priorV2)
            
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
                
                println("in reloadData datanames: \(curNode.dataName) \(curNode.dataSubName)")
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
                self.performSegueWithIdentifier("priorControls", sender: nil)
            }

     
            if curNode.postCount != nil {

                let postCount = NSKeyedUnarchiver.unarchiveObjectWithData(curNode.valueForKey("postCount") as! NSData) as! [Int]
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


            
            
        }
        
        else { //no node, just move graph off view
            
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
            
            
            priorDist = 0
            V1 = -10000.0
            V2 = -10000.0
            self.dataForChart = [Double](count: 100, repeatedValue: -10000.0)
        }
        
       
        
        graph.reloadData()
        
 
        //collect data for the prior and CPT controls
        self.collectData()


        
    }
    
    
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {

        return UInt(self.dataForChart.count)
    
    }
    
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject! {
        var numrec = Double(numberOfRecordsForPlot(plot))
        
        if(fieldEnum == 0){//x
            return (Double(idx)/numrec)
        }
        if(fieldEnum == 1){ //y
            
            if(plot.identifier.isEqual("PriorPlot")){
                
                
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
                    
                default:
                    return 0
                }
                
                
                
                
            }
                
            else if(plot.identifier.isEqual("PostPlot")){

                return self.dataForChart[Int(idx)] as NSNumber
            }
        }
        

        return 0
    }
    
    
    
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
    /*

    func chkDataName(inNode:BNNode) {
        println("in chkData name for node \(inNode.nodeLink.name)")
        
        switch(curNode.dataScope) {
        case 1:// self
            println("self \(curNode.nodeLink.name)")
            
            //from that object, select only the names of what is directly connected to it
            //only works for entries
            if(curNode.nodeLink.entity.name == "Entry"){
                let curEntry = curNode.nodeLink as! Entry
                switch(curNode.dataOp) {
                case 0: //trait

                    let theTraits = curEntry.trait
                    for thisTrait in theTraits {
                        dataNames.append(thisTrait.name)
                    }
                    
                }
            }
            
            
        }
        

        
        
    }
    */
    
    func collectData() {
        println("\ncollectData")
        self.dataPopup.removeAllItems()
        self.dataSubPopup.removeAllItems()
        self.dataPopup.enabled = true
        self.dataPopup.hidden = false
        self.dataSubPopup.hidden = false
        var dataNames = [String]()
        var dataSubNames = [String]()
        var err: NSError?
        
        
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            
            let request = NSFetchRequest(entityName: "Trait")
            

            switch(curNode.dataScope) {
            case 0://global // ALL entities matching this one's name
                
                println("global \(curNode.nodeLink.name)")
                dataNames.append(curNode.nodeLink.name)
                self.dataPopup.enabled = false
                self.dataPopup.hidden = true
                self.dataSubPopup.hidden = true
                
            
            case 1:// self
                println("self \(curNode.nodeLink.name)")
                
                //from that object, select only the names of what is directly connected to it
                //only works for entries
                if(curNode.nodeLink.entity.name == "Entry"){
                    let curEntry = curNode.nodeLink as! Entry
                    let theTraits = curEntry.trait
                    for thisTrait in theTraits {
                        dataNames.append(thisTrait.name)
                    }
                    
                }
                else if (curNode.nodeLink.entity.name == "Trait"){
                    dataNames.append(curNode.nodeLink.name)
                }
                else {
                    dataNames = [String]()
                    self.dataPopup.enabled = false
                }
                

            case 2: //children
                println("children \(curNode.nodeLink.name)")
                println(curNode.nodeLink.entity.name)
                
                
                if(curNode.nodeLink.entity.name == "Entry"){ //take this entry's children and look at it's children
                    
                    let predicate = NSPredicate(format: "entry.parent == %@", curNode.nodeLink as! Entry)
                    
                    request.resultType = .DictionaryResultType
                    request.predicate = predicate
                    request.returnsDistinctResults = true
                    request.propertiesToFetch = ["name"]
                    
                    if let fetch = moc.executeFetchRequest(request, error:&err) {
                        println("in entry to trait children fetch \(fetch)")
                        for obj  in fetch {
                            println(obj.valueForKey("name"))
                            dataNames.append(obj.valueForKey("name") as! String)
                            
                        }
                    }
                    
                }
                else if (curNode.nodeLink.entity.name == "Trait"){ //traits have no children, so change to global
                    dataNames = [String]()
                    self.dataPopup.enabled = false
                    
                }
                else {
                    dataNames = [String]()
                    self.dataPopup.enabled = false
                }
                
                

                
            default:
                
                println("collectData out of bounds")
                
            }
            
            self.dataPopup.addItemsWithTitles(dataNames)
            self.dataPopup.selectItemWithTitle(curNode.dataName)
            
            
            //now create pickable list of trait values
            switch(curNode.dataScope) {
                case 0://global list of all possible values of all traits with this name
                
                println("global")
                
                let predicate = NSPredicate(format: "name == %@", curNode.nodeLink.name)
                
                request.resultType = .DictionaryResultType
                request.predicate = predicate
                request.returnsDistinctResults = true
                request.propertiesToFetch = ["traitValue"]
                
                if let fetch = moc.executeFetchRequest(request, error:&err) {
                    println("Global sub fetch \(fetch)")
                    for obj  in fetch {
                        println(obj.valueForKey("traitValue"))
                        dataSubNames.append(obj.valueForKey("traitValue") as! String)
                        
                    }
                }
                
                
            case 1: //self
                println("self")
                if(curNode.nodeLink.entity.name == "Entry"){
                    
                    let predicate = NSPredicate(format: "entry == %@ AND name == %@", curNode.nodeLink, curNode.dataName)
                    request.predicate = predicate
                    request.returnsDistinctResults = true
                    request.propertiesToFetch = ["traitValue"]
                    
                    if let fetch = moc.executeFetchRequest(request, error:&err) {
                        println("Self sub fetch \(fetch)")
                        for obj  in fetch {
                            println(obj.valueForKey("traitValue"))
                            dataSubNames.append(obj.valueForKey("traitValue") as! String)
                            
                        }
                    }
                    
                }
                
                else if (curNode.nodeLink.entity.name == "Trait"){ //you obviously want this trait's own value, then
                    let curTrait = curNode.nodeLink as! Trait
                    dataSubNames.append(curTrait.traitValue)
                    
                    
                }
             
            case 2: //children
                println("children")
                if(curNode.nodeLink.entity.name == "Entry"){ //take this entry's children and look at it's children
                    
                    let predicate = NSPredicate(format: "entry.parent == %@ AND name == %@", curNode.nodeLink, curNode.dataName)
                    request.predicate = predicate
                    request.returnsDistinctResults = true
                    request.propertiesToFetch = ["traitValue"]
                    
                    if let fetch = moc.executeFetchRequest(request, error:&err) {
                        println("Children sub fetch \(fetch)")
                        for obj  in fetch {
                            println(obj.valueForKey("traitValue"))
                            dataSubNames.append(obj.valueForKey("traitValue") as! String)
                            
                        }
                    }
                    
                }
                
                else if (curNode.nodeLink.entity.name == "Trait"){ //traits cannot have children
                    dataSubNames = [String]()
                    self.dataSubPopup.enabled = false
                }
                
            default:
                println("out of bounds")
                
            }
            
            
            self.dataSubPopup.addItemsWithTitles(dataSubNames)
            self.dataSubPopup.selectItemWithTitle(curNode.dataSubName)
            
        }
        
       
        

        if(curNodes.count<1){
            self.dataPopup.hidden = true
            self.dataSubPopup.hidden = true
        }
        

    }

    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        //println(keyPath)
        switch (keyPath) {
        case("selectionIndex"):

            
            self.reloadData()
            
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func mocDidChange(notification: NSNotification){
        

        self.reloadData()

        
    }

    
}
