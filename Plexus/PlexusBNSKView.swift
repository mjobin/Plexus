//
//  PlexusBNSKView.swift
//  Plexus
//
//  Created by matt on 2/27/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa
import SpriteKit
import CoreServices

class PlexusBNSKView: SKView {
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    dynamic var nodesController : NSArrayController!
    
    required init?(coder aDecoder: NSCoder)
    {
        
        super.init(coder: aDecoder)
        let kString : String = kUTTypeURL as String
        let registeredTypes:[String] = [kString]
        self.registerForDraggedTypes(registeredTypes)
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
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
        
        
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        if (curModel.complete == true){
            return false
        }
        
        return true
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        
              
        let pboard : NSPasteboard = sender.draggingPasteboard()
       // let types : NSArray = pboard.types!
        
        
        let kString : String = kUTTypeURL as String
        let data : NSData = pboard.dataForType(kString)!
        let draggedArray : NSArray = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! NSArray
        

        for object : AnyObject in draggedArray{
            self.addNode(object as! NSURL)
           
        }

        return false
    }
    

    
    @IBAction func removeNode(sender: AnyObject) {
       // let errorPtr : NSErrorPointer = nil
        
        
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            let curNode : BNNode = curNodes[0]
            
             moc.deleteObject(curNode)
        }

        
        do {
            try moc.save()
        } catch let error as NSError {
            self.print(error)
        }
        
        
    }
    

    
    func addNode(mourl: NSURL){
       // let errorPtr : NSErrorPointer = nil
        if let id : NSManagedObjectID? = moc.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(mourl){
            
            let mo : NodeLink = moc.objectWithID(id!) as! NodeLink
            
            
            let newNode : BNNode = BNNode(entity: NSEntityDescription.entityForName("BNNode", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
            newNode.setValue(mo, forKey: "nodeLink")
          // mo.addBNNodeObject(newNode)
            


            let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
            let curModel : Model = curModels[0]

            
            curModel.addBNNodeObject(newNode)

            newNode.setValue(curModel, forKey: "model")

            
            
            
            do {
                try moc.save()
            } catch let error as NSError {
                self.print(error)
            }

            
        }
        
    }
    
    

    
    
}
