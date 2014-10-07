//
//  PlexusBNScene.swift
//  Plexus
//
//  Created by matt on 10/3/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import SpriteKit

class PlexusBNScene: SKScene {

    var dragStart = CGPointMake(0.0, 0.0)
    var startNode = SKNode()
    
    
    
    
    
    override func didMoveToView(view: SKView) {
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        
        var inset : CGRect = CGRectMake(self.frame.width*0.05, self.frame.height*0.05, self.frame.width*0.9, self.frame.height*0.9)
        var borderBody = SKPhysicsBody(edgeLoopFromRect: inset)
        //var borderBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        self.physicsBody = borderBody
        self.physicsBody?.friction = 0.0
        startNode = self // so initialized
        
        
        // Name label
        
        
        let nameLabel = SKLabelNode(text: "Bayesian Network 0")
        nameLabel.fontSize = 18
        nameLabel.zPosition = 1
        nameLabel.position = CGPointMake(self.frame.width*0.5, self.frame.height*0.95)
        
        self.addChild(nameLabel)
        
        
        
        
        
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
        /* Called when a mouse click occurs */
        
        var loc = theEvent.locationInNode(self)
        dragStart = loc
        
        
        
        var touchedNode : SKNode = self.nodeAtPoint(loc)
        startNode = touchedNode
        
        //for now, spawn a new node if you did not touch an exisitng node
        if(touchedNode.isEqualTo(self)) {
            //  println("miss")
            
            
            //create path
            
            var shapePath = CGPathCreateWithRoundedRect(CGRectMake(-30, -15, 60, 30), 4, 4, nil) //reaplce with size of name eventually
            
            let shape = SKShapeNode(path: shapePath)
            shape.position = loc
            shape.physicsBody = SKPhysicsBody(rectangleOfSize: CGRectMake(-15, -15, 30, 30).size)
            shape.physicsBody?.mass = 1.0
            shape.physicsBody?.restitution = 0.3
            shape.name = "bnNode"
            shape.physicsBody?.affectedByGravity = false
            shape.physicsBody?.dynamic = true
            shape.strokeColor = NSColor.blueColor()
            shape.fillColor = NSColor.grayColor()
            
            
            
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
            
            self.addChild(shape)
            /*
            let myLabel = SKLabelNode(text: "Hi there")
            myLabel.fontSize = 12
            myLabel.zPosition = 1
            myLabel.position = sprite.position
            
            self.addChild(myLabel)
            
            // let labelJoint = SKPhysicsJointSpring.jointWithBodyA(myLabel.physicsBody, bodyB: sprite.physicsBody, anchorA: myLabel.position, anchorB: sprite.position)
            let labelJoint = SKPhysicsJointFixed.jointWithBodyA(myLabel.physicsBody, bodyB: sprite.physicsBody, anchor: sprite.position)
            
            self.physicsWorld.addJoint(labelJoint)
            */
        }
            
        else {//touched existing node, can draw line between
            println("hit")
            
            
            
            
            
        }
        
    }
    
    
    
    override func mouseDragged(theEvent: NSEvent) {
        
        
        
        var loc : CGPoint = theEvent.locationInNode(self)
        var touchedNode : SKNode = self.nodeAtPoint(loc)
        
        
        //remove all existing lines
        self.enumerateChildNodesWithName("joinLine", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        
        var joinPath = CGPathCreateMutable()
        CGPathMoveToPoint(joinPath, nil, startNode.position.x, startNode.position.y)
        CGPathAddLineToPoint(joinPath, nil, loc.x, loc.y)
        // CGPathCloseSubpath(joinPath)
        
        let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPointMake(startNode.position.x,startNode.position.y), endPoint: CGPointMake(loc.x,loc.y), tailWidth: 4, headWidth: 10, headLength: 10)
        
        
        var joinLine = SKShapeNode(path: arrowPath)
        joinLine.name = "joinLine"
        joinLine.zPosition = -1
        joinLine.glowWidth = 1
        
        
        self.addChild(joinLine)
        
        
        
    }
    
    
    override func mouseUp(theEvent: NSEvent) {
        
        var loc = theEvent.locationInNode(self)
        
        var releasedNode : SKNode = self.nodeAtPoint(loc)
        
        if(!startNode.isEqualTo(self) && startNode.name == "bnNode" && !releasedNode.isEqualTo(self) && releasedNode.name == "bnNode") {
            println("blammo")
            //create physics joint between these two
            
            let theJoint = SKPhysicsJointSpring.jointWithBodyA(startNode.physicsBody, bodyB: releasedNode.physicsBody, anchorA: startNode.position, anchorB: releasedNode.position)
            
            
            
            self.physicsWorld.addJoint(theJoint)
            
            //make
            
            
            
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
        
        
        
        //remove all existing lines
        self.enumerateChildNodesWithName("joinLine", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
    }
    
    
    
    override func didSimulatePhysics() {
        
        //remove all existing lines
        
        self.enumerateChildNodesWithName("nodeLine", usingBlock: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        
        
        
        self.enumerateChildNodesWithName("bnNode", usingBlock: { thisNode, stop in
            
            
            
            
            //   var theJoints : AnyObject = thisNode.physicsBody.joints
            
            //silly test just to draw lines
            /*
            
            self.enumerateChildNodesWithName("bnNode", usingBlock: { thatNode, stop in
            var joinPath = CGPathCreateMutable()
            CGPathMoveToPoint(joinPath, nil, thisNode.position.x,thisNode.position.y)
            CGPathAddLineToPoint(joinPath, nil, thatNode.position.x, thatNode.position.y)
            CGPathCloseSubpath(joinPath)
            
            var joinLine = SKShapeNode(path: joinPath)
            joinLine.name = "nodeLine"
            joinLine.zPosition = -1
            
            
            self.addChild(joinLine)
            
            })
            */
            
            
            
            for thisJoint in thisNode.physicsBody!.joints {
                //   println(thisJoint)
            }
            
            
            
            
            //    println(thisNode)
            
            
            
            
            
            
            
            
            /*
            for  thisJoint in thisNode.physicsBody.joints as [SKPhysicsJoint] {
            
            
            
            
            
            
            var joinPath = CGPathCreateMutable()
            CGPathMoveToPoint(joinPath, nil, thisJoint.bodyA.node.position.x,thisJoint.bodyA.node.position.y)
            
            }
            */
            
            
        })
        
        
    }
    
    
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        var angle : CGFloat = 1.0
        
        
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
