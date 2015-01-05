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

    
  
    var bnSplitViewController : PlexusBNSplitViewController? = nil
    var modelTableViewController : PlexusModelTableViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bnSplitViewController = childViewControllers[0] as? PlexusBNSplitViewController
        modelTableViewController = childViewControllers[1] as? PlexusModelTableViewController
        
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        
       
        bnSplitViewController!.modelTreeController = self.modelTreeController
        modelTableViewController!.modelTreeController = self.modelTreeController

    }
    
}
