//
//  PlexusEntryViewController.swift
//  Plexus
//
//  Created by matt on 10/9/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusEntryViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {

    var moc : NSManagedObjectContext!
   dynamic var datasetController : NSArrayController!
    @IBOutlet dynamic var entryTreeController : NSTreeController!
    @IBOutlet weak var entryOutlineView : NSOutlineView!


    
    
    
    
    required init?(coder aDecoder: NSCoder)
    {

        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext

        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
    
        var registeredTypes:[String] = [kUTTypeURL]
        entryOutlineView.registerForDraggedTypes(registeredTypes)
        entryOutlineView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: true)
        entryOutlineView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
        entryOutlineView.verticalMotionCanBeginDrag = true

    }
    
    
    @IBAction func addEntry(sender : AnyObject){
        println("add entry")
        
    }
    
    @IBAction func removeEntry(sender : AnyObject){
        println("remove entry")
        
    }
    
    @IBAction func addChildEntry(sender : AnyObject){
        println("add child entry")
        
    }

    //nsoutlineview delegate methods
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
       // println("outlineview viewfortabelciom")
        var thisView : NSTableCellView = outlineView.makeViewWithIdentifier("Entry Cell", owner: self) as NSTableCellView
        
        

        var thisEntry = item.representedObject

        
        return thisView
        
    }
    

    
    
    
    
    func outlineView(outlineView: NSOutlineView, writeItems items: [AnyObject], toPasteboard pasteboard: NSPasteboard) -> Bool {
        //println("writeItems")
        let mutableArray : NSMutableArray = NSMutableArray()
        
        for object : AnyObject in items{
            if let treeItem : AnyObject? = object.representedObject!{
                mutableArray.addObject(treeItem!.objectID.URIRepresentation())
            }
        }
        
        let data : NSData = NSKeyedArchiver.archivedDataWithRootObject(mutableArray)
        pasteboard.setData(data, forType: kUTTypeURL)
        
        return true
    }



    
}
