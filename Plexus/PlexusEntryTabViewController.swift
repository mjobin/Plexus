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
    var notesViewController : PlexusNotesViewController? = nil
    var imageViewController : PlexusImageViewController? = nil
    var mapViewController : PlexusMapViewController? = nil
    
    dynamic var entryTreeController : NSTreeController!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        traitViewController = childViewControllers[0] as? PlexusTraitViewController
        notesViewController = childViewControllers[1] as? PlexusNotesViewController
        imageViewController = childViewControllers[2] as? PlexusImageViewController
        mapViewController = childViewControllers[3] as? PlexusMapViewController
        
        

    }
    
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        
        traitViewController!.entryTreeController = self.entryTreeController
        notesViewController!.entryTreeController = self.entryTreeController
        imageViewController!.entryTreeController = self.entryTreeController
        mapViewController!.entryTreeController = self.entryTreeController
    }
    
}
