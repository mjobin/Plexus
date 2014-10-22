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
    @IBOutlet dynamic var entryTreeController : NSTreeController!
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

        
    }
    
    @IBAction func addEntry(sender : AnyObject){
        println("add entry")
        
    }
    
    @IBAction func removeEntry(sender : AnyObject){
        println("remove entry")
        
    }
    
    @IBAction func addChildEntry(sender : AnyObject){
        println("add child entry")
        
    }

    
}
