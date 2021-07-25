//
//  PlexusModelViewController.swift
//  Plexus
//
//  Created by matt on 10/15/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Cocoa

class PlexusModelViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {

    let appDelegate : AppDelegate = NSApplication.shared.delegate as! AppDelegate
    @objc var moc : NSManagedObjectContext!
    @IBOutlet dynamic var modelTreeController : NSTreeController!
    @IBOutlet weak var modelOutlineView : NSOutlineView!
    
    var firstrun = true
    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        moc = appDelegate.persistentContainer.viewContext
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        modelOutlineView.registerForDraggedTypes(convertToNSPasteboardPasteboardTypeArray(registeredTypes))
        
        let options: NSKeyValueObservingOptions = [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old]
        modelTreeController.addObserver(self, forKeyPath: "arrangedObjects", options: options, context: nil)
        
    }
    
    
    override func viewWillDisappear() {
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: modelTreeController.selectionIndexPaths), forKey: "plexusModelSelectionIndexPaths")
    }

    //NSOutlineView delegate functions
    
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {

        if(outlineView == modelOutlineView){
            
            return .copy
        }

        return NSDragOperation()

    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        

        
        let pboard : NSPasteboard = info.draggingPasteboard
        let kString : String = kUTTypeURL as String
        let data : Data = pboard.data(forType: convertToNSPasteboardPasteboardType(kString))!
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

    
    /**
     Creates a new Model at index path and inserts into modelTreeController.
     
     - Parameter sender: Calling function.

     */
    @IBAction func addModel(_ sender : AnyObject){

        var inPath = IndexPath()
        if let curPath : IndexPath = modelTreeController.selectionIndexPath {
            inPath = curPath
        }
        
        
        let newModel : Model = Model(entity: NSEntityDescription.entity(forEntityName: "Model", in: self.moc)!, insertInto: self.moc)
        newModel.setValue("New Model", forKey: "name")
        newModel.setValue(NSNumber.init(floatLiteral: -Double.infinity), forKey: "score")
        
        modelTreeController.insert(newModel, atArrangedObjectIndexPath: inPath)
        
    }
    
    
    /**
     Creates a new Model that is the child of the selected Model. Uses Model's copySelf function.
     
     - Parameter sender: Calling function.
     
     */
    @IBAction func childModel(_ sender : AnyObject){
        
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        
        if let curPath : IndexPath = modelTreeController.selectionIndexPath {
            let newPath :IndexPath = curPath.appending(curModel.children.count)
            
            let newModel : Model = curModel.copySelf(moc: self.moc, withEntries: true)
            newModel.setValue(NSNumber.init(floatLiteral: -Double.infinity), forKey: "score")
            
            modelTreeController.insert(newModel, atArrangedObjectIndexPath: newPath)
            let copyName : String = curModel.name + " copy"
            newModel.setValue(copyName, forKey: "name")

        }
        
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let yerob = object as? NSTreeController {
            if yerob == modelTreeController {
                if firstrun {
                    let savedSIData = UserDefaults.standard.data(forKey: "plexusModelSelectionIndexPaths")
                    if let savedSI = NSKeyedUnarchiver.unarchiveObject(with: savedSIData ?? Data()) {
                        _ = modelTreeController.setSelectionIndexPaths(savedSI as! [IndexPath])
                    }
                    firstrun = false
                }
            }
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
