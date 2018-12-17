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
    @objc dynamic var modelTreeController : NSTreeController!
    @objc dynamic var nodesController : NSArrayController!


    
    var firstUpdate = true


    var dragStart = CGPoint(x: 0.0, y: 0.0)
    var startNode = SKNode()
    var movingNode = SKNode()


    var d1 : CGFloat = 0.3
    var d2 : CGFloat = 0.8
    
    
    /**
     Sets MOC as primary MOC. Adds observers for MOC changing and saving.
     
     - Parameter view: SKView linked to this SKScene.

     */
    override func didMove(to view: SKView) {

    
        let appDelegate : AppDelegate = NSApplication.shared.delegate as! AppDelegate
        moc = appDelegate.persistentContainer.viewContext
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlexusBNScene.mocDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: moc)
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveData), name: NSApplication.willTerminateNotification, object: nil)


        firstUpdate = true
        
        
        self.backgroundColor = SKColor.clear
        startNode = self
        movingNode = self

    }
    
//    override func didChangeSize(_ oldSize: CGSize) {
//
//    }


    /**
     Screens out key events when Model is complete.
     
     - Parameter theEvent: New key event.
     
     */
    override func keyDown(with theEvent: NSEvent) {
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        if(curModel.complete == true){
            return
        }
        
        interpretKeyEvents([theEvent])
    }
    
    /**
     Delete node from Model and MOC.
     
     - Parameter theEvent: New key event.
     
     */
    override func deleteBackward(_ sender: Any?) {
        
        
        let selNodes : [BNNode]  = nodesController.selectedObjects as! [BNNode]
        for selNode : BNNode in selNodes{
            
            nodesController.removeObject(selNode)
            let appDelegate : AppDelegate = NSApplication.shared.delegate as! AppDelegate
            moc = appDelegate.persistentContainer.viewContext
            moc.delete(selNode)
            
        }
        
        
        self.reloadData()
    }
    
    /**
     
     Interprets mouse down events. Passed touchedNode down from labels to PlexusBNNode if needed.
     Selects node if one click, performs dblClickAction if doubled.
     
     - Parameter theEvent: New key event.
     
     */
    override func mouseDown(with theEvent: NSEvent) {
        

        
        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]

        let loc = theEvent.location(in: self)
        dragStart = loc
       
        var touchedNode : SKNode = self.atPoint(loc)

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
                    

                    if(theNode.name == "bnNode")
                    {
                        touchedNode = theNode //switch to the bnNode in the position of the label
                    }
                }
                
            }
            
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
    
    
    /**
     
     Active during drag.
     Draws arrow to cursor if command-dragging. Otherwise moves dragged node.
     
     - Parameter theEvent: New key event.
     
     */
    override func mouseDragged(with theEvent: NSEvent) {
        

        let loc : CGPoint = theEvent.location(in: self)
        var touchedNode : SKNode = self.atPoint(loc)

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


            if touchedNode.name == "bnNode"{
                movingNode = touchedNode
//                print("mouseDragged start: \(String(describing: startNode.name)) touched \(String(describing: touchedNode.name))     moving: \(String(describing: movingNode.name)))\n")
                let bnNode = touchedNode as! PlexusBNNode
                bnNode.position = loc
                bnNode.nameLabel.position = loc
                bnNode.valLabel.position = loc
            }
        }
        
    }
    
    
    /**
     
     Creates an influence arrow between nodes if drag started on a node and ended ona different one.
     
     - Parameter theEvent: New key event.
     
     */
    override func mouseUp(with theEvent: NSEvent) {
        

        
        movingNode = self

        let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
        let curModel : Model = curModels[0]
        if(curModel.complete == true){
            return
        }
 
        
        let loc = theEvent.location(in: self)
        
        
        
        
        var releasedNode : SKNode = self.atPoint(loc)
        
        if(releasedNode.name == "nodeLine"){//passing mouseUp to node if in same area
            let allNodes : [SKNode] = self.nodes(at: releasedNode.position)
            for theNode : SKNode in allNodes {
                if(theNode.name == "bnNode")
                {
                    releasedNode = theNode //switch to the bnNode in the position of the label
                }
            }
        }
        
        if(releasedNode.name == "nodeName"){//passing mouseDown to node beenath
            let allNodes : [SKNode] = self.nodes(at: releasedNode.position)
            for theNode : SKNode in allNodes {
                if(theNode.name == "bnNode")
                {
                    releasedNode = theNode //switch to the bnNode in the position of the label
                }
            }
        }
        
//        print ("mouseUp    start node: \(startNode)      released node: \(releasedNode)")
        
        if(!startNode.isEqual(to: self) && startNode.name == "bnNode" && !releasedNode.isEqual(to: self) && releasedNode.name == "bnNode" && !startNode.isEqual(to: releasedNode) ) {

            
            //now add the necessary relationships in the data
            let startIDNode : PlexusBNNode = startNode as! PlexusBNNode
            let releasedIDNode : PlexusBNNode = releasedNode as! PlexusBNNode
            
            
            _ = startIDNode.node.addADownObject(downNode: releasedIDNode.node, moc: moc)
            _ = releasedIDNode.node.addAnUpObject(upNode: startIDNode.node, moc: moc)

            
            if(startIDNode.node.DFTcyclechk([startIDNode.node]) || releasedIDNode.node.DFTcyclechk([releasedIDNode.node])){
                
                startIDNode.node.removeADownObject(downNode: releasedIDNode.node, moc: moc)
                releasedIDNode.node.removeAnUpObject(upNode: startIDNode.node, moc: moc)
                
            }
            
            do {
                try moc.save()
            } catch let error as NSError {
                print(error)
            }
            
            
        }
        

        
        //remove all existing lines
        
        self.enumerateChildNodes(withName: "joinLine", using: { thisLine, stop in
            thisLine.removeFromParent()
        })
        
     
        
        
        //reset startnode
        startNode = self
        releasedNode = self

    }
    

    /**
     
     This just removes the nodes so that update can restore them. Preserves position.
     
     
     */
    func reloadDataWPos() {

        
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
            let idNode : PlexusBNNode = thisLine as! PlexusBNNode
            let oldPoint : CGPoint = idNode.position
            let oldNode : BNNode = idNode.node
            thisLine.removeFromParent()

            self.makeNode(oldNode, inPos: oldPoint)
            
            //update will catch undrawn nodes
        
        })

        
    }
   
    /**
     
     Removes all Nodes and NodeInters.
     
     
     */
    func reloadData(){
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
        

    }
    
    
    /**
     
     Runs periodically. Removes lines and score labels, then adds again in new positions if needed.
     Ensures nodes in controller have all been drawn and connected by NodeInters.
     
     
     */
    override func update(_ currentTime: TimeInterval) {
        
        
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
                    
                        let theDownNodes = curNode.downNodes(self)
                        for thisDownNode in theDownNodes {

                            
                            var infNode : PlexusBNNode!
                            self.enumerateChildNodes(withName: "bnNode", using: { thatNode, stop in
                                
                                let thatidNode : PlexusBNNode = thatNode as! PlexusBNNode
                                
                                if(thatidNode.node == thisDownNode){
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

                                    if let interNode = idNode.node.getDownInterBetween(downNode: infNode.node){
                                        var foundinter = false
                                        
                                        self.enumerateChildNodes(withName: "bnNodeInter", using: { thisNodeInter, stop in
                                            
                                            let thisidNodeInter : PlexusBNNodeInter = thisNodeInter as! PlexusBNNodeInter
                                            
                                            if(thisidNodeInter.nodeInter == interNode){ //Found it, just set its position
                                                foundinter = true
                                                thisidNodeInter.position = CGPoint(x: theX,  y: theY)
                                            }
     
                                        })
                                        

                                        
                                        if foundinter == false {
                                            let interNode = idNode.node.addADownObject(downNode: infNode.node, moc: moc)

                                            //Create display node for this Nodeinter
                                            self.makeNodeInter(interNode, inPos: CGPoint(x: theX,  y: theY))
                                            
                                            
                                        }
                                        
                                    }
                                    else {
                                                let interNode = idNode.node.addADownObject(downNode: infNode.node, moc: moc)
                                                //Create display node for this Nodeinter
                                                self.makeNodeInter(interNode, inPos: CGPoint(x: theX,  y: theY))
                                        
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
        

    }
  
    
    /**
     
     Saves position of nodes to MOC.
     
     */
    @objc func saveData () {
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


    /**
     Creates a PlexusBNNodeInter from the associated BNNodeInter and a saved position.
     The former is view, the latter is model.
     
     - Parameter inNodeInter: BNNodeInter that needs visual representation.
     - Parameter inPos: Input position.

    
     */
    func makeNodeInter(_ inNodeInter : BNNodeInter, inPos: CGPoint){
        

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

        
        shape.nodeInter = inNodeInter
        
        self.addChild(shape)

        myLabel.position = shape.position

        
        self.addChild(myLabel)
        shape.ifthenLabel = myLabel
        

        
    }
    
    
    /**
     Creates a PlexusBNNode from the associated BNNode and a saved position.
     The former is view, the latter is model.
     
     - Parameter inNode: BNNode that needs visual representation.
     - Parameter inPos: Input position.
     
     
     */
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

            var xloc = Double(truncating: inNode.savedX)
            var yloc = Double(truncating: inNode.savedY)
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

        shape.name = "bnNode"

        shape.node = inNode
        
        self.addChild(shape)
        
        myLabel.position = shape.position
        
        
        self.addChild(myLabel)
        shape.nameLabel = myLabel
        
        valLabel.position = shape.position
        
        
        self.addChild(valLabel)
        shape.valLabel = valLabel
        
    }

    //Unused (for now function for calculating angle and distance between nodes to animate them.
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
    

    /**
     If MOC changes, checks if nodes are deleted and resets score.
     
     - Parameter notification: Incoming Notification
     
     */
    @objc func mocDidChange(_ notification: Notification){
        
//        print (notification)
 
        if let _ = (notification as NSNotification).userInfo?[NSDeletedObjectsKey] as? NSSet {
            let curModels : [Model] = modelTreeController.selectedObjects as! [Model]
            let curModel : Model = curModels[0]
            curModel.setValue(NSNumber.init(floatLiteral: -Double.infinity), forKey: "score")
            self.reloadData()
        }
        
        else if let _ = (notification as NSNotification).userInfo?[NSInsertedObjectsKey] as? NSSet {
            self.reloadDataWPos()
        }
//        else {
//
//            self.reloadDataWPos()
//
//        }

    }


}
