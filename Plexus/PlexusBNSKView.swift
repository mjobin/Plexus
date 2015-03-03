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
        println("bnskview init")
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
        println("dragging on bnskview")
        
        return NSDragOperation.Copy
        
    }
    
    override func draggingExited(sender: NSDraggingInfo?) {
        println("dragging ENDED on bnskview")
    }
    
    override func prepareForDragOperation(sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pboard : NSPasteboard = sender.draggingPasteboard()
        let types : NSArray = pboard.types!
        
        println(types)
        

        
        let data : NSData = pboard.dataForType(kUTTypeURL)! as NSData
        let draggedArray : NSArray = NSKeyedUnarchiver.unarchiveObjectWithData(data) as NSArray
        
        // Loop through DraggedArray
        for object : AnyObject in draggedArray{
            
            println(object)
            self.addNode(object as NSURL)
            //let mo : NSURL = object as NSURL
            
            
            //FIXME then insert this to addNode in BNScene
            // Get the ID of the NSManagedObject
            /*
            if let id : NSManagedObjectID? = persistentStoreCoordinator?.managedObjectIDForURIRepresentation(object as NSURL){
                

            }
            */
        }
        /*
        if(types.containsObject(kUTTypeURL)){
            println("kutt found")
            //let ustr : NSString = pboard.stringForType(NSString (format: kUTTypeURL))!
           // let ustr : NSString = pboard.stringForType((NSString *)kUTTypeURL)
            //let mo : NSURL = NSURL(string: ustr)
           // println(mo)
        }
        */
        return false
    }
    
    func addNode(mourl: NSURL){
        var errorPtr : NSErrorPointer = nil
       // println("addnode \(mourl)")
        if let id : NSManagedObjectID? = moc.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(mourl){
            
            var mo : NodeLink = moc.objectWithID(id!) as NodeLink
            
            
            var newNode : BNNode = BNNode(entity: NSEntityDescription.entityForName("BNNode", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
            //newNode.setValue(newNode.name, forKey: "name")
            newNode.setValue("added", forKey: "name")
            newNode.setValue(mo, forKey: "nodeLink")
            
    //        yes but what about recirocal add for the node

            var curModels : [Model] = modelTreeController.selectedObjects as [Model]
            var curModel : Model = curModels[0]
            
            
            curModel.addBNNodeObject(newNode)
            newNode.setValue(curModel, forKey: "model")
            
            
            
            moc.save(errorPtr)
            
        }
        
    }
    
}
