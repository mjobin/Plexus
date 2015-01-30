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
    
    @IBOutlet var graphView : CPTGraphHostingView!
    @IBOutlet weak var visView: NSVisualEffectView!
    
    var priorDist = 0
    var V1 = 0.1
    var V2 = 0.5
    var dataForChart = [NSNumber]()
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
  


        
        visView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
        visView.material = NSVisualEffectMaterial.Dark
        visView.state = NSVisualEffectState.Active
        


        
        graph = CPTXYGraph(frame:self.graphView.bounds)
        self.graphView.hostedGraph = graph
        
        graph.title = "Graph Title"

        
        var plotSpace : CPTXYPlotSpace = graph.defaultPlotSpace as CPTXYPlotSpace
        plotSpace.allowsUserInteraction = false
      //  var xRange = plotSpace.xRange.mutableCopy() as CPTMutablePlotRange
       // var yRange = plotSpace.yRange.mutableCopy() as CPTMutablePlotRange
        
        
    //    xRange.setLengthFloat(1.2)
      //  yRange.setLengthFloat(1.2)
       // plotSpace.xRange = xRange
      //  plotSpace.yRange = yRange
        
        // Axes
        
        var axisSet = CPTXYAxisSet(frame:self.graphView.bounds)
        axisSet.xAxis.majorTickLength = 0.5
        axisSet.yAxis.majorTickLength = 0.5
        

        
        graph.axisSet = axisSet
        

        
        
        var priorPlot = CPTScatterPlot(frame:graph.bounds)
        priorPlot.identifier = "PriorPlot"
        var priorLineStyle = CPTMutableLineStyle()
        priorLineStyle.miterLimit = 1.0
        priorLineStyle.lineWidth = 2.0
        priorLineStyle.lineColor = CPTColor.greenColor()
        priorPlot.dataLineStyle = priorLineStyle
        
        priorPlot.interpolation = CPTScatterPlotInterpolation.Curved
        
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
        var curNodes : [BNNode] = nodesController.selectedObjects as [BNNode]
        if(curNodes.count>0) {
            curNode = curNodes[0]
            
            priorDist = Int(curNode.priorDistType)
            V1 = Double(curNode.priorV1)
            V2 = Double(curNode.priorV2)

            
        }
        
      //  println("reload Data")
        

        
        //FIXME dummy data
       // self.dataForChart = [0.3, 0.3, 0.1, 0.7]
        self.dataForChart = [Double](count: 100, repeatedValue: 0.5)
        /*
        var rmax = arc4random_uniform(100)+50
        
        for i in 1...rmax {
            self.dataForChart.append((CGFloat(arc4random()) /  CGFloat(UInt32.max)))
        }
        */
        
        graph.reloadData()
        
    }
    
    
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
       // println("self.dataForChart.count: \(UInt(self.dataForChart.count))");
        return UInt(self.dataForChart.count)
    
    }
    
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: Int) -> NSNumber! {
        
        var numrec = Double(numberOfRecordsForPlot(plot))

        if(fieldEnum == 0){//x
            return (Double(idx)/numrec)
        }
        if(fieldEnum == 1){ //y
            //FIXME dummy util i can get the real data
            

            
            if(plot.identifier.isEqual("PriorPlot")){
                // println(idx)
                
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
                   //// println(gaussian(dummyV1, sigma: dummyV2, x: nidx))
                    
                    return gaussian(V1, sigma: V2, x: nidx)
                    
                case 3: //gamma
                    // println("\(nidx) \(tgamma(nidx))")
                    
                    return tgamma(nidx)
                    
                default:
                    return 0
                }
                
                
                
                
            }
                
            else if(plot.identifier.isEqual("PostPlot")){
                return self.dataForChart[idx] as NSNumber
            }
        }


       // println("numberForPlot: \(self.dataForChart[idx] as NSNumber)")
       //
        return 0
        

    }
    
    func gaussian(mu: Double, sigma: Double, x: Double) -> Double {
        var result :Double =  exp ( -pow (x - mu, 2) / (2 * pow( sigma, 2)))
        return result / (sigma * 2 * sqrt(M_PI))
    }
    
    func gausstest(mu: Double, sigma: Double, x: Double) -> Double {
        var alpha : Double = 1 / (sigma * sqrt(2*M_PI))
        
        return alpha * exp ( -pow((x-mu), 2) / (2 * pow(sigma,2)))
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

    
}
