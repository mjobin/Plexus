//
//  PlexusBNSKView.swift
//  Plexus
//
//  Created by matt on 2/27/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa
import SpriteKit

class PlexusBNSKView: SKView, NSDraggingDestination {
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    dynamic var nodesController : NSArrayController!
    
    required init?(coder aDecoder: NSCoder)
    {
        
        super.init(coder: aDecoder)
        var registeredTypes:[String] = [kUTTypeURL]
        self.registerForDraggedTypes(registeredTypes)
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
    }


    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        
        return NSDragOperation.Copy
        
    }
    
    override func prepareForDragOperation(sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pboard : NSPasteboard = sender.draggingPasteboard()
        let types : NSArray = pboard.types!
        
        
        
        let data : NSData = pboard.dataForType(kUTTypeURL)! as NSData
        let draggedArray : NSArray = NSKeyedUnarchiver.unarchiveObjectWithData(data) as NSArray
        

        for object : AnyObject in draggedArray{
            self.addNode(object as NSURL)
           
        }

        return false
    }
    
    func addNode(mourl: NSURL){
        var errorPtr : NSErrorPointer = nil
        if let id : NSManagedObjectID? = moc.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(mourl){
            
            var mo : NodeLink = moc.objectWithID(id!) as NodeLink
            
            
            var newNode : BNNode = BNNode(entity: NSEntityDescription.entityForName("BNNode", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
            newNode.setValue(mo, forKey: "nodeLink")
            


            var curModels : [Model] = modelTreeController.selectedObjects as [Model]
            var curModel : Model = curModels[0]
            curModel.addBNNodeObject(newNode)

            newNode.setValue(curModel, forKey: "model")
            
            
            
            moc.save(errorPtr)

            
        }
        
    }
    
}
