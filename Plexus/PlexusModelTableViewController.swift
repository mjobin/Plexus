//
//  PlexusModelTableViewController.swift
//  Plexus
//
//  Created by matt on 12/26/2014.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Cocoa

class PlexusModelTableViewController: NSViewController {
    
    let appDelegate : AppDelegate = NSApplication.shared.delegate as! AppDelegate
    var moc : NSManagedObjectContext!
    
    @objc dynamic var modelTreeController : NSTreeController!
    @objc dynamic var nodesController : NSArrayController!

    
    required init?(coder aDecoder: NSCoder)
    {

        moc = appDelegate.persistentContainer.viewContext
        
        super.init(coder: aDecoder)
    }
    
    
}
