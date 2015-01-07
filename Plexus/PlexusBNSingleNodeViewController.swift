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
        
        var graph = CPTXYGraph(frame:self.graphView.bounds)
        self.graphView.hostedGraph = graph
        
        graph.title = "Graph Title"
       // graph.axisSet = nil
        
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
       // var xAxis = CPTXYAxis(frame:self.graphView.bounds)
      //  var yAxis = CPTXYAxis(frame:self.graphView.bounds)
        axisSet.xAxis.majorTickLength = 0.5
        axisSet.yAxis.majorTickLength = 0.5

        
        graph.axisSet = axisSet
        
        

            
        
        /*
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
        CPTXYAxis *x = axisSet.xAxis;
        x.majorIntervalLength = CPTDecimalFromString(@"0.5");
        x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0.0");
        x.minorTicksPerInterval = 2;
        
        CPTXYAxis *y = axisSet.yAxis;
        y.majorIntervalLength = CPTDecimalFromString(@"0.5");
        y.minorTicksPerInterval = 5;
        y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0.0");
            */
        
        
        var priorPlot = CPTScatterPlot(frame:graph.bounds)
        priorPlot.identifier = "PriorPlot"
        var priorLineStyle = CPTMutableLineStyle()
        priorLineStyle.miterLimit = 1.0
        priorLineStyle.lineWidth = 3.0
        priorLineStyle.lineColor = CPTColor.greenColor()
        priorPlot.dataLineStyle = priorLineStyle
        
        priorPlot.interpolation = CPTScatterPlotInterpolation(rawValue: 3)! //curved
        
        priorPlot.dataSource = self
        priorPlot.delegate = self
        
        //FIXME dummy data
        self.dataForChart = [0.05, 0.4, 0.2, 0.08]

        
        graph.addPlot(priorPlot)

        


        

    }
    /*
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return 4
    }

    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: UInt) -> NSNumber! {
        return idx
    }
*/
    
    
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
       // println("self.dataForChart.count: \(UInt(self.dataForChart.count))");
        return UInt(self.dataForChart.count)
    
    }
    
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: Int) -> NSNumber! {
        println("numberForPlot: \(self.dataForChart[idx])")
        return self.dataForChart[idx] as NSNumber
    }


    
}
