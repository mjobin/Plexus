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
        moc = appDelegate.managedObjectContext
        
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
            
            
            
            let newModel : Model = curModel.copySelf(self.moc)
                

            // curModel.addChildObject(newModel)
            // newModel.setValue(curModel, forKey: "parent")
            modelTreeController.insert(newModel, atArrangedObjectIndexPath: newPath)
            let copyName : String = curModel.name + " copy"
            newModel.setValue(copyName, forKey: "name")

            
//            var tempNodeArray = [BNNode]()
//
//            let curNodes  = curModel.bnnode.allObjects as! [BNNode]
//            for curNode : BNNode in curNodes {
//                let newNode : BNNode = BNNode(entity: NSEntityDescription.entity(forEntityName: "BNNode", in: self.moc)!, insertInto: self.moc)
//
//                newNode.setValue(curNode.cptArray, forKey: "cptArray")
//                newNode.setValue(curNode.cptReady, forKey: "cptReady")
//                newNode.setValue(curNode.name, forKey: "name")
//                newNode.setValue(curNode.numericData, forKey: "numericData")
//                newNode.setValue(curNode.priorDistType, forKey: "priorDistType")
//                newNode.setValue(curNode.priorDistType, forKey: "priorDistType")
//                newNode.setValue(curNode.priorV1, forKey: "priorV1")
//                newNode.setValue(curNode.priorV2, forKey: "priorV2")
//                newNode.setValue(curNode.savedX, forKey: "savedX")
//                newNode.setValue(curNode.savedY, forKey: "savedY")
//                newNode.setValue(curNode.tolerance, forKey: "tolerance")
//                newNode.setValue(curNode.value, forKey: "value")
//
//
//
//                let blankCount = [Int]()
//                let blankArray = [Float]()
//                newNode.postCount = blankCount
//                newNode.postArray = blankArray
//                newNode.priorCount = blankCount
//                newNode.priorArray = blankArray
//
//
//
//
//
//
//                newNode.setValue(newModel, forKey: "model")
//                newModel.addABNNodeObject(newNode)
//
//                tempNodeArray.append(newNode)
//
//
//
//            }
//
//            var infstwod = [[Int]]()
//
//
//            //Copy Influences
//            for curNode : BNNode in curNodes {
//                var infsoned = [Int]()
//                let infs : [BNNode] = curNode.influences.array as! [BNNode]
//                for inf : BNNode in infs{
//                    var chk = 0
//                    for chkNode : BNNode in curNodes {
//                        if (chkNode == inf){
//                            infsoned.append(chk)
//                        }
//                        chk += 1
//                    }
//
//                }
//                infstwod.append(infsoned)
//
//            }
//            
//            var i = 0
//            for infsoned : [Int] in infstwod{
//                for thisinf in infsoned{
//                    tempNodeArray[i].addAnInfluencesObject(tempNodeArray[thisinf])
//                    tempNodeArray[thisinf].addAnInfluencedByObject(tempNodeArray[i])
//                }
//                i += 1
//            }
            
        }
        
        
    }
    
}
