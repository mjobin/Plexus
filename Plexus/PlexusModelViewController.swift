//
//  PlexusModelViewController.swift
//  Plexus
//
//  Created by matt on 10/15/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusModelViewController: NSViewController {

    var moc : NSManagedObjectContext!
    @IBOutlet dynamic var modelTreeController : NSTreeController!
    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    

    
   @IBAction func childModel(_ sender : AnyObject){

        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]


        //print ("curmodel \(curModel)")
    
    
    if let curPath : IndexPath = modelTreeController.selectionIndexPath {
        let newPath :IndexPath = curPath.appending(curModel.children.count)
        
        

        let newModel : Model = Model(entity: NSEntityDescription.entity(forEntityName: "Model", in: self.moc)!, insertInto: self.moc)
        

        
        
       // curModel.addChildObject(newModel)
       // newModel.setValue(curModel, forKey: "parent")
        modelTreeController.insert(newModel, atArrangedObjectIndexPath: newPath)
        let copyName : String = curModel.name + " copy"
        newModel.setValue(copyName, forKey: "name")
        newModel.setValue(curModel.scope, forKey: "scope")

        var tempNodeArray = [BNNode]()
        
        let curNodes  = curModel.bnnode.allObjects as! [BNNode]
        for curNode : BNNode in curNodes {
            let newNode : BNNode = BNNode(entity: NSEntityDescription.entity(forEntityName: "BNNode", in: self.moc)!, insertInto: self.moc)

            
            newNode.setValue(curNode.priorDistType, forKey: "priorDistType")
            newNode.setValue(curNode.priorV1, forKey: "priorV1")
            newNode.setValue(curNode.priorV2, forKey: "priorV2")
            newNode.setValue(curNode.nodeLink, forKey: "nodeLink")
            newNode.setValue(curNode.numericData, forKey: "numericData")
            newNode.setValue(curNode.tolerance, forKey: "tolerance")
            newNode.setValue(curNode.cptArray, forKey: "cptArray")
            
            
            //Move postArray and post Count to new nodes' priorArray and priorCount, so that new sims can be run on previous results
            newNode.setValue(curNode.postArray, forKey: "priorArray")
            newNode.setValue(curNode.postCount, forKey: "priorCount")
            
            
            let blankArray = [NSNumber]()
            let blankData = NSKeyedArchiver.archivedData(withRootObject: blankArray)
            newNode.setValue(blankData, forKey: "postCount")
            newNode.setValue(blankData, forKey: "postArray")
            
            
            newNode.setValue(curNode.cptReady, forKey: "cptReady")
            
            
            newNode.setValue(newModel, forKey: "model")
            newModel.addBNNodeObject(newNode)
            
            tempNodeArray.append(newNode)
            
            
            
        }
        
        var infstwod = [[Int]]()

        
        //Copy Influences
        for curNode : BNNode in curNodes {
            var infsoned = [Int]()
            let infs : [BNNode] = curNode.influences.array as! [BNNode]
            for inf : BNNode in infs{
                var chk = 0
                for chkNode : BNNode in curNodes {
                    if (chkNode == inf){
                        infsoned.append(chk)
                    }
                    chk += 1
                }
                
            }
            infstwod.append(infsoned)
            
        }
        
        var i = 0
        for infsoned : [Int] in infstwod{
            for thisinf in infsoned{
                tempNodeArray[i].addInfluencesObject(tempNodeArray[thisinf])
                tempNodeArray[thisinf].addInfluencedByObject(tempNodeArray[i])
            }
            i += 1
        }
        
    }



    

    
    }
    
}
