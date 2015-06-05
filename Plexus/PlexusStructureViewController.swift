//
//  PlexusStructureViewController.swift
//  Plexus
//
//  Created by matt on 5/12/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa
import CoreData

class PlexusStructureViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    var moc : NSManagedObjectContext!
    dynamic var datasetController : NSArrayController!
    @IBOutlet var structurePopup : NSPopUpButton!
    @IBOutlet var structureEntriesController : NSArrayController!
    @IBOutlet var structureController : NSArrayController!
    @IBOutlet weak var structureTableView : NSTableView!
    @IBOutlet weak var structureEntriesTableView : NSTableView!
    
    
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
        structureTableView.registerForDraggedTypes(registeredTypes)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: true)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
        structureTableView.verticalMotionCanBeginDrag = true
        
        structureEntriesTableView.registerForDraggedTypes(registeredTypes)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.None, forLocal: true)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.None, forLocal: false)
    }
    
    //NSTableView Delegate for dragging
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
       // println("object value from \(tableView)")
        
        if(tableView == structureEntriesTableView){
            return structureEntriesController.arrangedObjects.objectAtIndex(row)
        }
        else if(tableView == structureTableView){
            return structureController.arrangedObjects.objectAtIndex(row)
        }
        
        return nil
    }
    
    func tableView(aTableView: NSTableView,
        writeRowsWithIndexes rowIndexes: NSIndexSet,
        toPasteboard pboard: NSPasteboard) -> Bool
    {

        
        if ((aTableView == structureTableView))
        {
            
            
            let selectedRow = rowIndexes.firstIndex
            let selectedObject: AnyObject = structureController.arrangedObjects.objectAtIndex(selectedRow)
            
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
    
    
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
       // println("valiudate \(tableView)")
        if(tableView == structureEntriesTableView){

            return .Copy
        }
        else if(tableView == structureTableView){

            return .None
        }
        return .None
    }

    
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {

        
        if(tableView == structureEntriesTableView){
            let pboard : NSPasteboard = info.draggingPasteboard()
            let types : NSArray = pboard.types!
            
            
            let kString : String = kUTTypeURL as String
            let data : NSData = pboard.dataForType(kString)!
            let draggedArray : NSArray = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! NSArray
            
            let curStructures : [Structure] = structureController.selectedObjects as! [Structure]
            var curStructure = curStructures[0]
            
            
            
            for object : AnyObject in draggedArray{
                
                let mourl : NSURL = object as! NSURL
                
                if let id : NSManagedObjectID? = moc.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(mourl){
                    
                    let mo : NodeLink = moc.objectWithID(id!) as! NodeLink
                    
                    if (mo.entity.name == "Entry"){
                        let curEntry = mo as! Entry
                        
                        //add it to structure.entry
                        curStructure.addEntryObject(curEntry)
                        curEntry.addStructureObject(curStructure)
                        
                    }
                    
                }
                
            }
            
        }
        
        return true
    }
    
  
    
}
