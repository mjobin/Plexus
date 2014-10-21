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
    //var datasetController : NSArrayController?
   dynamic var datasetController : NSArrayController!
 //   @IBOutlet var entryDatasetController : NSArrayController!
    
    
    
    required init?(coder aDecoder: NSCoder)
    {

        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext

        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext

    }
    


    func  chkDataset(x:NSToolbarItem){
        println("ENTRY VIEW CONTROLLER:")
        println(datasetController)
        println(datasetController!.selectionIndexes)
        println(datasetController!.selection)
        println(datasetController!.selectedObjects)
      //  println(datasetController.selectedObjects.objectAt.0)
        
        
    //    println("ENTRY VIEW CONTROLLER duplicate:")
      //  println(entryDatasetController.selectionIndexes)
      //  println(entryDatasetController.selection)
      //  println(entryDatasetController.selectedObjects)
        
    }
    

    
}
