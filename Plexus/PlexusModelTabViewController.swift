//
//  PlexusModelTabViewController.swift
//  Plexus
//
//  Created by matt on 11/11/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusModelTabViewController: NSTabViewController {
    
    dynamic var modelTreeController : NSTreeController!
    
    var bnViewController : PlexusBNViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        bnViewController = childViewControllers[0] as? PlexusBNViewController
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        
        bnViewController!.modelTreeController = self.modelTreeController

    }
    
}
