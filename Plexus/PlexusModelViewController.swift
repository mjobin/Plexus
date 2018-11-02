//
//  PlexusModelViewController.swift
//  Plexus
//
//  Created by matt on 10/15/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Cocoa

class PlexusModelViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {

    var moc : NSManagedObjectContext!
    @IBOutlet dynamic var modelTreeController : NSTreeController!
    @IBOutlet weak var modelOutlineView : NSOutlineView!
    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.persistentContainer.viewContext
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        modelOutlineView.register(forDraggedTypes: registeredTypes)
    }

    //NSOutlineView delegate functions
    
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {

        if(outlineView == modelOutlineView){
            
            return .copy
        }

        return NSDragOperation()

    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        

        
        let pboard : NSPasteboard = info.draggingPasteboard()
        let kString : String = kUTTypeURL as String
        let data : Data = pboard.data(forType: kString)!
        let draggedArray : NSArray = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSArray

        
        if let dropTreeNode = item as? NSTreeNode {

            let dropObject = dropTreeNode.representedObject

            if let dropModel = dropObject as? Model {

                
                for object : AnyObject in draggedArray as [AnyObject] {

                    
                    let mourl : URL = object as! URL
                    
                    if let id : NSManagedObjectID = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: mourl){
                        
                        let mo = moc.object(with: id)
                        
                        if (mo.entity.name == "Entry"){
                            let curEntry = mo as! Entry


                            
                            dropModel.addAnEntryObject(curEntry)
                            curEntry.addAModelObject(dropModel)
                            
                        }
                        
                    }
                    
                    
                } //End for object...
                
            }
        }
        
        



        do {
            try moc.save()
        } catch let error as NSError {
            print(error)
        }
        
        return true
    }

    
    @IBAction func childModel(_ sender : AnyObject){
        
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        
        //print ("curmodel \(curModel)")
        
        
        if let curPath : IndexPath = modelTreeController.selectionIndexPath {
            let newPath :IndexPath = curPath.appending(curModel.children.count)
            
            let newModel : Model = curModel.copySelf(moc: self.moc, withEntries: true)
            
            // curModel.addChildObject(newModel)
            // newModel.setValue(curModel, forKey: "parent")
            modelTreeController.insert(newModel, atArrangedObjectIndexPath: newPath)
            let copyName : String = curModel.name + " copy"
            newModel.setValue(copyName, forKey: "name")

  
            
        }
        
        
    }
    
    
}
