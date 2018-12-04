//
//  PlexusEntryDetailViewController.swift
//  Plexus
//
//  Created by matt on 6/9/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

import Cocoa

class PlexusEntryDetailViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTabViewDelegate {
    
    
    @objc var moc : NSManagedObjectContext!
    @objc dynamic var entryController : NSController!
    
    @IBOutlet dynamic var traitsController : NSArrayController!
    @IBOutlet weak var traitsTableView : NSTableView!
    
    @IBOutlet var detailTabView: NSTabView!
    
    @IBOutlet var textView: NSTextView!
    

    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.shared.delegate as! AppDelegate
        moc = appDelegate.persistentContainer.viewContext
        super.init(coder: aDecoder)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        traitsTableView.registerForDraggedTypes(convertToNSPasteboardPasteboardTypeArray(registeredTypes))
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
            pboard.setData(data, forType: convertToNSPasteboardPasteboardType(kString))
            return true
            
            
            
        }
        else
        {
            return false
        }
    }
    
  
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSPasteboardPasteboardTypeArray(_ input: [String]) -> [NSPasteboard.PasteboardType] {
	return input.map { key in NSPasteboard.PasteboardType(key) }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSPasteboardPasteboardType(_ input: String) -> NSPasteboard.PasteboardType {
	return NSPasteboard.PasteboardType(rawValue: input)
}
