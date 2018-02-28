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
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        structureTableView.register(forDraggedTypes: registeredTypes)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        structureTableView.verticalMotionCanBeginDrag = true
        
        structureEntriesTableView.register(forDraggedTypes: registeredTypes)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation(), forLocal: true)
        structureTableView.setDraggingSourceOperationMask(NSDragOperation(), forLocal: false)
    }
    
    
    @IBAction func setScopeStructrure(_ sender : AnyObject) {

        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        let curStructures : [Structure] = structureController.selectedObjects as! [Structure]
        if curStructures.count > 0 {
            let curStructure : Structure = curStructures[0]
            curStructure.addScopeObject(curModel)
            curModel.scope = curStructure
        }
 
    }
    
    //NSTableView Delegate for dragging
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
       // println("object value from \(tableView)")
        
        if(tableView == structureEntriesTableView){
            let secArray : NSArray = structureEntriesController.arrangedObjects as! NSArray
            return secArray.object(at: row)
        }
        else if(tableView == structureTableView){
            let secArray : NSArray = structureController.arrangedObjects as! NSArray
            return secArray.object(at: row)
        }
        
        return nil
    }
    
    func tableView(_ aTableView: NSTableView,
        writeRowsWith rowIndexes: IndexSet,
        to pboard: NSPasteboard) -> Bool
    {

        
        if ((aTableView == structureTableView))
        {
            
            
            let selectedRow = rowIndexes.first
            let secArray : NSArray = structureController.arrangedObjects as! NSArray
            let selectedObject: AnyObject = secArray.object(at: selectedRow!) as AnyObject

            
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
    
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
       // println("valiudate \(tableView)")
        if(tableView == structureEntriesTableView){

            return .copy
        }
        else if(tableView == structureTableView){

            return NSDragOperation()
        }
        return NSDragOperation()
    }

    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {

        
        if(tableView == structureEntriesTableView){
            let pboard : NSPasteboard = info.draggingPasteboard()

            
            
            let kString : String = kUTTypeURL as String
            let data : Data = pboard.data(forType: kString)!
            let draggedArray : NSArray = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSArray
            
            let curStructures : [Structure] = structureController.selectedObjects as! [Structure]
            var curStructure : Structure!
            
            if(curStructures.count < 1){

                curStructure = Structure(entity: NSEntityDescription.entity(forEntityName: "Structure", in: self.moc)!, insertInto: self.moc)

                curStructure.setValue("newzero", forKey: "name")

            }
            else {
                curStructure = curStructures[0]
            }
            

            
            for object : AnyObject in draggedArray as [AnyObject] {
                
                let mourl : URL = object as! URL
                
                if let id : NSManagedObjectID = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: mourl){
                    
                    let mo : NodeLink = moc.object(with: id) as! NodeLink
                    
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
