//
//  PlexusBNSKView.swift
//  Plexus
//
//  Created by matt on 2/27/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

import Cocoa
import SpriteKit
import CoreServices

class PlexusBNSKView: SKView {
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    dynamic var nodesController : NSArrayController!
    var vc : PlexusModelDetailViewController!
    
    required init?(coder aDecoder: NSCoder)
    {
        
        super.init(coder: aDecoder)
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        self.register(forDraggedTypes: registeredTypes)
        
        self.allowsTransparency = true
        self.ignoresSiblingOrder = true
        
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
    }


    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
               return NSDragOperation.copy
        
    }
    

    
    internal override func mouseDown(with theEvent: NSEvent) {
        
        self.scene?.mouseDown(with: theEvent)
    }
    
    internal override func mouseDragged(with theEvent: NSEvent) {
        self.scene?.mouseDragged(with: theEvent)
    }
    
    internal override func mouseUp(with theEvent: NSEvent) {
        
        self.scene?.mouseUp(with: theEvent)
    }
    
    internal override func rightMouseDown(with theEvent: NSEvent) {
            self.scene?.rightMouseDown(with: theEvent)
    }
 
    /*
    override func rightMouseDown(theEvent: NSEvent) {
        print("view rmd")
        let contextMenu = NSMenu.init(title: "whut")
        NSMenu.popUpContextMenu(contextMenu, withEvent: theEvent, forView: self)
    }
    */
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        if (curModels.count < 1){
            return false
        }
        let curModel : Model = curModels[0]
        if (curModel.complete == true){
            return false
        }
        

        
        
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
              
        let pboard : NSPasteboard = sender.draggingPasteboard()
       // let types : NSArray = pboard.types!
        
        
        let kString : String = kUTTypeURL as String
        let data : Data = pboard.data(forType: kString)!
        let draggedArray : NSArray = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSArray
        

        for object : AnyObject in draggedArray as [AnyObject] {
            
            let mourl : URL = object as! URL
            
            if let id : NSManagedObjectID = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: mourl){
                
                let mo = moc.object(with: id)
                
                if (mo.entity.name == "Trait"){
                    
                    self.addNode(object as! URL)
                    
                }
                
            }
            
            
           
        }

        return false
    }
    
    func addNode(_ mourl: URL){
        
        let newNode : BNNode = BNNode(entity: NSEntityDescription.entity(forEntityName: "BNNode", in: moc)!, insertInto: moc)

        if let id : NSManagedObjectID = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: mourl){
            
            let mo = moc.object(with: id)
            
            if (mo.entity.name == "Trait"){
                let moTrait = mo as! Trait

//                let curNodes : [BNNode] = nodesController.arrangedObjects as! [BNNode]
//                for curNode : BNNode in curNodes {
//                    if(curNode.name == moTrait.name) { //cannot add a node the same as an exisitng node
//                        return
//                    }
//                }
                newNode.setValue(moTrait.name, forKey: "name")
                newNode.setValue(moTrait.value, forKey: "value")

            }
        }
            
        

        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]

        
        curModel.addABNNodeObject(newNode)

        newNode.setValue(curModel, forKey: "model")
        
        let blankCount = [Int]()
        let blankArray = [Float]()
        newNode.postCount = blankCount
        newNode.priorCount = blankCount
        newNode.priorArray = blankArray
        newNode.postArray = blankArray
        newNode.cptFreezeArray = blankArray
        newNode.cptArray = blankArray


        do {
            try moc.save()
        } catch let error as NSError {
            self.print(error)
        }
 
    }
    
    

    
    
}
