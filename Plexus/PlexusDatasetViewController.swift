//
//  PlexusDatasetViewController.swift
//  Plexus
//
//  Created by matt on 10/9/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import CoreData

class PlexusDatasetViewController: NSViewController {

    var moc : NSManagedObjectContext!
    dynamic var datasetController : NSArrayController!
   
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Get MOC from App delegate

        
    }
    
}
