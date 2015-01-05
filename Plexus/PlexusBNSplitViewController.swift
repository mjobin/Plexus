//
//  PlexusBNSplitViewController.swift
//  Plexus
//
//  Created by matt on 1/4/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusBNSplitViewController: NSSplitViewController {
    
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    
    @IBOutlet dynamic var nodesController : NSArrayController!
    
    var bnViewController : PlexusBNViewController? = nil
    var bnSingleViewController : PlexusBNSingleNodeViewController? = nil
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        bnViewController = childViewControllers[0] as? PlexusBNViewController
        bnSingleViewController = childViewControllers[1] as? PlexusBNSingleNodeViewController
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        
        
        bnViewController!.modelTreeController = self.modelTreeController
        bnViewController!.nodesController = self.nodesController
        
         bnSingleViewController!.modelTreeController = self.modelTreeController
         bnSingleViewController!.nodesController = self.nodesController


    }
}
