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
        case Node = 1
        case NodeLine = 2

    }

    var dragStart = CGPointMake(0.0, 0.0)
    var startNode = SKNode()
    var d1 : CGFloat = 0.3
    var d2 : CGFloat = 0.8
    
    

    
    
    
    override func didMoveToView(view: SKView) {
        
            
            let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
            moc = appDelegate.managedObjectContext
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlexusBNScene.mocDidChange(_:)), name: NSManagedObjectContextObjectsDidChangeNotification, object: moc)
        

 
        firstUpdate = true
        
        
        self.backgroundColor = SKColor.clearColor()
        
        self.physicsWorld.gravity = CGVectorMake(0, 0)


        //var borderBody = SKPhysicsBody(edgeLoopFromRect: inset)
        let borderBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        self.physicsBody = borderBody
        self.physicsBody?.friction = 0.0
        startNode = self // so initialized

        
    }
  /*
    override func didChangeSize(oldSize: CGSize) {
        
        self.redrawNodes()
    }
*/
    
    override func mouseDown(theEvent: NSEvent) {

        
        let loc = theEvent.locationInNode(self)
        dragStart = loc
       
        var touchedNode : SKNode = self.nodeAtPoint(loc)
        //print("mouseDown touched \(touchedNode) parent: \(touchedNode.parent)")

        if(touchedNode.isEqualTo(self)) {
            //  print("miss")

            
        }
            
        else {//touched existing node, can draw line between
            
            if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
                let allNodes : [SKNode] = self.nodesAtPoint(touchedNode.position) 
                for theNode : SKNode in allNodes {
                    
                //   print("mouseDOWN sknode \(theNode)")

                    if(theNode.name == "bnNode" && theNode.position == touchedNode.position)
                    {
                        touchedNode = theNode //switch to the bnNode in the position of the label
                    }
                }
                
            }
            
           // print ("mouseDOWN now touchedNode is \(touchedNode)")

            if(touchedNode.name == "bnNode"){
                
                
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    let noglowNode : SKShapeNode = thisNode as! SKShapeNode
                    noglowNode.glowWidth = 0

                })
                
               let idNode : PlexusBNNode = touchedNode as! PlexusBNNode

                idNode.glowWidth = 5
                let idArray : [BNNode] = [idNode.node]

                nodesController.setSelectedObjects(idArray)

                
                if(theEvent.clickCount > 1){ //double-clicks open single node view
                    NSNotificationCenter.defaultCenter().postNotificationName("edu.scu.Plexus.toggleSingleNode", object: self)
                    
                }
                
            }


        }

        
               startNode = touchedNode
        /*
        if(startNode.name == "bnNode"){
            let IDNode : PlexusBNNode = startNode as! PlexusBNNode
            print("mouseDOWN now startNode is bnnode \(startNode) \(IDNode.node.nodeLink.name)")

        }
        else {
            print ("mouseDown startnode is \(startNode)")
        }
        */
    }
    
    
    
    override func mouseDragged(theEvent: NSEvent) {
        

        
        let loc : CGPoint = theEvent.locationInNode(self)
        var touchedNode : SKNode = self.nodeAtPoint(loc)
        
        if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
            let allNodes : [SKNode] = self.nodesAtPoint(touchedNode.position) 
            for theNode : SKNode in allNodes {

                if(theNode.name == "bnNode" && theNode.position == touchedNode.position)
                {
                    touchedNode = theNode //switch to the bnNode in the position of the label
                }
            }
            
        }
        
        
        if (theEvent.modifierFlags.intersect(.CommandKeyMask) == .CommandKeyMask) {
            touchedNode.position = loc
        }
        
        else {
            //remove all existing lines
            self.enumerateChildNodesWithName("joinLine", usingBlock: { thisLine, stop in
                thisLine.removeFromParent()
            })
            
            if(!startNode.isEqualToNode(self)){
                let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPointMake(startNode.position.x,startNode.position.y), endPoint: CGPointMake(loc.x,loc.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: d1, d2: d2)
                d1+=0.1
                d2+=0.1
                if (d2>=1){
                    d2=d1
                    d1=0
                }
                
                
                let joinLine = SKShapeNode(path: arrowPath)
                joinLine.name = "joinLine"
                joinLine.zPosition = -1
                joinLine.fillColor = NSColor.whiteColor()
                joinLine.glowWidth = 1

                self.addChild(joinLine)
            }
            
        }

    }
    
    
    override func mouseUp(theEvent: NSEvent) {
        //let errorPtr : NSErrorPointer = nil
        
        let loc = theEvent.locationInNode(self)
        
        var releasedNode : SKNode = self.nodeAtPoint(loc)
        



        
        
        if(releasedNode.name == "nodeName"){//passing mouseDown to node beenath
            let allNodes : [SKNode] = self.nodesAtPoint(releasedNode.position)
            for theNode : SKNode in allNodes {
                //print("mouseup sknode \(theNode)")
                if(theNode.name == "bnNode" && theNode.position == releasedNode.position)
                {
                    releasedNode = theNode //switch to the bnNode in the position of the label
                }
            }
            
        }
        


        
        if(!startNode.isEqualToNode(self) && startNode.name == "bnNode" && !releasedNode.isEqualToNode(self) && releasedNode.name == "bnNode" && !startNode.isEqualToNode(releasedNode) ) {

            //create physics joint between these two
            
            
            let theJoint = SKPhysicsJointSpring.jointWithBodyA(startNode.physicsBody!, bodyB: releasedNode.physicsBody!, anchorA: startNode.position, anchorB: releasedNode.position)
            
            
            //now add the necessary relationships in the data
            let startIDNode : PlexusBNNode = startNode as! PlexusBNNode
            let releasedIDNode : PlexusBNNode = releasedNode as! PlexusBNNode
            

            
    

            self.physicsWorld.addJoint(theJoint)
            

            startIDNode.node.addInfluencesObject(releasedIDNode.node)
            releasedIDNode.node.addInfluencedByObject(startIDNode.node)
            do {
                try moc.save()
            } catch let error as NSError {
                print(error)
            }


        }
        

        
        //remove all existing lines
        
        self.enumerateChildNodesWithName("joinLine", usingBlock: { thisLine, stop in
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

        
        self.enumerateChildNodesWithName("nodeName", usingBlock: { thisLine, stop in
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

        
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisLine, stop in
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
      // println("bnscene FULL reload")
        self.enumerateChildNodesWithName("nodeName", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
    }
    
    
    override func update(currentTime: CFTimeInterval) {
        

        let inset : CGRect = CGRectMake(25, 25, self.size.width-50, self.size.height-50)
        
       // let inset : CGRect = CGRectMake(25, 25, self.frame.width-50, self.frame.height-50)
        
        let borderBody = SKPhysicsBody(edgeLoopFromRect: inset)
        self.physicsBody = borderBody
        
        
        self.enumerateChildNodesWithName("nodeLine", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
        

        self.enumerateChildNodesWithName("noNodesName", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
        

        
        var outOfBounds = false
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
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
                
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    
                    let idNode : PlexusBNNode = thisNode as! PlexusBNNode
                    
                    if(idNode.node == curNode){
                        matchNode = true
                       
                    }
                    
                })
                
                if(!matchNode){//no visible node exists, so make one
                    self.makeNode(curNode, inPos: CGPointMake(self.frame.width*0.5,  self.frame.height*0.5) )
                    startNode = self //to ensure no deleted nodes rteained as startNode
                    
                }
                
            }
            
            
            //draw arrows
            
            for curNode :BNNode in curNodes{
                
                var idNode : PlexusBNNode!
                
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    
                    let thisidNode : PlexusBNNode = thisNode as! PlexusBNNode
                    
                    if(thisidNode.node == curNode){
                        idNode = thisidNode
                        

                    }
                    
                })
                
                

                
                let theInfluenced : [BNNode] = curNode.influences.allObjects as! [BNNode]

                for thisInfluenced : BNNode in theInfluenced as [BNNode] {

                    var infNode : PlexusBNNode!
                    
                    self.enumerateChildNodesWithName("bnNode", usingBlock: { thatNode, stop in
                        
                        let thatidNode : PlexusBNNode = thatNode as! PlexusBNNode
                        
                        if(thatidNode.node == thisInfluenced){
                            infNode = thatidNode

                        }
                        
                    })

                    if (idNode != nil && infNode != nil) {
                       

                        if(idNode.position.x != infNode.position.x && idNode.position.y != infNode.position.y){ //don't bother drawing the line if nodes right on top of each other. Causes Core Graphics to complain
                        
                            let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPointMake(idNode.position.x,idNode.position.y), endPoint: CGPointMake(infNode.position.x,infNode.position.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: 0.25, d2: 0.75)
                            
                            
                            let joinLine = SKShapeNode(path: arrowPath)
                            joinLine.name = "nodeLine"
                            joinLine.zPosition = -1
                            joinLine.fillColor = NSColor.whiteColor()
                            
                            self.addChild(joinLine)
                        }
                        


                    }
                    
                    
                }
                

                
                
            }
            

            //glow selected
            

            
            self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                let noglowNode : SKShapeNode = thisNode as! SKShapeNode
                noglowNode.glowWidth = 0
                
            })
            
            
            let selNodes : [BNNode]  = nodesController.selectedObjects as! [BNNode]
            for selNode : BNNode in selNodes{
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    
                    let idNode : PlexusBNNode = thisNode as! PlexusBNNode
                    
                    if(idNode.node == selNode){ //found, so make it glow
                        idNode.glowWidth = 4
  
                    }
                    
                })
            }


           
        }



        
        /* Called before each frame is rendered */
        var angle : CGFloat = 0.0
        

        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisKid, stop in
            
            var shortestDistance = self.size.width
            
            self.enumerateChildNodesWithName("bnNode", usingBlock: { thatKid, stop in
                if(!thisKid.isEqualTo(thatKid)){
                    
                    let distance = self.distanceBetween(thisKid.position, q: thatKid.position)
                    
                    if(distance < shortestDistance){
                        
                        shortestDistance = distance
                        
                        angle = self.angleAway(thisKid, nodeB: thatKid)
                        
                        
                        
                    }
                    
                    
                    
                }
                
            })
            
            thisKid.physicsBody?.applyImpulse(self.vectorFromRadians(angle))
            
        })
        
        //redrawNodes()
  
        //Post message in nodes area if no nodes yet
        
        if(nodesController != nil ){
            
            let curNodes : [BNNode]  = nodesController.arrangedObjects as! [BNNode]
            if(curNodes.count < 1) {
                let nnl1 = SKLabelNode(text: "Drag from Structures,")
                let nnl2 = SKLabelNode(text: "Entries or Traits to")
                let nnl3 = SKLabelNode(text: "create a node.")
                nnl1.fontSize = 18
                nnl1.fontName = "SanFrancisco"
                nnl1.name = "noNodesName"
                nnl1.zPosition = 1
                
                nnl2.fontSize = 18
                nnl2.fontName = "SanFrancisco"
                nnl2.name = "noNodesName"
                nnl2.zPosition = 1
                
                nnl3.fontSize = 18
                nnl3.fontName = "SanFrancisco"
                nnl3.name = "noNodesName"
                nnl3.zPosition = 1
                
                nnl1.position = CGPointMake(self.frame.width*0.5, self.frame.height*0.5+30)
                nnl2.position = CGPointMake(self.frame.width*0.5, self.frame.height*0.5)
                nnl3.position = CGPointMake(self.frame.width*0.5, self.frame.height*0.5-30)
                
                self.addChild(nnl1)
                self.addChild(nnl2)
                self.addChild(nnl3)
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

    
    func makeNode(inNode : BNNode, inPos: CGPoint){
               
       // var labelString = inNode.nodeLink.name
        //truncate
        
        let myLabel = SKLabelNode(text: inNode.nodeLink.name)
        myLabel.fontName = "SanFrancisco"
        myLabel.fontSize = 18
        myLabel.zPosition = 1
        myLabel.name = "nodeName"
        myLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
       // myLabel.userInteractionEnabled = true
        
        
        let nodeWidth = (myLabel.frame.size.width)+10
        let nodeHeight = (myLabel.frame.size.height)+10

        
        
        
        
        let shapePath = CGPathCreateWithRoundedRect(CGRectMake(-(nodeWidth/2), -(nodeHeight/2), nodeWidth, nodeHeight), 4, 4, nil)


        
        let shape = PlexusBNNode(path: shapePath)


       // shape.position = CGPointMake(self.frame.width*0.5,  self.frame.height*0.5)
        
        shape.position = inPos
        shape.userInteractionEnabled = true
        shape.physicsBody = SKPhysicsBody(rectangleOfSize: CGRectMake(-(nodeWidth/2), -(nodeHeight/2), nodeWidth, nodeHeight).size)
        shape.physicsBody?.mass = 1.0
        shape.physicsBody?.restitution = 0.3
        shape.name = "bnNode"
        shape.physicsBody?.affectedByGravity = false
        shape.physicsBody?.dynamic = true
        shape.physicsBody?.allowsRotation = false
        shape.physicsBody?.categoryBitMask = ColliderType.Node.rawValue
        shape.physicsBody?.collisionBitMask = ColliderType.Node.rawValue
        shape.strokeColor = NSColor.blueColor()
        shape.fillColor = NSColor.grayColor()

        shape.node = inNode
        
        self.addChild(shape)
        
        myLabel.physicsBody = SKPhysicsBody(rectangleOfSize: CGRectMake(-(nodeWidth/2), -(nodeHeight/2), nodeWidth, nodeHeight).size)
        myLabel.position = shape.position
        
        
        self.addChild(myLabel)
        
        let labelJoint = SKPhysicsJointFixed.jointWithBodyA(myLabel.physicsBody!, bodyB: shape.physicsBody!, anchor: shape.position)
        
        self.physicsWorld.addJoint(labelJoint)
        
        
    }

    
    func distanceBetween(p: CGPoint, q: CGPoint) -> CGFloat {
        return hypot(p.x - q.x, p.y - q.y)
    }
    
    func vectorFromRadians (rad: CGFloat) -> CGVector {
        return CGVectorMake(cos(rad), sin(rad))
    }
    
    func angleAway(nodeA: SKNode, nodeB: SKNode) ->CGFloat {
        return angleTowards(nodeA, nodeB: nodeB) + CGFloat(M_PI)
    }
    
    func angleTowards(nodeA: SKNode, nodeB: SKNode) ->CGFloat {
        
        return atan2(nodeB.position.y - nodeA.position.y, nodeB.position.x - nodeA.position.x)
        
    }
    

    func mocDidChange(notification: NSNotification){
     //   println(notification.userInfo)
        
      //  var justUpdate = true
        
       // println("bn scene MOC DID CHANGE")
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
        
        if let _ = notification.userInfo?[NSDeletedObjectsKey] as? NSSet {
           // justUpdate = false

            self.reloadData()
        }
        else {

            self.reloadDataWPos()
            
        }
        


        
        
    }

    


}
