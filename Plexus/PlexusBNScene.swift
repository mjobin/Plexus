//
//  PlexusBNScene.swift
//  Plexus
//
//  Created by matt on 10/3/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
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
    var movingNode = SKNode()
    var changes = false
    var drawInter = true

    var d1 : CGFloat = 0.3
    var d2 : CGFloat = 0.8
    
    
    override func didMove(to view: SKView) {

        
            
        let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
        moc = appDelegate.persistentContainer.viewContext
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlexusBNScene.mocDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: moc)
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveData), name: NSNotification.Name.NSApplicationWillTerminate, object: nil)


        
//        let options: NSKeyValueObservingOptions = [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old]
//        modelTreeController.addObserver(self, forKeyPath: "selectionIndexPath", options: options, context: nil)

 
        firstUpdate = true
        
        
        self.backgroundColor = SKColor.clear
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)


        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody = borderBody
        self.physicsBody?.friction = 0.0
        startNode = self // so initialized
        movingNode = self


    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        changes = true
//        self.redrawNodes()
    }

    
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
            


            
            
            let theInfInters = selNode.infsInter(sender: self)
            for thisinfInter in theInfInters{
                self.enumerateChildNodes(withName: "bnNodeInter", using: { thisNodeInter, stop in
                    let thisidNodeInter : PlexusBNNodeInter = thisNodeInter as! PlexusBNNodeInter
                    if(thisidNodeInter.nodeInter == thisinfInter){
                        thisidNodeInter.ifthenLabel.removeFromParent()
                        thisidNodeInter.removeFromParent()
                    }
                })
                moc.delete(thisinfInter)
            }
            
            let theInfByInters = selNode.infByInter (sender : self)
            for thisinfByInter in theInfByInters{
                    self.enumerateChildNodes(withName: "bnNodeInter", using: { thisNodeInter, stop in
                        let thisidNodeInter : PlexusBNNodeInter = thisNodeInter as! PlexusBNNodeInter
                        if(thisidNodeInter.nodeInter == thisinfByInter){
                            thisidNodeInter.ifthenLabel.removeFromParent()
                            thisidNodeInter.removeFromParent()
                        }
                    })
                moc.delete(thisinfByInter)
            }
            
            
            nodesController.removeObject(selNode)
            let appDelegate : AppDelegate = NSApplication.shared().delegate as! AppDelegate
            moc = appDelegate.persistentContainer.viewContext
            moc.delete(selNode)
            
        }
        
        
        self.reloadData()
    }
    
    override func mouseDown(with theEvent: NSEvent) {

        //print ("event: \(theEvent)")
        
        
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]

        
        
        let loc = theEvent.location(in: self)
        dragStart = loc
       
        var touchedNode : SKNode = self.atPoint(loc)
//        print("mouseDown touched \(touchedNode.name)      parent: \(String(describing: touchedNode.parent))")

        if(touchedNode.isEqual(to: self)) { //pass up to scroll?
            if(theEvent.clickCount > 1){
                if(curModel.complete == true){
                    return
                }
                
                if let skView = self.view as! PlexusBNSKView? {
                    skView.addNode(inTrait: nil)
                }
                
                    
            }

            
        }
            
        else {//touched existing node, can draw line between
            
            
             if(touchedNode.name == "nodeLine"){//passing mouseDown to node if in same area
                let allNodes : [SKNode] = self.nodes(at: touchedNode.position)
                for theNode : SKNode in allNodes {
                    if(theNode.name == "bnNode")
                    {
                        touchedNode = theNode //switch to the bnNode in the position of the label
                    }
                }
                
            }
            
            
            if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
                let allNodes : [SKNode] = self.nodes(at: touchedNode.position)

                for theNode : SKNode in allNodes {
                    
                //   print("mouseDOWN sknode \(theNode) pos: \(theNode.position)")

                    if(theNode.name == "bnNode")
                    {
                        touchedNode = theNode //switch to the bnNode in the position of the label
                    }
                }
                
            }
            
//            print ("mouseDown now touchedNode is \(touchedNode)")

            if(touchedNode.name == "bnNode"){
                
                self.enumerateChildNodes(withName: "lightingNode", using: { thisNode, stop in
                    thisNode.removeFromParent()
                    
                     })
                
                self.enumerateChildNodes(withName: "bnNode", using: { thisNode, stop in
                    let noglowNode : SKSpriteNode = thisNode as! SKSpriteNode
                    noglowNode.texture = SKTexture(imageNamed:"PlexusNode")

                })
                
                self.enumerateChildNodes(withName: "bnNodeInter", using: { thisNode, stop in
                    let noglowNode : SKSpriteNode = thisNode as! SKSpriteNode
                    noglowNode.texture = SKTexture(imageNamed:"PlexusNode")
                    
                })
                
               let idNode : PlexusBNNode = touchedNode as! PlexusBNNode
                idNode.texture = SKTexture(imageNamed:"PlexusNodeSelected")
               
                
                let idArray : [BNNode] = [idNode.node]

                nodesController.setSelectedObjects(idArray)
                
                if(theEvent.clickCount > 1){ //double-clicks open single node view
                    NotificationCenter.default.post(name:Notification.Name(rawValue:"nodeDblClick"),
                            object: nil,
                            userInfo: ["message":"nodeDblClick", "date":Date()])
                    
                }
                
            }
            
            

        }

        
               startNode = touchedNode
    
 
    }
    
    
    override func rightMouseDown(with theEvent: NSEvent) {
        
        print("right mouse down")
       
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
    
    override func rightMouseDragged(with event: NSEvent) {
        print("right mouse dragged")
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        
        let loc : CGPoint = theEvent.location(in: self)
        var touchedNode : SKNode = self.atPoint(loc)
        changes = true
        drawInter = false
        
//        print("mouseDragged touched \(String(describing: touchedNode.name))        moving: \(String(describing: movingNode.name)))")
        
//        if(touchedNode.isEqual(to: self)) { //pass up to scroll?
//            
//        }
        
//        if movingNode != self {
//            print("mouseDdragged touched \(touchedNode) parent: \(String(describing: touchedNode.parent)) moving \(movingNode)")
//        }
        
        self.enumerateChildNodes(withName: "nodeInterName", using: { thisLine, stop in
            thisLine.removeFromParent()
        })

        self.enumerateChildNodes(withName: "bnNodeInter", using: { thisLine, stop in
            thisLine.removeFromParent()
        })

        
        if movingNode.name == "bnNode"{
            let bnNode = movingNode as! PlexusBNNode
            bnNode.position = loc
            bnNode.nameLabel.position = loc
            bnNode.valLabel.position = loc
//            print("\(bnNode.name) position now \(bnNode.position)")
            return
        }
        
        if(touchedNode.name == "nodeLine"){//passing mouseDown to node if in same area
            let allNodes : [SKNode] = self.nodes(at: touchedNode.position)
            for theNode : SKNode in allNodes {
                if(theNode.name == "bnNode")
                {
                    touchedNode = theNode //switch to the bnNode in the position of the label
                }
            }
            
        }
        
        if(touchedNode.name == "nodeName"){//passing mouseDown to node beenath
            let allNodes : [SKNode] = self.nodes(at: touchedNode.position) 
            for theNode : SKNode in allNodes {

                if(theNode.name == "bnNode" && theNode.position == touchedNode.position)
                {
                    touchedNode = theNode //switch to the bnNode in the position of the label

                }
            }
            
        }
        
//        print ("\nmouseDdragged now touchedNode is \(touchedNode)\n")
        
        if (theEvent.modifierFlags.intersection(.command) == .command) {

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
        else {
//            touchedNode = startNode
//            touchedNode.position = loc


            if touchedNode.name == "bnNode"{
                movingNode = touchedNode
//                print("\n**********************mouseDdragged touched \(String(describing: touchedNode.name))     moving: \(String(describing: movingNode.name)))\n")
                let bnNode = touchedNode as! PlexusBNNode
                bnNode.position = loc
                bnNode.nameLabel.position = loc
                bnNode.valLabel.position = loc
            }
        }
        

    }
    
    
    override func mouseUp(with theEvent: NSEvent) {
        //let errorPtr : NSErrorPointer = nil
        
        movingNode = self

        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        if(curModel.complete == true){
            return
        }
 
        
        
        
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
            

            _ = startIDNode.node.addAnInfluencesObject(infBy: releasedIDNode.node, moc : moc)
            _ = releasedIDNode.node.addAnInfluencedByObject(inf: startIDNode.node, moc : moc)

            
            if(startIDNode.node.DFTcyclechk([startIDNode.node]) || releasedIDNode.node.DFTcyclechk([releasedIDNode.node])){
                
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
            

//           self.reloadData()

            
        }
        

        
        //remove all existing lines
        
        self.enumerateChildNodes(withName: "joinLine", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
     
        
        
        //reset startnode
        startNode = self
        releasedNode = self
        drawInter = true
    }
    
    
    
    
    
    func reloadDataWPos() { //this just removes the nodes so that update can restopre them

//        print("bnscene reloadDataWpos")
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
        changes = true
        drawInter = true
        
    }
   
    
    func reloadData(){
//        print ("reload data")
        self.enumerateChildNodes(withName: "nodeName", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        self.enumerateChildNodes(withName: "nodeInterName", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        self.enumerateChildNodes(withName: "bnNodeInter", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        
        self.enumerateChildNodes(withName: "bnNode", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
        changes = true

    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
//        print ("changes \(changes) firstupdate \(firstUpdate) drawInter \(drawInter)")
        
        if changes == false && firstUpdate == false  && drawInter == false {
            return
        }

        let inset : CGRect = CGRect(x: 25, y: 25, width: self.size.width-50, height: self.size.height-50)
        
        let borderBody = SKPhysicsBody(edgeLoopFrom: inset)
        self.physicsBody = borderBody
        

        self.enumerateChildNodes(withName: "nodeLine", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        

        self.enumerateChildNodes(withName: "scoreName", using: { thisText, stop in
            thisText.removeFromParent()
        })

        self.enumerateChildNodes(withName: "noNodesName", using: { thisText, stop in
            thisText.removeFromParent()
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
                    let xloc = Double(self.frame.width/2)
                    let yloc = Double(self.frame.height/2)
                    self.makeNode(curNode, inPos: CGPoint(x: xloc,  y: yloc) )
                    startNode = self //to ensure no deleted nodes rteained as startNode
                }
                
            }
            

            //draw arrows
            if curNodes.count > 0 {
                for curNode :BNNode in curNodes{
                    
                    
                    var idNode : PlexusBNNode!
                    
                    self.enumerateChildNodes(withName: "bnNode", using: { thisNode, stop in
                        
                        let thisidNode : PlexusBNNode = thisNode as! PlexusBNNode
                        
                        if(thisidNode.node == curNode){
                            idNode = thisidNode
                            

                        }
                        
                    })
                    

                        let theInfluences : [BNNode] = curNode.infs(self)
                        for thisInfluences : BNNode in theInfluences as [BNNode] {
                            var infNode : PlexusBNNode!
                            self.enumerateChildNodes(withName: "bnNode", using: { thatNode, stop in
                                
                                let thatidNode : PlexusBNNode = thatNode as! PlexusBNNode
                                
                                if(thatidNode.node == thisInfluences){
                                    infNode = thatidNode
                                }
                            })
                            if (idNode != nil && infNode != nil) {
                                
                                
                               //Draw Arrow
                                if(idNode.position.x != infNode.position.x && idNode.position.y != infNode.position.y){ //don't bother drawing the line if nodes right on top of each other. Causes Core Graphics to complain
                                    let arrowPath = CGPath.bezierPathWithArrowFromPoint(CGPoint(x: idNode.position.x,y: idNode.position.y), endPoint: CGPoint(x: infNode.position.x,y: infNode.position.y), tailWidth: 2, headWidth: 10, headLength: 10, d1: 0.25, d2: 0.75)
                                    let joinLine = SKShapeNode(path: arrowPath)
//                                    joinLine.alpha = 1.0
                                    joinLine.name = "nodeLine"
                                    joinLine.zPosition = 1
//                                    joinLine.fillColor = NSColor.white
                                    self.addChild(joinLine)
                                }
                                
                                
                                if drawInter == true {
                                    //Create and draw NodeInter
                                    //Find halfway distance along line
                                    //Get lower of the two
                                    var lowX = idNode.position.x
                                    var hiX = infNode.position.x
                                    if infNode.position.x < lowX {
                                        lowX = infNode.position.x
                                        hiX = idNode.position.x
                                    }
                                    var lowY = idNode.position.y
                                    var hiY = infNode.position.y
                                    if infNode.position.y < lowY {
                                        lowY = infNode.position.y
                                        hiY = idNode.position.y
                                    }

                                    let theX = ((hiX - lowX) / 2.0) + lowX
                                    let theY = ((hiY - lowY) / 2.0) + lowY

                                    if let interNode = idNode.node.getInfInterBetween(infByNode: infNode.node, moc: moc) {
                                        var foundinter = false
                                        
                                        self.enumerateChildNodes(withName: "bnNodeInter", using: { thisNodeInter, stop in
                                            
                                            let thisidNodeInter : PlexusBNNodeInter = thisNodeInter as! PlexusBNNodeInter
                                            

                                            if(thisidNodeInter.nodeInter == interNode){ //Found it, just set its position
                                                foundinter = true
                                                thisidNodeInter.position = CGPoint(x: theX,  y: theY)
                                            }
     
                                        })
                                        
                                        if foundinter == false {
                                            let interNode = idNode.node.addAnInfluencesObject(infBy: infNode.node, moc: moc)
                                            //Create display node for this Nodeinter
                                            self.makeNodeInter(interNode, inPos: CGPoint(x: theX,  y: theY))
                                            
                                            
                                        }
                                        
                                    }
                                    else {

                                                let interNode = idNode.node.addAnInfluencesObject(infBy: infNode.node, moc: moc)
                                                //Create display node for this Nodeinter
                                                self.makeNodeInter(interNode, inPos: CGPoint(x: theX,  y: theY))
                                        
                                        }
                                    
                                    drawInter = false
                                }
                            }
                        }

                    
                
                }
                firstUpdate = false
            }
            
            
            //Highlight selected node
            
            let theSelected = nodesController.selectedObjects as! [BNNode]
            if theSelected.count > 0 {
                let selNode = theSelected[0]

                self.enumerateChildNodes(withName: "bnNode", using: { thisKid, stop in
                    let thisPBN = thisKid as! PlexusBNNode
                    if thisPBN.node == selNode {
                        thisPBN.texture = SKTexture(imageNamed:"PlexusNodeSelected")
                    }

                })
            }
            
        }
        

        
        
//
//        var angle : CGFloat = 0.0
        

//        self.enumerateChildNodes(withName: "bnNode", using: { thisKid, stop in
//
//            var shortestDistance = self.size.width
//
//            self.enumerateChildNodes(withName: "bnNode", using: { thatKid, stop in
//                if(!thisKid.isEqual(to: thatKid)){
//
//                    let distance = self.distanceBetween(thisKid.position, q: thatKid.position)
//
//                    if(distance < shortestDistance){
//
//                        shortestDistance = distance
//
//                        angle = self.angleAway(thisKid, nodeB: thatKid)
//
//                    }
//
//                }
//
//            })
//
//            thisKid.physicsBody?.applyImpulse(self.vectorFromRadians(angle))
//
//        })
        
        
  
        //Post message in nodes area if no nodes yet
        if(nodesController != nil ){
            
            let curNodes : [BNNode]  = nodesController.arrangedObjects as! [BNNode]
            if(curNodes.count < 1) {
                let nnl1 = SKLabelNode(text: "Drag from  Traits to")
                let nnl2 = SKLabelNode(text: "create a node.")
                nnl1.fontSize = 18
                nnl1.fontName = "SFProDisplay-Bold"
                nnl1.name = "noNodesName"
                nnl1.zPosition = 1
                
                nnl2.fontSize = 18
                nnl2.fontName = "SFProDisplay-Bold"
                nnl2.name = "noNodesName"
                nnl2.zPosition = 1
                
                nnl1.position = CGPoint(x: self.frame.width*0.5, y: self.frame.height*0.5+30)
                nnl2.position = CGPoint(x: self.frame.width*0.5, y: self.frame.height*0.5)

                
                self.addChild(nnl1)
                self.addChild(nnl2)

            }
        }

        if(modelTreeController != nil ){
            let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
            if curModels.count > 0{
                let curModel : Model = curModels[0]
                if(curModel.score != 0){
                    let scoretxt = SKLabelNode(text: "Score: \(curModel.score)")
                    scoretxt.fontSize = 18
                    scoretxt.fontName = "SFProDisplay-Bold"
                    scoretxt.name = "scoreName"
                    scoretxt.zPosition = 1
                    scoretxt.position = CGPoint(x: self.frame.width*0.5, y: 20)
                    self.addChild(scoretxt)
                }
                
            }
        }
        
        
        
        changes = false
        
        
    }
  
    
    func saveData () {
        if(nodesController != nil ){
            
            let curNodes : [BNNode]  = nodesController.arrangedObjects as! [BNNode]
            
            for curNode :BNNode in curNodes{
                self.enumerateChildNodes(withName: "bnNode", using: { thisNode, stop in
                    
                    let idNode : PlexusBNNode = thisNode as! PlexusBNNode
                    if(idNode.node == curNode){
                        let xloc = idNode.position.x
                        let yloc = idNode.position.y
                        curNode.setValue(xloc, forKey: "savedX")
                        curNode.setValue(yloc, forKey: "savedY")
                    }
                    
                })
            }
        }
        
        do {
            try moc.save()
        } catch let error as NSError {
            print(error)
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

    func makeNodeInter(_ inNodeInter : BNNodeInter, inPos: CGPoint){
        
//        print ("makeNodeinter")
        let labelText = (String(format: "%.3f", inNodeInter.ifthen.floatValue))
        
        let myLabel = SKLabelNode(text: labelText)
        myLabel.fontName = "SFProDisplay-Bold"
        myLabel.fontSize = 12
        myLabel.zPosition = 3
        myLabel.name = "nodeInterName"
        myLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        
        
        let nodeWidth = myLabel.frame.size.width + 15
        let nodeHeight = myLabel.frame.size.height + 15
        
        
        
        let shapeSize = CGSize(width: nodeWidth, height: nodeHeight)

        let shape = PlexusBNNodeInter(imageNamed: "PlexusNode")
        shape.scale(to: shapeSize)
        shape.name = "bnNodeInter"
        shape.position = inPos
        shape.zPosition = 1
        
        shape.isUserInteractionEnabled = false
        shape.physicsBody = SKPhysicsBody(rectangleOf: CGRect(x: -(nodeWidth/2), y: -(nodeHeight/2), width: nodeWidth, height: nodeHeight).size)
        shape.physicsBody?.mass = 1.0
        shape.physicsBody?.restitution = 0.3
        shape.physicsBody?.linearDamping = 0.9
        shape.physicsBody?.affectedByGravity = false
        shape.physicsBody?.isDynamic = true
        shape.physicsBody?.allowsRotation = false
        shape.physicsBody?.categoryBitMask = ColliderType.node.rawValue
        shape.physicsBody?.collisionBitMask = ColliderType.node.rawValue
        
        shape.nodeInter = inNodeInter
        
        self.addChild(shape)
        
        myLabel.physicsBody = SKPhysicsBody(rectangleOf: CGRect(x: -(nodeWidth/2), y: -(nodeHeight/2), width: nodeWidth, height: nodeHeight).size)
        myLabel.position = shape.position

        
        self.addChild(myLabel)
        shape.ifthenLabel = myLabel
        
        let labelJoint = SKPhysicsJointFixed.joint(withBodyA: shape.physicsBody!, bodyB:  myLabel.physicsBody!, anchor: shape.position)
        
        self.physicsWorld.add(labelJoint)
        

        
    }
    
    func makeNode(_ inNode : BNNode, inPos: CGPoint){
               

        
        let myLabel = SKLabelNode(text: inNode.name)
        myLabel.fontName = "SFProDisplay-Bold"
        myLabel.fontSize = 14
        myLabel.zPosition = 3
        myLabel.name = "nodeName"
        myLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.bottom
        
        
        let valLabel = SKLabelNode(text: inNode.value)
        valLabel.fontName = "SFProDisplay-Medium"
        valLabel.fontSize = 12
        valLabel.zPosition = 2
        valLabel.name = "nodeName"
        valLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
        
        
        
        var nodeWidth = (myLabel.frame.size.width)+15
        if(valLabel.frame.size.width > myLabel.frame.size.width) {
            nodeWidth = (valLabel.frame.size.width)+15
        }
        let nodeHeight = myLabel.frame.size.height + valLabel.frame.size.height + 15

        let shapeSize = CGSize(width: nodeWidth, height: nodeHeight)
//        print (shapeSize)
        
//        let shapePath = CGPath(roundedRect: CGRect(x: -(nodeWidth/2), y: -(nodeHeight/2), width: nodeWidth, height: nodeHeight), cornerWidth: 4, cornerHeight: 4, transform: nil)
//

        
//        let shape = PlexusBNNode(path: shapePath)
        let shape = PlexusBNNode(imageNamed: "PlexusNode")
        shape.scale(to: shapeSize)
        if inPos.x == (self.frame.width/2) && inPos.y == (self.frame.height/2) {

            var xloc = Double(inNode.savedX)
            var yloc = Double(inNode.savedY)
            if xloc <= 0 {
                xloc = Double.random(in: 1...Double(self.frame.width))
            }
            if yloc <= 0 {
                yloc = Double.random(in: 1...Double(self.frame.height))
            }
            if (xloc + Double(nodeWidth)) >= Double(self.size.width) {
                xloc = Double(self.size.width) - Double(nodeWidth)-1
            }
            if (yloc + Double(nodeHeight)) >= Double(self.size.height) {
                yloc = Double(self.size.height) - Double(nodeHeight)-1
            }

            shape.position = CGPoint(x: xloc,  y: yloc)
        }
        else {
            shape.position = inPos
        }
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
//        shape.strokeColor = NSColor.blue
//        shape.fillColor = NSColor.darkGray

        shape.node = inNode
        
        self.addChild(shape)
        
        myLabel.physicsBody = SKPhysicsBody(rectangleOf: CGRect(x: -(nodeWidth/2), y: -(nodeHeight/2), width: nodeWidth, height: nodeHeight).size)
        myLabel.position = shape.position
        
        
        self.addChild(myLabel)
        shape.nameLabel = myLabel
        
        
        valLabel.physicsBody = SKPhysicsBody(rectangleOf: CGRect(x: -(nodeWidth/2), y: -(nodeHeight/2), width: nodeWidth, height: nodeHeight).size)
        valLabel.position = shape.position
        
        
        self.addChild(valLabel)
        shape.valLabel = valLabel
        
        
        let labelJoint = SKPhysicsJointFixed.joint(withBodyA: shape.physicsBody!, bodyB:  myLabel.physicsBody!, anchor: shape.position)
        
        self.physicsWorld.add(labelJoint)
        
        let vallabelJoint = SKPhysicsJointFixed.joint(withBodyA: shape.physicsBody! , bodyB: valLabel.physicsBody!, anchor: shape.position)
        
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
     //   print(notification.userInfo)
        
      //  var justUpdate = true
//                print("bn scene MOC DID CHANGE ")

//        print("bn scene MOC DID CHANGE \(notification.userInfo)")
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
