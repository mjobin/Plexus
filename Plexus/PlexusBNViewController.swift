//
//  PlexusBNViewController.swift
//  Plexus
//
//  Created by matt on 10/2/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import SpriteKit

class PlexusBNViewController: NSViewController {
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    dynamic var nodesController : NSArrayController!
    
    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var visView: NSVisualEffectView!
    var scene: PlexusBNScene!
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        

        

        visView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
        visView.material = NSVisualEffectMaterial.Dark
        visView.state = NSVisualEffectState.Active

        
        scene = PlexusBNScene(size: self.skView.bounds.size)
        
        

        
         scene.scaleMode = SKSceneScaleMode.ResizeFill
        //FIXME this was what was causing nodes to fall off the screen
      //  scene.scaleMode = SKSceneScaleMode.Fill
        

        
       // var skt : SKTransition = SKTransition.flipHorizontalWithDuration(2)
       // self.skView!.presentScene(scene, transition: skt)

        
        self.skView!.presentScene(scene)
        
        self.skView!.showsFPS = true
        self.skView!.showsNodeCount = true
        
      //  self.performSegueWithIdentifier("NodeData", sender: self)
        

    }
    override func viewDidAppear() {
        super.viewDidAppear()

        scene.modelTreeController = self.modelTreeController
        scene.nodesController = self.nodesController
        
        let options = NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old
        modelTreeController.addObserver(self, forKeyPath: "selectionIndexPath", options: options, context: nil)


    }
    
    
    override func viewDidLayout() {
       // println("bnvc views bounds widths: \(view.bounds.width) \(visView.bounds.width) \(skView.bounds.width)")
        scene.redrawNodes()
        
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
        switch (keyPath) {
        case("selectionIndexPath"):
            scene.reloadData()
            
            
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }


    

}
