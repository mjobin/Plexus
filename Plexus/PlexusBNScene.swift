//
//  PlexusBNScene.swift
//  Plexus
//
//  Created by matt on 10/3/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import SpriteKit
import CoreData

class PlexusBNScene: SKScene {
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    dynamic var nodesController : NSArrayController!
    
    var firstUpdate = true
    
    enum ColliderType: UInt32 {
        case node = 1
        case nodeLine = 2

    }

    var dragStart = CGPoint(x: 0.0, y: 0.0)
    var startNode = SKNode()
    var d1 : CGFloat = 0.3
    var d2 : CGFloat = 0.8
    
    
    override func didMove(to view: SKView) {
        
            
            let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
            moc = appDelegate.managedObjectContext
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlexusBNScene.mocDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: moc)
        

 
        firstUpdate = true
        
        
        self.backgroundColor = SKColor.clear
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)


        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody = borderBody
        self.physicsBody?.friction = 0.0
        startNode = self // so initialized

        
    }
  /*
    override func didChangeSize(oldSize: CGSize) {
        
        self.redrawNodes()
    }
*/
    
    override func keyDown(with theEvent: NSEvent) {
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        if(curModel.complete == true){
            return
        }
        
        interpretKeyEvents([theEvent])
    }
    
    override func deleteBackward(_ sender: Any?) {
        
        
        let selNodes : [BNNode]  = nodesController.selectedObjects as! [BNNode]
        for selNode : BNNode in selNodes{
            nodesController.removeObject(selNode)
            let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
            moc = appDelegate.managedObjectContext
            moc.delete(selNode)
            
        }
        
        
        self.reloadData()
    }
    
    override func mouseDown(with theEvent: NSEvent) {

        //print ("event: \(theEvent)")
        
        
        let loc = theEvent.location(in: self)
        dragStart = loc
       
        var touchedNode : SKNode = self.atPoint(loc)
       // print("mouseDown touched \(touchedNode) parent: \(touchedNode.parent)")

        if(touchedNode.isEqual(to: self)) {
            //  print("miss")

            
        }
            
        else {//touched existing node, can draw line between
            
            if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
                let allNodes : [SKNode] = self.nodes(at: touchedNode.position)
               // print (allNodes)
                for theNode : SKNode in allNodes {
                    
                //   print("mouseDOWN sknode \(theNode) pos: \(theNode.position)")

                    if(theNode.name == "bnNode")
                    {
                        touchedNode = theNode //switch to the bnNode in the position of the label
                    }
                }
                
            }
            
           // print ("mouseDown now touchedNode is \(touchedNode)")

            if(touchedNode.name == "bnNode"){
                
                
                self.enumerateChildNodes(withName: "bnNode", using: { thisNode, stop in
                    let noglowNode : SKShapeNode = thisNode as! SKShapeNode
                    noglowNode.glowWidth = 0

                })
                
               let idNode : PlexusBNNode = touchedNode as! PlexusBNNode

                idNode.glowWidth = 5
                let idArray : [BNNode] = [idNode.node]

                nodesController.setSelectedObjects(idArray)
                
                


                
                if(theEvent.clickCount > 1){ //double-clicks open single node view
//                    print("DOUBLE")
//
//                    var contextMenu = NSMenu.init(title: "whut")
//                    NSMenu.popUpContextMenu(contextMenu, with: theEvent, for: self.view!)
                }
                
            }


        }

        
               startNode = touchedNode
        
//        if(startNode.name == "bnNode"){
//            let IDNode : PlexusBNNode = startNode as! PlexusBNNode
//            print("mouseDOWN now startNode is bnnode \(startNode) \(IDNode.node.nodeLink.name)")
//
//        }
//        else {
//            print ("mouseDown startnode is \(startNode)")
//        }
 
    }
    
    
    override func rightMouseDown(with theEvent: NSEvent) {
        

       
        let loc = theEvent.location(in: self)

        
        let touchedNode : SKNode = self.atPoint(loc)
        
        if(touchedNode.name == "bnNode"){
            print("on node")
        }
        /*
         let contextMenu = NSMenu.init(title: "whut")
        NSMenu.popUpContextMenu(contextMenu, withEvent: theEvent, forView: self.view!)
 */
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        
        
        let loc : CGPoint = theEvent.location(in: self)
        var touchedNode : SKNode = self.atPoint(loc)
        
        if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
            let allNodes : [SKNode] = self.nodes(at: touchedNode.position) 
            for theNode : SKNode in allNodes {

                if(theNode.name == "bnNode" && theNode.position == touchedNode.position)
                {
                    touchedNode = theNode //switch to the bnNode in the position of the label
                }
            }
            
        }
        
        
        if (theEvent.modifierFlags.intersection(.command) == .command) {
            touchedNode = startNode
            touchedNode.position = loc
        }
        
        else {
            
            let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
            let curModel : Model = curModels[0]
            if(curModel.complete == true){
                return
            }

            
            //remove all existing lines
            self.enumerateChildNodes(withName: "joinLine", using: { thisLine, stop in
                thisLine.removeFromParent()
            })
            
            if(!startNode.isEqual(to: self)){
                let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPoint(x: startNode.position.x,y: startNode.position.y), endPoint: CGPoint(x: loc.x,y: loc.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: d1, d2: d2)
                d1+=0.1
                d2+=0.1
                if (d2>=1){
                    d2=d1
                    d1=0
                }
                
                
                let joinLine = SKShapeNode(path: arrowPath)
                joinLine.name = "joinLine"
                joinLine.zPosition = -1
                joinLine.fillColor = NSColor.white
                joinLine.glowWidth = 1

                self.addChild(joinLine)
            }
            
        }

    }
    
    
    override func mouseUp(with theEvent: NSEvent) {
        //let errorPtr : NSErrorPointer = nil
        /*
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        if(curModel.complete == true){
            return
        }
        */
        
        let loc = theEvent.location(in: self)
        
        var releasedNode : SKNode = self.atPoint(loc)
        



        
        
        if(releasedNode.name == "nodeName"){//passing mouseDown to node beenath
            let allNodes : [SKNode] = self.nodes(at: releasedNode.position)

            for theNode : SKNode in allNodes {
                //print("mouseup sknode \(theNode)")
                if(theNode.name == "bnNode")
                {
                    releasedNode = theNode //switch to the bnNode in the position of the label
                }
            }
            
        }
        

//        print("mouseup startnode \(startNode) rleasednode \(releasedNode)")


        
        if(!startNode.isEqual(to: self) && startNode.name == "bnNode" && !releasedNode.isEqual(to: self) && releasedNode.name == "bnNode" && !startNode.isEqual(to: releasedNode) ) {

            //create physics joint between these two
            
            
            let theJoint = SKPhysicsJointSpring.joint(withBodyA: startNode.physicsBody!, bodyB: releasedNode.physicsBody!, anchorA: startNode.position, anchorB: releasedNode.position)
            
            
            //now add the necessary relationships in the data
            let startIDNode : PlexusBNNode = startNode as! PlexusBNNode
            let releasedIDNode : PlexusBNNode = releasedNode as! PlexusBNNode
            


            self.physicsWorld.add(theJoint)
            

            startIDNode.node.addInfluencesObject(releasedIDNode.node)
            releasedIDNode.node.addInfluencedByObject(startIDNode.node)

            
            if(startIDNode.node.DFTcyclechk([startIDNode.node]) || releasedIDNode.node.DFTcyclechk([releasedIDNode.node])){
                //print("Cycle detected! Not an allowable influence")
                
                let startinfluences = startIDNode.node.mutableSetValue(forKey: "influences");
                startinfluences.remove(releasedIDNode.node)
                
                let releasedinfluences = releasedIDNode.node.mutableSetValue(forKey: "influencedBy");
                releasedinfluences.remove(startIDNode.node)
                
            }
            
            do {
                try moc.save()
            } catch let error as NSError {
                print(error)
            }
            

           self.reloadData()

            
        }
        

        
        //remove all existing lines
        
        self.enumerateChildNodes(withName: "joinLine", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
     
        
        
        //reset startnode
        startNode = self
        releasedNode = self
    }
    
    
    
    
    
    func reloadDataWPos() { //this just removes the nodes so that update can restopre them

     //   print("bnscene reloadDataWpos")
        //save the moc here to make sure changes read properly
        /*
        
      do {
          try moc.save()
      } catch let error as NSError {
          print(error)
      }
        */

        
        self.enumerateChildNodes(withName: "nodeName", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        

        
        //check if there are  any PlexusBNNodes without an exisitng BNNode, and delete them forst
        
        /*
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisLine, stop in
            var idNode : PlexusBNNode = thisLine as! PlexusBNNode
            if(idNode.node == nil){
                println("missing BNNode")
                thisLine.removeFromParent()
            }
            
        })
        */

        
        self.enumerateChildNodes(withName: "bnNode", using: { thisLine, stop in
            let idNode : PlexusBNNode = thisLine as! PlexusBNNode
            let oldPoint : CGPoint = idNode.position
            let oldNode : BNNode = idNode.node
            thisLine.removeFromParent()

            self.makeNode(oldNode, inPos: oldPoint)
            
            //update will catch undrawn nodes
        
        })


        startNode = self //to ensure no deleted nodes retained as startNode
        
    }
   
    
    func reloadData(){
        self.enumerateChildNodes(withName: "nodeName", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        self.enumerateChildNodes(withName: "bnNode", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        

        let inset : CGRect = CGRect(x: 25, y: 25, width: self.size.width-50, height: self.size.height-50)
        
        let borderBody = SKPhysicsBody(edgeLoopFrom: inset)
        self.physicsBody = borderBody
        
        
        self.enumerateChildNodes(withName: "nodeLine", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        

        self.enumerateChildNodes(withName: "noNodesName", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        

        
        var outOfBounds = false
        self.enumerateChildNodes(withName: "bnNode", using: { thisNode, stop in
            let idNode : PlexusBNNode = thisNode as! PlexusBNNode
        
            if(idNode.position.x < 0 || idNode.position.y < 0 || idNode.position.x > self.size.width || idNode.position.y  > self.size.height) {
                
                outOfBounds = true
            }

        })
        
        if (outOfBounds == true){
            self.reloadData()
        }
        
        
        
        //make sure all listed nodes are drawn
        
        if(nodesController != nil ){
        
            let curNodes : [BNNode]  = nodesController.arrangedObjects as! [BNNode]
            

            for curNode :BNNode in curNodes{
                
                var matchNode = false
                
                self.enumerateChildNodes(withName: "bnNode", using: { thisNode, stop in
                    
                    let idNode : PlexusBNNode = thisNode as! PlexusBNNode
                    
                    if(idNode.node == curNode){
                        matchNode = true
                       
                    }
                    
                })
                
                if(!matchNode){//no visible node exists, so make one
                    self.makeNode(curNode, inPos: CGPoint(x: self.frame.width*0.5,  y: self.frame.height*0.5) )
                    startNode = self //to ensure no deleted nodes rteained as startNode
                    
                }
                
            }
            
            
            //draw arrows
            
            for curNode :BNNode in curNodes{
                
                var idNode : PlexusBNNode!
                
                self.enumerateChildNodes(withName: "bnNode", using: { thisNode, stop in
                    
                    let thisidNode : PlexusBNNode = thisNode as! PlexusBNNode
                    
                    if(thisidNode.node == curNode){
                        idNode = thisidNode
                        

                    }
                    
                })
                
                

                
                let theInfluenced : [BNNode] = curNode.influences.array as! [BNNode]

                for thisInfluenced : BNNode in theInfluenced as [BNNode] {

                    var infNode : PlexusBNNode!
                    
                    self.enumerateChildNodes(withName: "bnNode", using: { thatNode, stop in
                        
                        let thatidNode : PlexusBNNode = thatNode as! PlexusBNNode
                        
                        if(thatidNode.node == thisInfluenced){
                            infNode = thatidNode

                        }
                        
                    })

                    if (idNode != nil && infNode != nil) {
                       

                        if(idNode.position.x != infNode.position.x && idNode.position.y != infNode.position.y){ //don't bother drawing the line if nodes right on top of each other. Causes Core Graphics to complain
                        
                            let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPoint(x: idNode.position.x,y: idNode.position.y), endPoint: CGPoint(x: infNode.position.x,y: infNode.position.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: 0.25, d2: 0.75)
                            
                            
                            let joinLine = SKShapeNode(path: arrowPath)
                            joinLine.name = "nodeLine"
                            joinLine.zPosition = -1
                            joinLine.fillColor = NSColor.white
                            
                            self.addChild(joinLine)
                        }
                        


                    }
                    
                    
                }
                

                
                
            }
            

            //glow selected
            

            
            self.enumerateChildNodes(withName: "bnNode", using: { thisNode, stop in
                let noglowNode : SKShapeNode = thisNode as! SKShapeNode
                noglowNode.glowWidth = 0
                
            })
            
            
            let selNodes : [BNNode]  = nodesController.selectedObjects as! [BNNode]
            for selNode : BNNode in selNodes{
                self.enumerateChildNodes(withName: "bnNode", using: { thisNode, stop in
                    
                    let idNode : PlexusBNNode = thisNode as! PlexusBNNode
                    
                    if(idNode.node == selNode){ //found, so make it glow
                        idNode.glowWidth = 4
  
                    }
                    
                })
            }


           
        }

        var angle : CGFloat = 0.0
        

        self.enumerateChildNodes(withName: "bnNode", using: { thisKid, stop in
            
            var shortestDistance = self.size.width
            
            self.enumerateChildNodes(withName: "bnNode", using: { thatKid, stop in
                if(!thisKid.isEqual(to: thatKid)){
                    
                    let distance = self.distanceBetween(thisKid.position, q: thatKid.position)
                    
                    if(distance < shortestDistance){
                        
                        shortestDistance = distance
                        
                        angle = self.angleAway(thisKid, nodeB: thatKid)
                        
                    }
                    
                }
                
            })
            
            thisKid.physicsBody?.applyImpulse(self.vectorFromRadians(angle))
            
        })
        

  
        //Post message in nodes area if no nodes yet
        
        if(nodesController != nil ){
            
            let curNodes : [BNNode]  = nodesController.arrangedObjects as! [BNNode]
            if(curNodes.count < 1) {
                let nnl1 = SKLabelNode(text: "Drag from  Traits to")
                let nnl2 = SKLabelNode(text: "create a node.")
                nnl1.fontSize = 18
                nnl1.fontName = "Helvetica-Bold"
                nnl1.name = "noNodesName"
                nnl1.zPosition = 1
                
                nnl2.fontSize = 18
                nnl2.fontName = "Helvetica-Bold"
                nnl2.name = "noNodesName"
                nnl2.zPosition = 1
                
                nnl1.position = CGPoint(x: self.frame.width*0.5, y: self.frame.height*0.5+30)
                nnl2.position = CGPoint(x: self.frame.width*0.5, y: self.frame.height*0.5)

                
                self.addChild(nnl1)
                self.addChild(nnl2)

            }
        }


        
    }
  
    /*
    func redrawNodes() {
        
    
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
            let idNode : PlexusBNNode = thisNode as! PlexusBNNode

            if(idNode.position.x < 25){
                idNode.position.x = 25
                print("too left")
                
            }
            if(idNode.position.y < 25){
                idNode.position.y = 25
                print("too low")
                
            }
            
            if((idNode.position.x + idNode.frame.width) > self.frame.width-25){
                idNode.position.x = (self.frame.width-25 - idNode.frame.width)
                 print("too right")
                
            }
            if((idNode.position.y + idNode.frame.height) > self.frame.height-25){
                idNode.position.y = (self.frame.height-25 - idNode.frame.height)
                print("too high")
             
            }
 
 
            
        })
        
        self.reloadDataWPos()
        
    }
    
    */

    
    func makeNode(_ inNode : BNNode, inPos: CGPoint){
               

        
        let myLabel = SKLabelNode(text: inNode.nodeLink.name)
        myLabel.fontName = "Helvetica-Bold"
        myLabel.fontSize = 14
        myLabel.zPosition = 3
        myLabel.name = "nodeName"
        myLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.bottom
       // myLabel.userInteractionEnabled = true
        
        let inTrait = inNode.nodeLink as! Trait
        
        let valLabel = SKLabelNode(text: inTrait.traitValue)
        valLabel.fontName = "Helvetica"
        valLabel.fontSize = 12
        //valLabel.fontColor = SKColor.lightGray
        valLabel.zPosition = 2
        valLabel.name = "nodeName"
        valLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
        
        
        
        var nodeWidth = (myLabel.frame.size.width)+10
        if(valLabel.frame.size.width > myLabel.frame.size.width) {
            nodeWidth = (valLabel.frame.size.width)+10
        }
        let nodeHeight = myLabel.frame.size.height + valLabel.frame.size.height + 10

        
        
        let shapePath = CGPath(roundedRect: CGRect(x: -(nodeWidth/2), y: -(nodeHeight/2), width: nodeWidth, height: nodeHeight), cornerWidth: 4, cornerHeight: 4, transform: nil)


        
        let shape = PlexusBNNode(path: shapePath)

        
        shape.position = inPos
        shape.zPosition = 1
        shape.isUserInteractionEnabled = true
        shape.physicsBody = SKPhysicsBody(rectangleOf: CGRect(x: -(nodeWidth/2), y: -(nodeHeight/2), width: nodeWidth, height: nodeHeight).size)
        shape.physicsBody?.mass = 1.0
        shape.physicsBody?.restitution = 0.3
        //shape.physicsBody?.friction = 0.9
        shape.physicsBody?.linearDamping = 0.9
        //shape.physicsBody?.angularDamping = 0.9
        shape.name = "bnNode"
        shape.physicsBody?.affectedByGravity = false
        shape.physicsBody?.isDynamic = true
        shape.physicsBody?.allowsRotation = false
        shape.physicsBody?.categoryBitMask = ColliderType.node.rawValue
        shape.physicsBody?.collisionBitMask = ColliderType.node.rawValue
        shape.strokeColor = NSColor.blue
        shape.fillColor = NSColor.darkGray

        shape.node = inNode
        
        self.addChild(shape)
        
        myLabel.physicsBody = SKPhysicsBody(rectangleOf: CGRect(x: -(nodeWidth/2), y: -(nodeHeight/2), width: nodeWidth, height: nodeHeight).size)
        myLabel.position = shape.position
        
        
        self.addChild(myLabel)
        
        
        valLabel.physicsBody = SKPhysicsBody(rectangleOf: CGRect(x: -(nodeWidth/2), y: -(nodeHeight/2), width: nodeWidth, height: nodeHeight).size)
        valLabel.position = shape.position
        
        
        self.addChild(valLabel)
        
        
        let labelJoint = SKPhysicsJointFixed.joint(withBodyA: myLabel.physicsBody!, bodyB: shape.physicsBody!, anchor: shape.position)
        
        self.physicsWorld.add(labelJoint)
        
        let vallabelJoint = SKPhysicsJointFixed.joint(withBodyA: valLabel.physicsBody!, bodyB: shape.physicsBody!, anchor: shape.position)
        
        self.physicsWorld.add(vallabelJoint)
        
        
    }

    
    func distanceBetween(_ p: CGPoint, q: CGPoint) -> CGFloat {
        return hypot(p.x - q.x, p.y - q.y)
    }
    
    func vectorFromRadians (_ rad: CGFloat) -> CGVector {
        return CGVector(dx: cos(rad), dy: sin(rad))
    }
    
    func angleAway(_ nodeA: SKNode, nodeB: SKNode) ->CGFloat {
        return angleTowards(nodeA, nodeB: nodeB) + CGFloat(Double.pi)
    }
    
    func angleTowards(_ nodeA: SKNode, nodeB: SKNode) ->CGFloat {
        
        return atan2(nodeB.position.y - nodeA.position.y, nodeB.position.x - nodeA.position.x)
        
    }
    

    func mocDidChange(_ notification: Notification){
     //   println(notification.userInfo)
        
      //  var justUpdate = true
        
     //   print("bn scene MOC DID CHANGE")
        /*
        NB: don't chamnge the following unless you know what will happen when you delete a node
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
            for updatedObject in updatedObjects {
              //  println("UPDATE \(updatedObject)")
                self.reloadData()
            }
        }
        
        if let refreshedObjects = notification.userInfo?[NSRefreshedObjectsKey] as? NSSet {
            justUpdate = false
            for refreshedObject in refreshedObjects {
              //  println("REFRESHED \(refreshedObject)")
                self.reloadData()
            }
        }
        
        
        
        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? NSSet {
            justUpdate = false
            for insertedObject in insertedObjects {
              //  println("inserted \(insertedObject)")
                self.reloadData()
            }
        }
        */
        
        if let _ = (notification as NSNotification).userInfo?[NSDeletedObjectsKey] as? NSSet {
           // justUpdate = false

            self.reloadData()
        }
        else {

            self.reloadDataWPos()
            
        }
        


        
        
    }

    


}
