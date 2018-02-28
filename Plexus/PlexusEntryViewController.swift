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
    dynamic var modelTreeController : NSTreeController!
    @IBOutlet dynamic var entryTreeController : NSTreeController!
    @IBOutlet weak var entryOutlineView : NSOutlineView!


    
    required init?(coder aDecoder: NSCoder)
    {

        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext

        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        
    
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        entryOutlineView.register(forDraggedTypes: registeredTypes)
        entryOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        entryOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        entryOutlineView.verticalMotionCanBeginDrag = true
        
        
        
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
        entryTreeController.sortDescriptors = [sortDescriptor]


    }
    
    
    @IBAction func setScopeEntry(_ sender : AnyObject) {

        
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        let curEntries : [Entry] = entryTreeController.selectedObjects as! [Entry]
        if (curEntries.count > 0){
            let curEntry : Entry = curEntries[0]
            curEntry.addScopeObject(curModel)
            curModel.scope = curEntry
        }
    }
    
    @IBAction func unScope(_ sender : AnyObject) {

        
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        let curScoped : NodeLink = curModel.scope
        curScoped.scope = Set<Model>() as NSSet
        
 
    }
    


    //nsoutlineview delegate methods
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        let thisView : NSTableCellView = outlineView.make(withIdentifier: "Entry Cell", owner: self) as! NSTableCellView

        return thisView
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, mouseDownInHeaderOf tableColumn: NSTableColumn) {
        
        let sds = entryTreeController.sortDescriptors
        if(sds.count > 0){
        
            let sd = entryTreeController.sortDescriptors[0]

            let sortDescriptor = NSSortDescriptor(key: "name", ascending: !sd.ascending, selector: #selector(NSString.localizedStandardCompare(_:)))

            entryTreeController.sortDescriptors = [sortDescriptor]
            
        }
        else {
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))) //This should not happen, but default to true just in case sortDescriptiors empty
            
            entryTreeController.sortDescriptors = [sortDescriptor]
        }

    }


    
    
    
    
    func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {

        let mutableArray : NSMutableArray = NSMutableArray()
        
        for object in items{
            if let treeItem : AnyObject? = (object as AnyObject).representedObject!{
                mutableArray.add(treeItem!.objectID.uriRepresentation())
            }
        }
        
        let data : Data = NSKeyedArchiver.archivedData(withRootObject: mutableArray)
        let kString : String = kUTTypeURL as String
        pasteboard.setData(data, forType: kString)
        
        return true
    }



    
}
