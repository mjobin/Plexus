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
    
    let appDelegate : AppDelegate = NSApplication.shared.delegate as! AppDelegate
    var moc : NSManagedObjectContext!
    @objc dynamic var modelTreeController : NSTreeController!
    @objc dynamic var nodesController : NSArrayController!
    var vc : PlexusModelDetailViewController!
    
    required init?(coder aDecoder: NSCoder)
    {
        
        super.init(coder: aDecoder)
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        self.registerForDraggedTypes(convertToNSPasteboardPasteboardTypeArray(registeredTypes))
        
        self.allowsTransparency = true
        self.ignoresSiblingOrder = true
        
        

        moc = appDelegate.persistentContainer.viewContext
        

    }


    
    /**
     If dragging, operation always Copy.
     
     */
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
               return NSDragOperation.copy
    }
    
    /**
     These functions pass events down to the PlexusBNScene.

     */
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
 

    /**
     Disallows drag if current Model is complete or there is no Model.
     
     - Parameter sender: Calling function.
     
     - Returns: True if drag allowed.
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
    
    /**
     Drag operation results in a new BNNode being created.
     
     - Parameter sender: Calling function.
     
     - Returns: Always false.
     */
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
              
        let pboard : NSPasteboard = sender.draggingPasteboard
        
        
        let kString : String = kUTTypeURL as String
        let data : Data = pboard.data(forType: convertToNSPasteboardPasteboardType(kString))!
        let draggedArray : NSArray = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSArray
        

        for object : AnyObject in draggedArray as [AnyObject] {
            
            let mourl : URL = object as! URL
            
            if let id : NSManagedObjectID = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: mourl){
                
                let mo = moc.object(with: id)
                
                if (mo.entity.name == "Trait"){
                    self.addNode(inTrait: mo as? Trait)
                    
                }
                
            }
            
        }

        return false
    }
    

    /**
     Creates a new BNNode and adds it to the Model.
     
     - Parameter inTrait: Trait whose information attaches to the Node.
     
     */
    func addNode(inTrait: Trait?){
        
        let newNode : BNNode = BNNode(entity: NSEntityDescription.entity(forEntityName: "BNNode", in: moc)!, insertInto: moc)
        
        
        if inTrait == nil {
            newNode.setValue("New Name", forKey: "name")
            newNode.setValue("New Value", forKey: "value")
        }
        
        else {
            newNode.setValue(inTrait?.name, forKey: "name")
            newNode.setValue(inTrait?.value, forKey: "value")
            
            
        }

        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]


        curModel.setValue(NSNumber.init(floatLiteral: -Double.infinity), forKey: "score")
        
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
        
        newNode.savedX = NSNumber(value: Float(self.frame.width/2.0))
        newNode.savedY = NSNumber(value: Float(self.frame.height/2.0))


        do {
            try moc.save()
        } catch let error as NSError {
            self.printView(error)
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
