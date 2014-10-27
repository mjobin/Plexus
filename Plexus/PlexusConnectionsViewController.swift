//
//  PlexusConnectionsViewController.swift
//  Plexus
//
//  Created by matt on 10/27/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import SpriteKit

class PlexusConnectionsViewController: NSViewController {
    
    @IBOutlet weak var skView: SKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        
        var scene: PlexusBNScene = PlexusBNScene(size: self.skView.bounds.size)
        
        scene.scaleMode = SKSceneScaleMode.Fill
        
        
        
        
        self.skView!.presentScene(scene)
        
        self.skView!.showsFPS = true
        self.skView!.showsNodeCount = true
    }
    
}
