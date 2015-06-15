//
//  PlexusEntryDetailViewController.swift
//  Plexus
//
//  Created by matt on 6/9/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa
import MapKit

class PlexusEntryDetailViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTabViewDelegate {
    
    
    var moc : NSManagedObjectContext!
    dynamic var entryTreeController : NSTreeController!
    
    @IBOutlet dynamic var traitsController : NSArrayController!
    @IBOutlet weak var traitsTableView : NSTableView!
    
    @IBOutlet var detailTabView: NSTabView!
    
    @IBOutlet var textView: NSTextView!
    
    @IBOutlet var mapView : MKMapView!

    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        super.init(coder: aDecoder)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let kString : String = kUTTypeURL as String
        var registeredTypes:[String] = [kString]
        traitsTableView.registerForDraggedTypes(registeredTypes)
        traitsTableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: true)
        traitsTableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
        traitsTableView.verticalMotionCanBeginDrag = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        //self.markMap()
        
    }
    

    
    
    //TableView Delegate fxns
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return traitsController.arrangedObjects.objectAtIndex(row)
    }
    
    func tableView(aTableView: NSTableView,
        writeRowsWithIndexes rowIndexes: NSIndexSet,
        toPasteboard pboard: NSPasteboard) -> Bool
    {
        
        if ((aTableView == traitsTableView))
        {
            
            
            let selectedRow = rowIndexes.firstIndex
            let selectedObject: AnyObject = traitsController.arrangedObjects.objectAtIndex(selectedRow)
            
            let mutableArray : NSMutableArray = NSMutableArray()
            mutableArray.addObject(selectedObject.objectID.URIRepresentation())
            
            
            let data : NSData = NSKeyedArchiver.archivedDataWithRootObject(mutableArray)
            
            let kString : String = kUTTypeURL as String
            pboard.setData(data, forType: kString)
            return true
            
            
            
        }
        else
        {
            return false
        }
    }
    
    
    //Tab View Delegate
    func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        self.markMap()
    }
    
    //Map
    func markMap() {

        
        let mapEntries : [Entry] = entryTreeController.selectedObjects as! [Entry]
        if(mapEntries.count > 0){
            let mapEntry : Entry =  mapEntries[0]
            
            
            var location = CLLocationCoordinate2D(
                latitude: mapEntry.latitude,
                longitude: mapEntry.longitude
            )
            var span = MKCoordinateSpanMake(1, 1)
            var region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            
            mapView.addAnnotation(MKPlacemark(coordinate: location, addressDictionary:nil))
            

        }
        
    }
    
    func mocDidChange(notification: NSNotification){
        //  println("moc changed in map view")
        //  markMap()
        
    }
    
    
}
