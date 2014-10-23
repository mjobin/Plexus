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
   dynamic var datasetController : NSArrayController!
    @IBOutlet dynamic var entryTreeController : NSTreeController!
    @IBOutlet var iconController : NSArrayController!

    var iconDictionary : NSMutableDictionary!
    
    
    
    
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
        
        
        var iconImages = NSArray(objects: NSImage(named: "PlexusTest")!, NSImage(named: "PlexusTest")!)
            var iconKeys = NSArray(objects: "entry", "site")
        iconDictionary = NSMutableDictionary(objects: iconImages, forKeys: iconKeys)

       // println(iconDictionary)
        

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
