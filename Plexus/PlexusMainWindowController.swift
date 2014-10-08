//
//  PlexusMainWindowController.swift
//  Plexus
//
//  Created by matt on 10/1/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import CoreData

class PlexusMainWindowController: NSWindowController, ProgressViewControllerDelegate {
    
    @IBOutlet var moc : NSManagedObjectContext!
    var mainSplitViewController = PlexusMainSplitViewController()
    var progressViewController : PlexusProgressPanel?

    override func windowDidLoad() {
        super.windowDidLoad()
        
        //let appDelegate = (NSApplication.sharedApplication().delegate as AppDelegate)
        
        mainSplitViewController = contentViewController as PlexusMainSplitViewController
        
 //       let moc:NSManagedObjectContext = appDelegate.managedObjectContext!
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        println(moc.persistentStoreCoordinator)
        
       // moc.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func  copyDataset(x:NSToolbarItem){
        println("copy dataset Tapped: \(x)")
        
    }
    
    @IBAction func  toggleModels(x:NSToolbarItem){
        println("Toggle models Tapped: \(x)")

        mainSplitViewController.toggleModels(x)
        
    }
    
    @IBAction func  calculate(x:NSToolbarItem){
        println("calc Tapped: \(x)")

        //instatntiate progress controller
        if self.progressViewController == nil {
            let storyboard = NSStoryboard(name:"Main", bundle:nil)
            self.progressViewController = storyboard!.instantiateControllerWithIdentifier("ProgressViewController") as? PlexusProgressPanel
        }
        self.progressViewController?.delegate = self
       // self.presentViewControllerAsSheet(self.progressViewController!)
        
        //self.window?.beginSheet(progressViewController, completionHandler: <#((NSModalResponse) -> Void)?##(NSModalResponse) -> Void#>)
        
        self.contentViewController?.presentViewControllerAsSheet(self.progressViewController!)
        //swap it in?
        
        
        //then tear it down again
        
    }
    
    @IBAction func importCSV(x:NSToolbarItem){
        println("Tapped: \(x)")
        
        var errorPtr : NSErrorPointer = nil
        
        let op:NSOpenPanel = NSOpenPanel()
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true
        op.allowedFileTypes = ["csv"]
        op.runModal()
        
        var inFile = op.URL
        
        if (inFile != nil){ // operate on iput file
            
            /*
            
        
            
            
            let theStreamReader = StreamReader(path: inFile.path!)
            
            while let line = theStreamReader.nextLine() {
            //println(line)
            
            // var newEntry : NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Entry", inManagedObjectContext: moc) as NSManagedObject
            
            NSManagedObject(entity: NSEntityDescription.entityForName("Dataset", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
            
            
            
            theStreamReader.close()
            moc.save(errorPtr)
            }
            */
            
        }
        
    }
    
    func progressViewControllerDidCancel(progressViewController: PlexusProgressPanel) {
        println("Cancelled progress")
        self.contentViewController?.dismissViewController(self.progressViewController!)
    }

}
