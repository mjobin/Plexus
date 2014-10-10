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
    
    

  
    var moc : NSManagedObjectContext!
    var mainSplitViewController = PlexusMainSplitViewController()
    var progressViewController : PlexusProgressPanel?

    
    override func windowWillLoad() {

        //Get MOC from App delegate
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        println(moc)
        
       // perfromsegue?????

       // mainSplitViewController = contentViewController as PlexusMainSplitViewController
       // mainSplitViewController.moc = moc

        
        //create a dataset if there are none
        let request = NSFetchRequest(entityName: "Dataset")
        var anyError: NSError?
        let fetchedDatasets = moc.executeFetchRequest(request, error:&anyError)
        
        if fetchedDatasets == nil {
            println("error")

        }
        
        let initDatasets = fetchedDatasets as [NSManagedObject]
        if(initDatasets.count == 0){
            println("no datasets")
            //so make an initial one
            let newDataset = NSEntityDescription.insertNewObjectForEntityForName("Dataset", inManagedObjectContext: moc) as NSManagedObject
            moc.save(&anyError)

        }
        
        
        
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        

        
        mainSplitViewController = contentViewController as PlexusMainSplitViewController
        

        
    
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
        
        var inFile  = op.URL
        
        if (inFile != nil){ // operate on iput file
            
           var newDataset : NSManagedObject = NSManagedObject(entity: NSEntityDescription.entityForName("Dataset", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
            newDataset.setValue(inFile!.lastPathComponent, forKey: "name")
            /*
            
        
            
            
            let theStreamReader = StreamReader(path: inFile.path!)
            
            while let line = theStreamReader.nextLine() {
            //println(line)
            
            // var newEntry : NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Entry", inManagedObjectContext: moc) as NSManagedObject
            
            
            
            
            
            theStreamReader.close()
            moc.save(errorPtr)
            }
            */
            moc.save(errorPtr)
        }
        
    }
    
    func progressViewControllerDidCancel(progressViewController: PlexusProgressPanel) {
        println("Cancelled progress")
        self.contentViewController?.dismissViewController(self.progressViewController!)
    }

}
