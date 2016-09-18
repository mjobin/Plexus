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
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        super.init(coder: aDecoder)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        traitsTableView.register(forDraggedTypes: registeredTypes)
        traitsTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        traitsTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        traitsTableView.verticalMotionCanBeginDrag = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        //self.markMap()
        
    }
    

    
    
    //TableView Delegate fxns
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let traitsArray : NSArray = traitsController.arrangedObjects as! NSArray
        return traitsArray.object(at: row)
 
       // return traitsController.arrangedObjects.objectAtIndex(row) FIXME beta compiler was complaing so i used the above clumsiness. replace?

    }
    
    func tableView(_ aTableView: NSTableView,
        writeRowsWith rowIndexes: IndexSet,
        to pboard: NSPasteboard) -> Bool
    {
        
        if ((aTableView == traitsTableView))
        {
            
            
            let selectedRow = rowIndexes.first
            
            let traitsArray : NSArray = traitsController.arrangedObjects as! NSArray
            let selectedObject : AnyObject = traitsArray.object(at: selectedRow!) as AnyObject
            // let selectedObject: AnyObject = traitsController.arrangedObjects.objectAtIndex(selectedRow) FIXME beta compiler was complaing so i used the above clumsiness. replace?

            
            let mutableArray : NSMutableArray = NSMutableArray()
            mutableArray.add(selectedObject.objectID.uriRepresentation())
            
            
            let data : Data = NSKeyedArchiver.archivedData(withRootObject: mutableArray)
            
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
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        self.markMap()
    }
    
    //Map
    func markMap() {

        
        let mapEntries : [Entry] = entryTreeController.selectedObjects as! [Entry]
        if(mapEntries.count > 0){
            let mapEntry : Entry =  mapEntries[0]
            
            
            let location = CLLocationCoordinate2D(
                latitude: mapEntry.latitude,
                longitude: mapEntry.longitude
            )
            let span = MKCoordinateSpanMake(1, 1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            
            mapView.addAnnotation(MKPlacemark(coordinate: location, addressDictionary:nil))
            

        }
        
    }
    
    func mocDidChange(_ notification: Notification){
        //  println("moc changed in map view")
        //  markMap()
        
    }
    
    
}
