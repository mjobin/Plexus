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
        

        
    }
    

    
    
    //TableView Delegate fxns
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let traitsArray : NSArray = traitsController.arrangedObjects as! NSArray
        return traitsArray.object(at: row)
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
    
    

    

    

    
    
}
