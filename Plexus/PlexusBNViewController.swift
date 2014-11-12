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
    
    dynamic var modelTreeController : NSTreeController!
    
    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var visView: NSVisualEffectView!

    override func viewDidLoad() {
        super.viewDidLoad()
        

        visView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
        
            

        visView.material = NSVisualEffectMaterial.Dark
        

        visView.state = NSVisualEffectState.Active

        
        var scene: PlexusBNScene = PlexusBNScene(size: self.skView.bounds.size)

        
         scene.scaleMode = SKSceneScaleMode.ResizeFill
        
        
       // var skt : SKTransition = SKTransition.flipHorizontalWithDuration(2)
       // self.skView!.presentScene(scene, transition: skt)

        
        self.skView!.presentScene(scene)
        
        self.skView!.showsFPS = true
        self.skView!.showsNodeCount = true
        

    }
    
}
