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
        
        var graph = CPTXYGraph(frame:self.graphView.bounds);
        self.graphView.hostedGraph = graph
        
        graph.title = "Graph Title"
        graph.axisSet = nil
        
        var plotSpace : CPTXYPlotSpace = graph.defaultPlotSpace as CPTXYPlotSpace
        plotSpace.allowsUserInteraction = false
        
        var priorPlot = CPTScatterPlot(frame:graph.bounds)
        
        priorPlot.dataSource = self
        priorPlot.delegate = self
        
        //FIXME dummy data
        self.dataForChart = [0.6, 0.4, 0.2, 0.08]
        
        graph.addPlot(priorPlot)
        

    }
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        println("self.dataForChart.count: \(UInt(self.dataForChart.count))");
        return UInt(self.dataForChart.count)
    
    }
    
    func numberForPlot(plot:CPTPlot, fieldEnum:Int, index:Int) -> AnyObject! {
        println("numberForPlot")
        return self.dataForChart[index] as NSNumber
    }
    
}
