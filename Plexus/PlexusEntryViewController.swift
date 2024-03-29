//
//  PlexusEntryViewController.swift
//  Plexus
//
//  Created by matt on 10/9/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Cocoa
import CoreServices


class PlexusEntryViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    let appDelegate : AppDelegate = NSApplication.shared.delegate as! AppDelegate
    @objc var moc : NSManagedObjectContext!
    @objc dynamic var modelTreeController : NSTreeController!
    @IBOutlet dynamic var entryController : NSArrayController!
    @IBOutlet weak var entryTableView : NSTableView!

    
    required init?(coder aDecoder: NSCoder)
    {

        moc = appDelegate.persistentContainer.viewContext

        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        entryTableView.registerForDraggedTypes(convertToNSPasteboardPasteboardTypeArray(registeredTypes))
        entryTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        entryTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        entryTableView.verticalMotionCanBeginDrag = true

    }
    

    /**
     Removes selected Entries from current Model. If an Entry is no longer attached to any Model, it is deleted from the MOC.
     
     - Parameter sender: Calling function.

     */
    @IBAction func removeEntries(_ sender: AnyObject) {
        
        let curModels : [Model] = modelTreeController?.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        if(curModel.complete == true){
            return
        }
        
        let curEntries : [Entry] = entryController.selectedObjects as! [Entry]
        for curEntry in curEntries {
            curModel.removeAnEntryObject(curEntry)
            curEntry.removeAModelObject(curModel)
            //If the Entry is no longer associated with any models, delete from data store
            if curEntry.model.count < 1 {
                moc.delete(curEntry)
            }
        }
        
        do {
            try moc.save()
        } catch let error as NSError {
            print(error)
        }
        

    }

    // MARK: - TableView Delegate fxns
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {

        let entryArray : NSArray = entryController.arrangedObjects as! NSArray
        return entryArray.object(at: row)
    }
    
    func tableView(_ aTableView: NSTableView,
                   writeRowsWith rowIndexes: IndexSet,
                   to pboard: NSPasteboard) -> Bool
    {

        if ((aTableView == entryTableView))
        {
            
            let entryArray : NSArray = entryController.arrangedObjects as! NSArray
            print (entryArray.count)
            
            
            let mutableArray : NSMutableArray = NSMutableArray()
            
            for rowIndex in rowIndexes {

                 let selectedObject : AnyObject = entryArray.object(at: rowIndex) as AnyObject
                mutableArray.add(selectedObject.objectID.uriRepresentation())
            }


            
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
