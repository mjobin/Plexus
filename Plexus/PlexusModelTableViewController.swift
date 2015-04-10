//
//  PlexusModelTableViewController.swift
//  Plexus
//
//  Created by matt on 12/26/2014.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusModelTableViewController: NSViewController {
    
    var moc : NSManagedObjectContext!
    
    dynamic var modelTreeController : NSTreeController!
    dynamic var nodesController : NSArrayController!

    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        

    }
    
}
