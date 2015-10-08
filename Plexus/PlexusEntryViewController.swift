//
//  PlexusEntryViewController.swift
//  Plexus
//
//  Created by matt on 10/9/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import CoreServices


class PlexusEntryViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {

    var moc : NSManagedObjectContext!
   dynamic var datasetController : NSArrayController!
    @IBOutlet dynamic var entryTreeController : NSTreeController!
    @IBOutlet weak var entryOutlineView : NSOutlineView!


    
    
    
    
    required init?(coder aDecoder: NSCoder)
    {

        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext

        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        
    
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        entryOutlineView.registerForDraggedTypes(registeredTypes)
        entryOutlineView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: true)
        entryOutlineView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
        entryOutlineView.verticalMotionCanBeginDrag = true

    }
    
    
    @IBAction func addEntry(sender : AnyObject){
        print("add entry")
        
    }
    
    @IBAction func removeEntry(sender : AnyObject){
        print("remove entry")
        
    }
    
    @IBAction func addChildEntry(sender : AnyObject){
        print("add child entry")
        
    }

    //nsoutlineview delegate methods
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
       // println("outlineview viewfortabelciom")
        let thisView : NSTableCellView = outlineView.makeViewWithIdentifier("Entry Cell", owner: self) as! NSTableCellView
        
        

      //  var thisEntry = item.representedObject

        
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
        let kString : String = kUTTypeURL as String
        pasteboard.setData(data, forType: kString)
        
        return true
    }



    
}
