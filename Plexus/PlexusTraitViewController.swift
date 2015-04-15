//
//  PlexusTraitViewController.swift
//  Plexus
//
//  Created by matt on 10/21/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import CoreServices

class PlexusTraitViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

     var moc : NSManagedObjectContext!

    dynamic var entryTreeController : NSTreeController!
    @IBOutlet dynamic var traitsController : NSArrayController!
    @IBOutlet weak var traitsTableView : NSTableView!
    
    
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


}
