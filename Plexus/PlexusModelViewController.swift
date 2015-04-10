//
//  PlexusModelViewController.swift
//  Plexus
//
//  Created by matt on 10/15/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusModelViewController: NSViewController {

    var moc : NSManagedObjectContext!
    dynamic var datasetController : NSArrayController!
    @IBOutlet dynamic var modelTreeController : NSTreeController!
    
    
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
    
}
