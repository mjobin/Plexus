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
        
            
            let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
            moc = appDelegate.managedObjectContext
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "mocDidChange:", name: NSManagedObjectContextObjectsDidChangeNotification, object: moc)
        

 
        firstUpdate = true
        
        
        self.backgroundColor = SKColor.clearColor()
        
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        
        var inset : CGRect = CGRectMake(self.frame.width*0.05, self.frame.height*0.05, self.frame.width*0.9, self.frame.height*0.9)
        //var borderBody = SKPhysicsBody(edgeLoopFromRect: inset)
        var borderBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        self.physicsBody = borderBody
        self.physicsBody?.friction = 0.0
        startNode = self // so initialized
        
        
        // Name label
        
        
        //let nameLabel = SKLabelNode(text: "Bayesian Network 0")
       // nameLabel.fontSize = 18
       // nameLabel.zPosition = 1
       // nameLabel.position = CGPointMake(self.frame.width*0.5, self.frame.height*0.95)
        
       // self.addChild(nameLabel)
        
        
        
        
        
        //parent button
        /*
        
        let parent = SKSpriteNode(imageNamed:"Plexus Node")
        parent.position = CGPointMake(self.frame.width*0.05, self.frame.height*0.95)
        parent.setScale(0.1)
        parent.physicsBody = SKPhysicsBody(rectangleOfSize: parent.size)
        parent.physicsBody?.mass = 1.0
        parent.physicsBody?.restitution = 0.6
        parent.name = "fixedButton"
        
        parent.physicsBody?.affectedByGravity = 0
        parent.physicsBody?.dynamic = 0
        
        self.addChild(parent)
        */
        
        
        //flip button
        
        
        /*
        let flip = SKSpriteNode(imageNamed:"Flip Button")
        flip.position = CGPointMake(self.frame.width*0.95, self.frame.height*0.95)
        flip.setScale(0.05)
        flip.physicsBody = SKPhysicsBody(rectangleOfSize: flip.size)
        flip.physicsBody?.mass = 1.0
        flip.physicsBody?.restitution = 0.6
        flip.name = "flipButton"
        
        flip.physicsBody?.affectedByGravity = 0
        flip.physicsBody?.dynamic = 0
        
        self.addChild(flip)
        */
        
        
        // flip button
        //         let flip = PlexusFTButtonNode(normalTexture: "Flip Button")
        //   let flip = PlexusFTButtonNode(normalTexture: "Flip Button", selectedTexture: "Flip Button Selected", disabledTexture: "FlipButton Disabled")
        //    let flip = PlexusFTButtonNode(normalTexture: "Flip Button")
        //     let flip = PlexusFTButtonNode(normalTexture: "Flip Button", selectedTexture: "Flip Button Selected", disabledTexture: "Flip Button Disabled")
        

 
        
    }
    
    override func mouseDown(theEvent: NSEvent) {
        var errorPtr : NSErrorPointer = nil
        
        var loc = theEvent.locationInNode(self)
        dragStart = loc
        
        
        
        var touchedNode : SKNode = self.nodeAtPoint(loc)
        //println("mousDown touched \(touchedNode) name: \(touchedNode.name) ue: \(touchedNode.userInteractionEnabled)")

 
        
        //for now, spawn a new node if you did not touch an exisitng node
        if(touchedNode.isEqualTo(self)) {
            //  println("miss")
            
            let curModels : [Model] = modelTreeController.selectedObjects as [Model]
            let curModel : Model = curModels[0]
            //let curDataset : Dataset = curModel.dataset
            
            
            
            //create an NodeLink - independet node link for nodes not linked to any other form of data
            
            let newNodeLink : NodeLink = NodeLink(entity: NSEntityDescription.entityForName("NodeLink", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
            newNodeLink.setValue("New Node", forKey: "name")
            
            
            let newNode : BNNode = BNNode(entity: NSEntityDescription.entityForName("BNNode", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
            newNode.setValue(newNodeLink, forKey: "nodeLink")
            
            

            curModel.addBNNodeObject(newNode)
            
            newNode.setValue(curModel, forKey: "model")
            
            
            
            moc.save(errorPtr)
            

            self.makeNode(newNode, inPos: loc)
            
            
            //create path
            
            /*
            
            var shapePath = CGPathCreateWithRoundedRect(CGRectMake(-50, -25, 100, 50), 4, 4, nil) //reaplce with size of name eventually
            
            let shape = PlexusBNNode(path: shapePath)
            shape.position = loc
            //shape.userInteractionEnabled = true
            shape.physicsBody = SKPhysicsBody(rectangleOfSize: CGRectMake(-25, -25, 50, 50).size)
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
            

            
            //give it an initial model
            var newNode : BNNode = BNNode(entity: NSEntityDescription.entityForName("BNNode", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
            shape.node = newNode
        

        
            
            var curModels : [Model] = modelTreeController.selectedObjects as [Model]
            var curModel : Model = curModels[0]
            

            curModel.addBNNodeObject(newNode)
            newNode.setValue(curModel, forKey: "model")


            
            moc.save(errorPtr)
            self.addChild(shape)
            
            let myLabel = SKLabelNode(text: "New Node")
            myLabel.fontSize = 18
            myLabel.zPosition = 1
            myLabel.name = "nodeName"
            myLabel.userInteractionEnabled = false
            myLabel.position = shape.position
            myLabel.physicsBody = SKPhysicsBody(rectangleOfSize: CGRectMake(-25, -25, 50, 50).size)
            
            self.addChild(myLabel)
            
            let labelJoint = SKPhysicsJointFixed.jointWithBodyA(myLabel.physicsBody, bodyB: shape.physicsBody, anchor: shape.position)
            
            self.physicsWorld.addJoint(labelJoint)
            */
            
            
            /*
            let sprite = SKSpriteNode(imageNamed:"Plexus Node")
            sprite.position = loc;
            sprite.setScale(0.1)
            sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
            sprite.physicsBody?.mass = 1.0
            sprite.physicsBody?.restitution = 0.3
            sprite.name = "bnNode"
            
            sprite.physicsBody?.affectedByGravity = 0
            sprite.physicsBody?.dynamic = 1
            
            */
            
            
            
            // let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
            // sprite.runAction(SKAction.repeatActionForever(action))
            
            //  self.addChild(sprite)
            
            
            
            

            


            
            
            
        }
            
        else {//touched existing node, can draw line between
            
            if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
                var allNodes : [SKNode] = self.nodesAtPoint(touchedNode.position) as [SKNode]
                for theNode : SKNode in allNodes {

                    if(theNode.name == "bnNode" && theNode.position == touchedNode.position)
                    {
                        touchedNode = theNode //switch to the bnNode in the position of the label
                    }
                }
                
            }

            if(touchedNode.name == "bnNode"){
                
                
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    var noglowNode : SKShapeNode = thisNode as SKShapeNode
                    noglowNode.glowWidth = 0

                })
                
               var idNode : PlexusBNNode = touchedNode as PlexusBNNode
                
                idNode.glowWidth = 5
                let idArray : [BNNode] = [idNode.node]

                //println (idArray)
                

                nodesController.setSelectedObjects(idArray)
                /*
                var newSels : [BNNode] = nodesController.selectedObjects as [BNNode]
                for newSel : BNNode in newSels {
                    println (newSel.name)
                }
               */
                
                
                if(theEvent.clickCount > 1){ //double-clicks open single node view
                    NSNotificationCenter.defaultCenter().postNotificationName("edu.scu.Plexus.toggleSingleNode", object: self)
                    
                }
                
                
                
            }


            
        }

        
               startNode = touchedNode
    }
    
    
    
    override func mouseDragged(theEvent: NSEvent) {
        

        
        var loc : CGPoint = theEvent.locationInNode(self)
        var touchedNode : SKNode = self.nodeAtPoint(loc)
        
        if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
            var allNodes : [SKNode] = self.nodesAtPoint(touchedNode.position) as [SKNode]
            for theNode : SKNode in allNodes {

                if(theNode.name == "bnNode" && theNode.position == touchedNode.position)
                {
                    touchedNode = theNode //switch to the bnNode in the position of the label
                }
            }
            
        }
        
        
        if (theEvent.modifierFlags & .CommandKeyMask == .CommandKeyMask) {
            touchedNode.position = loc
        }
        
        else {
            //remove all existing lines
            self.enumerateChildNodesWithName("joinLine", usingBlock: { thisLine, stop in
                thisLine.removeFromParent()
            })
            
            
            
            let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPointMake(startNode.position.x,startNode.position.y), endPoint: CGPointMake(loc.x,loc.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: d1, d2: d2)
            d1+=0.1
            d2+=0.1
            if (d2>=1){
                d2=d1
                d1=0
            }
            
            
            var joinLine = SKShapeNode(path: arrowPath)
            joinLine.name = "joinLine"
            joinLine.zPosition = -1
            joinLine.fillColor = NSColor.whiteColor()
            joinLine.glowWidth = 1
            
            
            
            self.addChild(joinLine)
            
        }
        


        
    }
    
    
    override func mouseUp(theEvent: NSEvent) {
        var errorPtr : NSErrorPointer = nil
        
        var loc = theEvent.locationInNode(self)
        
        var releasedNode : SKNode = self.nodeAtPoint(loc)
        
        
        if(releasedNode.name == "nodeName"){//passing mouseDown to node beenath
            var allNodes : [SKNode] = self.nodesAtPoint(releasedNode.position) as [SKNode]
            for theNode : SKNode in allNodes {
                if(theNode.name == "bnNode" && theNode.position == releasedNode.position)
                {
                    releasedNode = theNode //switch to the bnNode in the position of the label
                }
            }
            
        }
        

      //  println("start \(startNode) and released \(releasedNode)")

        
        if(!startNode.isEqualTo(self) && startNode.name == "bnNode" && !releasedNode.isEqualTo(self) && releasedNode.name == "bnNode" && !startNode.isEqualTo(releasedNode) ) {

            //create physics joint between these two
            
            let theJoint = SKPhysicsJointSpring.jointWithBodyA(startNode.physicsBody, bodyB: releasedNode.physicsBody, anchorA: startNode.position, anchorB: releasedNode.position)
            
            
            
            
            self.physicsWorld.addJoint(theJoint)
            
            
            
            //now add the necessary relationships in the data
            var startIDNode : PlexusBNNode = startNode as PlexusBNNode
            var releasedIDNode : PlexusBNNode = releasedNode as PlexusBNNode
            
            
            startIDNode.node.addInfluencesObject(releasedIDNode.node)
            releasedIDNode.node.addInfluencedByObject(startIDNode.node)
            moc.save(errorPtr)

            
            
            
        }
        

        
        
        //remove all existing lines
        
        self.enumerateChildNodesWithName("joinLine", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
     
        
    }
    
    
    /*
    override func didSimulatePhysics() {
        
        //remove all existing lines
    
        self.enumerateChildNodesWithName("nodeLine", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })



  
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisKid, stop in
            
            var shortestDistance = self.size.width
            
            self.enumerateChildNodesWithName("bnNode", usingBlock: { thatKid, stop in
                if(!thisKid.isEqualTo(thatKid)){
                    
                   

                    
                    
                    
                    
                    
                    
                }
                
            })
            

            
        })
        

        
        
    }
*/
    
    
    
    func reloadData() { //this just removes the nodes so that update can restopre them
        
        self.enumerateChildNodesWithName("nodeName", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisLine, stop in
            var idNode : PlexusBNNode = thisLine as PlexusBNNode

            let oldPoint : CGPoint = idNode.position
            let oldNode : BNNode = idNode.node
            thisLine.removeFromParent()
            self.makeNode(oldNode, inPos: oldPoint)
            
            
        })

        
        
    }
    
    
    
    override func update(currentTime: CFTimeInterval) {
        

        
        var inset : CGRect = CGRectMake(self.frame.width*0.05, self.frame.height*0.05, self.frame.width*0.9, self.frame.height*0.9)
        var borderBody = SKPhysicsBody(edgeLoopFromRect: inset)
        self.physicsBody = borderBody
        
        
        self.enumerateChildNodesWithName("nodeLine", usingBlock: { thisLine, stop in
        thisLine.removeFromParent()
        })
        

        
        //make sure all listed nodes are drawn
        
        if(nodesController != nil ){
        
            let curNodes : [BNNode]  = nodesController.arrangedObjects as [BNNode]

            for curNode :BNNode in curNodes{
                
                
                
                
                var matchNode = false
                
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    
                    var idNode : PlexusBNNode = thisNode as PlexusBNNode
                    
                    if(idNode.node == curNode){
                        matchNode = true
                       
                    }
                    
                })
                
                if(!matchNode){//no visible node exists, so make one

                    self.makeNode(curNode, inPos: CGPointMake(self.frame.width*0.5,  self.frame.height*0.5) )
                    
                }

                
            }
            
            

            //draw arrows
            
            
            for curNode :BNNode in curNodes{
                
                var idNode : PlexusBNNode!
                
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    
                    var thisidNode : PlexusBNNode = thisNode as PlexusBNNode
                    
                    if(thisidNode.node == curNode){
                        idNode = thisidNode

                    }
                    
                })
                
                
                let theInfluenced : [BNNode] = curNode.influences.allObjects as [BNNode]
                


                
                for thisInfluenced : BNNode in theInfluenced as [BNNode] {

                    
                    //FIXME this is s stupid way to do this
                    var infNode : PlexusBNNode!
                    
                    self.enumerateChildNodesWithName("bnNode", usingBlock: { thatNode, stop in
                        
                        var thatidNode : PlexusBNNode = thatNode as PlexusBNNode
                        
                        if(thatidNode.node == thisInfluenced){
                            infNode = thatidNode

                        }
                        
                    })
                    
                    
                    
                    if (idNode != nil && infNode != nil) {
                       
                        

                        
                        let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPointMake(idNode.position.x,idNode.position.y), endPoint: CGPointMake(infNode.position.x,infNode.position.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: 0.25, d2: 0.75)
                        
                        
                        var joinLine = SKShapeNode(path: arrowPath)
                        joinLine.name = "nodeLine"
                        joinLine.zPosition = -1
                        joinLine.fillColor = NSColor.whiteColor()
                        
                        
                        
                        self.addChild(joinLine)
                        
                        
                        

                    }
                    
                    
                }
                

                
                
            }
            
            
            
            
            //match names
            /*
            for curNode :BNNode in curNodes{
                curNode.setValue(curNode.nodeLink.name, forKey: "name")
            }
            */
            


            
            //glow selected
            
            
            
            self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                var noglowNode : SKShapeNode = thisNode as SKShapeNode
                noglowNode.glowWidth = 0
                
            })
            
            
            let selNodes : [BNNode]  = nodesController.selectedObjects as [BNNode]
            for selNode : BNNode in selNodes{
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    
                    var idNode : PlexusBNNode = thisNode as PlexusBNNode
                    
                    if(idNode.node == selNode){ //found, so make it glow
                        idNode.glowWidth = 5
  
                    }
                    
                })
            }


           
        }


        
/*
      
        var selNodes : [BNNode] = nodesController.selectedObjects as [BNNode]
        for selNode : BNNode in selNodes {
            
            self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                
                var idNode : PlexusBNNode = thisNode as PlexusBNNode
                
                if(idNode.node == selNode){
                    idNode.glowWidth = 5
                    
                }
                else {
                    idNode.glowWidth = 0
                }
        
                
            })
            
            
        }

        */
        
        /* Called before each frame is rendered */
        var angle : CGFloat = 0.0
        

        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisKid, stop in
            
            var shortestDistance = self.size.width
            
            self.enumerateChildNodesWithName("bnNode", usingBlock: { thatKid, stop in
                if(!thisKid.isEqualTo(thatKid)){
                    
                    var distance = self.distanceBetween(thisKid.position, q: thatKid.position)
                    
                    if(distance < shortestDistance){
                        
                        shortestDistance = distance
                        
                        angle = self.angleAway(thisKid, nodeB: thatKid)
                        
                        
                        
                    }
                    
                    
                    
                }
                
            })
            
            thisKid.physicsBody?.applyImpulse(self.vectorFromRadians(angle))
            
        })
        

  
        
        
    }
    
    func redrawNodes() {

       self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
            var idNode : PlexusBNNode = thisNode as PlexusBNNode

            if(idNode.position.x < self.frame.width*0.05){
                idNode.position.x = self.frame.width*0.1
                //println("too left")
                
            }
            if(idNode.position.y < self.frame.height*0.05){
                idNode.position.y = self.frame.height*0.1
               // println("too low")
                
            }
            
            if((idNode.position.x + idNode.frame.width) > self.frame.width*0.95){
                idNode.position.x = (self.frame.width*0.9 - idNode.frame.width)
               // println("too right")
                
            }
            if((idNode.position.y + idNode.frame.height) > self.frame.height*0.95){
                idNode.position.y = (self.frame.height*0.9 - idNode.frame.height)
              // println("too high")
            }
        

            
            })
        
        
    }
    
    func makeNode(inNode : BNNode, inPos: CGPoint){
        
        
        let myLabel = SKLabelNode(text: inNode.nodeLink.name)
        myLabel.fontSize = 18
        myLabel.zPosition = 1
        myLabel.name = "nodeName"
        myLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
       // myLabel.userInteractionEnabled = true
        
        


        let nodeWidth = (myLabel.frame.size.width)*1.5
        let nodeHeight = (myLabel.frame.size.height)*1.3
        
        
        
        var shapePath = CGPathCreateWithRoundedRect(CGRectMake(-(nodeWidth/2), -(nodeHeight/2), nodeWidth, nodeHeight), 4, 4, nil)


        
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
        
        let labelJoint = SKPhysicsJointFixed.jointWithBodyA(myLabel.physicsBody, bodyB: shape.physicsBody, anchor: shape.position)
        
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
        self.reloadData()
    }

    


}
