//
//  PlexusImageViewController.swift
//  Plexus
//
//  Created by matt on 10/23/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusImageViewController: NSViewController {
 
    var moc : NSManagedObjectContext!
    
    dynamic var entryTreeController : NSTreeController!
    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        
        
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        

    }
    
}
