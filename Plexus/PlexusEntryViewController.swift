//
//  PlexusEntryViewController.swift
//  Plexus
//
//  Created by matt on 10/9/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusEntryViewController: NSViewController {

    var moc : NSManagedObjectContext!
    
    
    required init?(coder aDecoder: NSCoder)
    {
        println("coder")
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        println(moc)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        println(moc)
    }
    
}
