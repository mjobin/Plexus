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
    dynamic var modelTreeController : NSTreeController!
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
        let registeredTypes:[String] = [kString]
        structureTableView.registerForDraggedTypes(registeredTypes)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: true)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
        structureTableView.verticalMotionCanBeginDrag = true
        
        structureEntriesTableView.registerForDraggedTypes(registeredTypes)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.None, forLocal: true)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.None, forLocal: false)
    }
    
    
    @IBAction func setScopeStructrure(sender : AnyObject) {

        
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        let curStructures : [Structure] = structureController.selectedObjects as! [Structure]
        let curStructure : Structure = curStructures[0]
        
        curStructure.addScopeObject(curModel)
        curModel.scope = curStructure
        

        
    }
    
    //NSTableView Delegate for dragging
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
       // println("object value from \(tableView)")
        
        if(tableView == structureEntriesTableView){
            let secArray : NSArray = structureEntriesController.arrangedObjects as! NSArray
            return secArray.objectAtIndex(row)
        }
        else if(tableView == structureTableView){
            let secArray : NSArray = structureController.arrangedObjects as! NSArray
            return secArray.objectAtIndex(row)
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
            let secArray : NSArray = structureController.arrangedObjects as! NSArray
            let selectedObject: AnyObject = secArray.objectAtIndex(selectedRow)

            
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

            
            
            let kString : String = kUTTypeURL as String
            let data : NSData = pboard.dataForType(kString)!
            let draggedArray : NSArray = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! NSArray
            
            let curStructures : [Structure] = structureController.selectedObjects as! [Structure]
            var curStructure : Structure!
            
            if(curStructures.count < 1){

                curStructure = Structure(entity: NSEntityDescription.entityForName("Structure", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)

                curStructure.setValue("newzero", forKey: "name")

            }
            else {
                curStructure = curStructures[0]
            }
            

            
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
