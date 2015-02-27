//
//  PlexusTraitViewController.swift
//  Plexus
//
//  Created by matt on 10/21/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusTraitViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

     var moc : NSManagedObjectContext!

    dynamic var entryTreeController : NSTreeController!
    @IBOutlet dynamic var traitsController : NSArrayController!
    @IBOutlet weak var traitsTableView : NSTableView!
    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var registeredTypes:[String] = [kUTTypeURL]
        traitsTableView.registerForDraggedTypes(registeredTypes)
        traitsTableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: true)
        traitsTableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
        traitsTableView.verticalMotionCanBeginDrag = true
        
    }
    
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        println("obj for table column")
        return traitsController.arrangedObjects.objectAtIndex(row)
    }
    
    func tableView(aTableView: NSTableView,
        writeRowsWithIndexes rowIndexes: NSIndexSet,
        toPasteboard pboard: NSPasteboard) -> Bool
    {
        println("write rows")
        if ((aTableView == traitsTableView))
        {
            var data:NSData = NSKeyedArchiver.archivedDataWithRootObject(rowIndexes)
            var registeredTypes:[String] = [NSStringPboardType]
            pboard.declareTypes(registeredTypes, owner: self)
            pboard.setData(data, forType: NSStringPboardType)
            return true
            
        }
        else
        {
            return false
        }
    }


}
