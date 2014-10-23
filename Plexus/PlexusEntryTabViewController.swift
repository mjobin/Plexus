//
//  PlexusEntryTabViewController.swift
//  Plexus
//
//  Created by matt on 10/21/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusEntryTabViewController: NSTabViewController {

    
    var traitViewController : PlexusTraitViewController? = nil
    var imageViewController : PlexusImageViewController? = nil
    
    dynamic var entryTreeController : NSTreeController!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        traitViewController = childViewControllers[0] as? PlexusTraitViewController
        imageViewController = childViewControllers[3] as? PlexusImageViewController
        

    }
    
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        
        traitViewController!.entryTreeController = self.entryTreeController
        imageViewController!.entryTreeController = self.entryTreeController
    }
    
}
