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
        var xRange = plotSpace.xRange.mutableCopy() as CPTMutablePlotRange
        var yRange = plotSpace.yRange.mutableCopy() as CPTMutablePlotRange
        
        
        xRange.setLengthFloat(1.2)
        yRange.setLengthFloat(1.2)
        plotSpace.xRange = xRange
        plotSpace.yRange = yRange
        
        // Axes
        
        var axisSet = CPTXYAxisSet(frame:self.graphView.bounds)
        axisSet.xAxis.majorTickLength = 0.5
        axisSet.yAxis.majorTickLength = 0.5
        

        
        graph.axisSet = axisSet
        

        
        
        var priorPlot = CPTScatterPlot(frame:graph.bounds)
        priorPlot.identifier = "PriorPlot"
        var priorLineStyle = CPTMutableLineStyle()
        priorLineStyle.miterLimit = 1.0
        priorLineStyle.lineWidth = 3.0
        priorLineStyle.lineColor = CPTColor.greenColor()
        priorPlot.dataLineStyle = priorLineStyle
        
                priorPlot.interpolation = CPTScatterPlotInterpolation.Curved
        
        priorPlot.dataSource = self
        priorPlot.delegate = self
        

        

        
        graph.addPlot(priorPlot)

        


        

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
        }
        
        //println("reload Data")
        
        //FIXME dummy data
        self.dataForChart = [Double](count: 100, repeatedValue: 0.5)
        
        graph.reloadData()
        
    }
    
    
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
       // println("self.dataForChart.count: \(UInt(self.dataForChart.count))");
        return UInt(self.dataForChart.count)
    
    }
    
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: Int) -> NSNumber! {
        
        
        //FIXME dummy util i can get the real data
        var dummyPDist = 1
        var dummyV1 = 0.4
        var dummyV2 = 0.7
        
        if(plot.identifier.isEqual("PriorPlot")){
            //println(idx)
            
            let nidx = (Double(idx)/100)
            let nnidx = (Double(idx+1)/100)
            
            switch dummyPDist {
                
            case 0:  //point/expert
                if(nidx <= dummyV1 && nnidx > dummyV1){
                    println ("yus")
                    return 1
                }
                else {
                    return 0
                }
              
            case 1: //uniform
                if(nidx >= dummyV1 && nidx < dummyV2){
                    return 1
                }
                else {
                    return 0
                }
                
            default:
                return 0
            }

            

            
        }
        
       // println("numberForPlot: \(self.dataForChart[idx] as NSNumber)")
       // return self.dataForChart[idx] as NSNumber
        return 0
        

    }

    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
        switch (keyPath) {
        case("selectionIndex"):

            
            self.reloadData()
            
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    
}
