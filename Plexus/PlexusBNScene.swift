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
        

 
        firstUpdate = true
        
        
        self.backgroundColor = SKColor.clearColor()
        
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        
        var inset : CGRect = CGRectMake(self.frame.width*0.05, self.frame.height*0.05, self.frame.width*0.9, self.frame.height*0.9)
        var borderBody = SKPhysicsBody(edgeLoopFromRect: inset)
        //var borderBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
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
            
            
            //create path
            
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
            newNode.setValue("test", forKey: "name")
            shape.node = newNode
//            newDataset.addModelObject(newModel)
            

            

            
            var curModels : [Model] = modelTreeController.selectedObjects as [Model]
            var curModel : Model = curModels[0]
            

            curModel.addBNNodeObject(newNode)
            newNode.setValue(curModel, forKey: "model")


            
            moc.save(errorPtr)
            self.addChild(shape)
            
            
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


            
            
            
        }
            
        else {//touched existing node, can draw line between
            
            if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
                var allNodes : [SKNode] = self.nodesAtPoint(touchedNode.position) as [SKNode]
                for theNode : SKNode in allNodes {
                    //println(theNode)
                   // println("\(theNode) pos: \(theNode.position)")
                    if(theNode.name == "bnNode" && theNode.position == touchedNode.position)
                    {
                        //println("BINGO \(theNode) pos: \(theNode.position)")
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
                let idArray : [PlexusBNNode] = [idNode]
                
                nodesController.setSelectedObjects(idArray)
                
                
                if(theEvent.clickCount > 1){ //double-clicks open single node view
                    NSNotificationCenter.defaultCenter().postNotificationName("edu.scu.Plexus.toggleSingleNode", object: self)
                    
                }
                
                
                
            }

            
            
            

            

            

            
            
            
            
        }
        touchedNode.physicsBody?.applyImpulse(CGVectorMake(0.0, 0.0))
        
               startNode = touchedNode
    }
    
    
    
    override func mouseDragged(theEvent: NSEvent) {
        
        
        
        var loc : CGPoint = theEvent.locationInNode(self)
        var touchedNode : SKNode = self.nodeAtPoint(loc)
        
        if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
            var allNodes : [SKNode] = self.nodesAtPoint(touchedNode.position) as [SKNode]
            for theNode : SKNode in allNodes {
                //println(theNode)
                // println("\(theNode) pos: \(theNode.position)")
                if(theNode.name == "bnNode" && theNode.position == touchedNode.position)
                {
                    //println("BINGO \(theNode) pos: \(theNode.position)")
                    touchedNode = theNode //switch to the bnNode in the position of the label
                }
            }
            
        }
        
        
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
        
        touchedNode.physicsBody?.applyImpulse(CGVectorMake(0.0, 0.0))
        
    }
    
    
    override func mouseUp(theEvent: NSEvent) {
        var errorPtr : NSErrorPointer = nil
        
        var loc = theEvent.locationInNode(self)
        
        var releasedNode : SKNode = self.nodeAtPoint(loc)
        
        
        if(releasedNode.name == "nodeName"){//passing mouseDown to node beenath
            var allNodes : [SKNode] = self.nodesAtPoint(releasedNode.position) as [SKNode]
            for theNode : SKNode in allNodes {
                //println(theNode)
                // println("\(theNode) pos: \(theNode.position)")
                if(theNode.name == "bnNode" && theNode.position == releasedNode.position)
                {
                    //println("BINGO \(theNode) pos: \(theNode.position)")
                    releasedNode = theNode //switch to the bnNode in the position of the label
                }
            }
            
        }
        

        //println("\(startNode) to \(releasedNode)")
        
        if(!startNode.isEqualTo(self) && startNode.name == "bnNode" && !releasedNode.isEqualTo(self) && releasedNode.name == "bnNode") {
            //println("blammo")
            //create physics joint between these two
            
            let theJoint = SKPhysicsJointSpring.jointWithBodyA(startNode.physicsBody, bodyB: releasedNode.physicsBody, anchorA: startNode.position, anchorB: releasedNode.position)
            
            
            
            
            self.physicsWorld.addJoint(theJoint)
            

         //   then create a line and pin it to the nodes duh
            

            
            let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPointMake(startNode.position.x,startNode.position.y), endPoint: CGPointMake(loc.x,loc.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: 0.25, d2: 0.75)
            
            
            var joinLine = SKShapeNode(path: arrowPath)
            joinLine.name = "nodeLine"
            joinLine.zPosition = -1
            //joinLine.glowWidth = 1
            joinLine.fillColor = NSColor.whiteColor()
            joinLine.physicsBody = SKPhysicsBody(polygonFromPath: arrowPath)
            joinLine.physicsBody?.affectedByGravity = false
            
             joinLine.physicsBody?.categoryBitMask = ColliderType.NodeLine.rawValue
            //joinLine.physicsBody?.collisionBitMask = ColliderType.NodeLine.rawValue
            joinLine.physicsBody?.collisionBitMask = 0

            
            self.addChild(joinLine)
            

            
            let startJoint = SKPhysicsJointPin.jointWithBodyA(startNode.physicsBody, bodyB: joinLine.physicsBody, anchor: startNode.position)
            //let startSpringJoint = SKPhysicsJointSpring.jointWithBodyA(startNode.physicsBody, bodyB: joinLine.physicsBody, anchorA: startNode.position, anchorB:
            self.physicsWorld.addJoint(startJoint)

            let endJoint = SKPhysicsJointPin.jointWithBodyA(releasedNode.physicsBody, bodyB: joinLine.physicsBody, anchor: releasedNode.position)
            self.physicsWorld.addJoint(endJoint)
            
            //now add the necessary relationships in the data
            var startIDNode : PlexusBNNode = startNode as PlexusBNNode
            var releasedIDNode : PlexusBNNode = releasedNode as PlexusBNNode
            
            
            startIDNode.node.addInfluencesObject(releasedIDNode.node)
            releasedIDNode.node.addInfluencedByObject(startIDNode.node)
            moc.save(errorPtr)

            
            
            
            
        }
        
        /*
        if(releasedNode.isEqualTo(self)) {
        println("and miss")
        }
        else { //did not release onto background
        if(releasedNode.name == "bnNode"){
        println("hit node")
        if(startNode.isEqualTo(self)) {
        }
        else {
        
        }
        
        
        }
        
        }
        */
        
        
        
        //remove glow all nodes
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
            var noglowNode : SKShapeNode = thisNode as SKShapeNode
            noglowNode.glowWidth = 0
            
        })
        
        //remove all existing lines
        
        self.enumerateChildNodesWithName("joinLine", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        releasedNode.physicsBody?.applyImpulse(CGVectorMake(0.0, 0.0))
        
    }
    
    
    /*
    override func didSimulatePhysics() {
        
        //remove all existing lines
        /*
        self.enumerateChildNodesWithName("nodeLine", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
        */

        
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisKid, stop in
            
            var shortestDistance = self.size.width
            
            self.enumerateChildNodesWithName("bnNode", usingBlock: { thatKid, stop in
                if(!thisKid.isEqualTo(thatKid)){
                    
                   

                    
                    
                    
                    
                    
                    
                }
                
            })
            

            
        })
        

        
        
    }
    */
    
    
    func drawInitial () {
        
        if(nodesController != nil){
            
            let curNodes : [BNNode]  = nodesController.arrangedObjects as [BNNode]
            
            //draw nodes
            for curNode :BNNode in curNodes{
                println("curNode")
                
                var matchNode = false
                
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    
                    var idNode : PlexusBNNode = thisNode as PlexusBNNode
                    
                    if(idNode.node == curNode){
                        matchNode = true
                    }
                    
                })
                
                if(!matchNode){//no visible node exists, so make one
                    
                    self.makeNode(curNode)
                    
                }
                
                
            }
            
            
            //draw arrows FIXME
            
            /*
            for curNode :BNNode in curNodes{
                
                var idNode : PlexusBNNode!
                
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    
                    var thisidNode : PlexusBNNode = thisNode as PlexusBNNode
                    
                    if(thisidNode.node == curNode){
                        idNode = thisidNode
                        println("bingo")
                    }
                    
                })
                
                
                let theInfluenced : [BNNode] = curNode.influences.allObjects as [BNNode]
                
                // println("cur: \(curNode)  inf  \(theInfluenced.count)")
                
                
                for thisInfluenced : BNNode in theInfluenced as [BNNode] {
                    // println(thisInfluenced)
                    
                    //FIXME this is s stupid way to do this
                    var infNode : PlexusBNNode!
                    
                    self.enumerateChildNodesWithName("bnNode", usingBlock: { thatNode, stop in
                        
                        var thatidNode : PlexusBNNode = thatNode as PlexusBNNode
                        
                        if(thatidNode.node == thisInfluenced){
                            infNode = thatidNode
                            println("bongo")
                        }
                        
                    })
                    
                    var idJoints = idNode.physicsBody?.joints
                    
                    if (idNode != nil && infNode != nil) {
                        
                        
                        // println("\(idNode) \(idNode.position) and \(infNode) \(infNode.position)")
                        
                        var matchJoint = false
                        var idJoints = idNode.physicsBody?.joints
                        var infJoints = infNode.physicsBody?.joints
                        
                        /*
                        for idJoint : SKPhysicsJoint in [idJoints] as [SKPhysicsJoint] {
                        for infJoint : SKNode in [infJoints] as SKNode {
                        println(" \(idJoint.bodyB) and \(infJoint.bodyB)")
                        // if (idJoint == infJoint){
                        //   println("MATCH \(idJoint) and \(infJoint)")
                        // }
                        }
                        }
                        */
                        
                        
                        
                        
                        
                        let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPointMake(idNode.position.x,idNode.position.y), endPoint: CGPointMake(infNode.position.x,infNode.position.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: 0.25, d2: 0.75)
                        
                        
                        var joinLine = SKShapeNode(path: arrowPath)
                        joinLine.name = "nodeLine"
                        joinLine.zPosition = -1
                        joinLine.fillColor = NSColor.whiteColor()
                        
                        
                        println(joinLine.position)
                        
                        joinLine.physicsBody = SKPhysicsBody(polygonFromPath: arrowPath)
                        joinLine.physicsBody?.affectedByGravity = false
                        
                        joinLine.physicsBody?.categoryBitMask = ColliderType.NodeLine.rawValue
                        joinLine.physicsBody?.collisionBitMask = 0
                        
                        
                        self.addChild(joinLine)
                        
                        
                        
                        let startJoint = SKPhysicsJointPin.jointWithBodyA(idNode.physicsBody, bodyB: joinLine.physicsBody, anchor: idNode.position)
                        self.physicsWorld.addJoint(startJoint)
                        
                        let endJoint = SKPhysicsJointPin.jointWithBodyA(infNode.physicsBody, bodyB: joinLine.physicsBody, anchor: infNode.position)
                        self.physicsWorld.addJoint(endJoint)
                    }
                    
                    
                }
                
                
                
                
            }
            */
            
        }
    }
    
    
    
    override func update(currentTime: CFTimeInterval) {
        
        var inset : CGRect = CGRectMake(self.frame.width*0.05, self.frame.height*0.05, self.frame.width*0.9, self.frame.height*0.9)
        var borderBody = SKPhysicsBody(edgeLoopFromRect: inset)
        self.physicsBody = borderBody
        
        //make sure all listed nodes are drawn
        
        if(nodesController != nil && firstUpdate){
        
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

                    self.makeNode(curNode)
                    
                }

                
            }
            
            

            //draw arrows FIXME
            
            
            for curNode :BNNode in curNodes{
                
                var idNode : PlexusBNNode!
                
                self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
                    
                    var thisidNode : PlexusBNNode = thisNode as PlexusBNNode
                    
                    if(thisidNode.node == curNode){
                        idNode = thisidNode
                        println("bingo")
                    }
                    
                })
                
                
                let theInfluenced : [BNNode] = curNode.influences.allObjects as [BNNode]
                
               // println("cur: \(curNode)  inf  \(theInfluenced.count)")

                
                for thisInfluenced : BNNode in theInfluenced as [BNNode] {
                   // println(thisInfluenced)
                    
                    //FIXME this is s stupid way to do this
                    var infNode : PlexusBNNode!
                    
                    self.enumerateChildNodesWithName("bnNode", usingBlock: { thatNode, stop in
                        
                        var thatidNode : PlexusBNNode = thatNode as PlexusBNNode
                        
                        if(thatidNode.node == thisInfluenced){
                            infNode = thatidNode
                            println("bongo")
                        }
                        
                    })
                    
                    var idJoints = idNode.physicsBody?.joints
                    
                    if (idNode != nil && infNode != nil) {
                       
                        
        

                        
                        
//FIXMEchange it so that every new upodate a new line is drawn?
                        
                        
                        let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPointMake(idNode.position.x,idNode.position.y), endPoint: CGPointMake(infNode.position.x,infNode.position.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: 0.25, d2: 0.75)
                        
                        
                        var joinLine = SKShapeNode(path: arrowPath)
                        joinLine.name = "nodeLine"
                        joinLine.zPosition = -1
                        joinLine.fillColor = NSColor.whiteColor()
                        
                        
                        println(joinLine.position)
                        
                        joinLine.physicsBody = SKPhysicsBody(polygonFromPath: arrowPath)
                        joinLine.physicsBody?.affectedByGravity = false
                        
                        joinLine.physicsBody?.categoryBitMask = ColliderType.NodeLine.rawValue
                        joinLine.physicsBody?.collisionBitMask = 0
                        
                        
                        self.addChild(joinLine)
                        
                        
                        
                        let startJoint = SKPhysicsJointPin.jointWithBodyA(idNode.physicsBody, bodyB: joinLine.physicsBody, anchor: idNode.position)
                       //  let startJoint = SKPhysicsJointSpring.jointWithBodyA(idNode.physicsBody, bodyB: infNode.physicsBody, anchorA: idNode.position, anchorB: infNode.position)
                        self.physicsWorld.addJoint(startJoint)
                        
                        let endJoint = SKPhysicsJointPin.jointWithBodyA(infNode.physicsBody, bodyB: joinLine.physicsBody, anchor: infNode.position)
                        // let endJoint = SKPhysicsJointSpring.jointWithBodyA(infNode.physicsBody, bodyB: idNode.physicsBody, anchorA: infNode.position, anchorB: idNode.position)
                        self.physicsWorld.addJoint(endJoint)
                    }
                    
                    
                }
                

                
                
            }

            firstUpdate = false //damn this is ugly
        }


        
        
        //self.frame.width*0.05, self.frame.height*0.05, self.frame.width*0.9, self.frame.height*0.9)
        
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
            var idNode : PlexusBNNode = thisNode as PlexusBNNode
            if(idNode.position.x < self.frame.width*0.05){
                idNode.position.x = self.frame.width*0.05
                
                //idNode.physicsBody?.applyImpulse(CGVectorMake(10.0, 0.0))
            }
            if(idNode.position.y < self.frame.height*0.05){
                idNode.position.y = self.frame.height*0.05
                //idNode.physicsBody?.applyImpulse(CGVectorMake(0.0, 10.0))
            }
            
            if(idNode.position.x > self.frame.width*0.95){
                idNode.position.x = self.frame.width*0.95
                //idNode.physicsBody?.applyImpulse(CGVectorMake(-10.0, 0.0))
            }
            if(idNode.position.y > self.frame.height*0.95){
                idNode.position.y = self.frame.height*0.95
               // idNode.physicsBody?.applyImpulse(CGVectorMake(0.0, -10.0))
            }
        
            
            
            })

        
      
        
        
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
        
        //check if frame of node is outside bounds
        /*
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisKid, stop in
            println(thisKid.frame)
            println(self.frame)
            
        })
        */
     
        
        
        
        
        
    }
    
    func makeNode(inNode : BNNode){
        
        
        let myLabel = SKLabelNode(text: inNode.name)
        myLabel.fontSize = 18
        myLabel.zPosition = 1
        myLabel.name = "nodeName"
        myLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
       // myLabel.userInteractionEnabled = true
        
        
        //now get size of that text?
        //println(myLabel.frame.size)
        let nodeWidth = (myLabel.frame.size.width)*1.2
        let nodeHeight = (myLabel.frame.size.height)*1.2
        
        
        
        var shapePath = CGPathCreateWithRoundedRect(CGRectMake(-(nodeWidth/2), -(nodeHeight/2), nodeWidth, nodeHeight), 4, 4, nil)


        
        let shape = PlexusBNNode(path: shapePath)
        //FIXME node will probably be drag/droppped
        var xrand = (CGFloat(arc4random()) /  CGFloat(UInt32.max))
        var yrand = (CGFloat(arc4random()) /  CGFloat(UInt32.max))

        shape.position = CGPointMake(self.frame.width*xrand,  self.frame.height*yrand)
       // shape.position = CGPointMake(self.frame.width*0.5,  self.frame.height*0.5)
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

}
