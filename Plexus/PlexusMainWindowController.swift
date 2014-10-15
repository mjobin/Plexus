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
       // println("Tapped: \(x)")
        
        var errorPtr : NSErrorPointer = nil
        
        let op:NSOpenPanel = NSOpenPanel()
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true
        op.allowedFileTypes = ["csv"]
        op.runModal()
        
        var inFile  = op.URL
        
        op.orderOut(self)
        op.close()
        
        if (inFile != nil){ // operate on iput file
            
            
            //instatntiate progress controller
            if self.progressViewController == nil {
                let storyboard = NSStoryboard(name:"Main", bundle:nil)
                self.progressViewController = storyboard!.instantiateControllerWithIdentifier("ProgressViewController") as? PlexusProgressPanel
            }
            self.progressViewController?.delegate = self
                       
            
            self.contentViewController?.presentViewControllerAsSheet(self.progressViewController!)
            
            
           var newDataset : NSManagedObject = NSManagedObject(entity: NSEntityDescription.entityForName("Dataset", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
            newDataset.setValue(inFile!.lastPathComponent, forKey: "name")
            

            
            let fileContents : String = NSString(contentsOfFile: inFile!.path!, encoding: NSUTF8StringEncoding, error: nil)!
           // print(fileContents)
            var fileLines : [String] = fileContents.componentsSeparatedByString("\n")
            
            var lineCount = Double(fileLines.count)
            
            for thisLine : String in fileLines {
                var newEntry : NSManagedObject = NSManagedObject(entity: NSEntityDescription.entityForName("Entry", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
                newEntry.setValue("test", forKey: "name")
                //  println(thisLine)
                //  println("\n********************************************\n")
                
                var theTraits : [String] = thisLine.componentsSeparatedByString(",")
                for thisTrait in theTraits {
                 //println(thisTrait)
                    var newTrait : NSManagedObject = NSManagedObject(entity: NSEntityDescription.entityForName("Trait", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
                    newTrait.setValue("test", forKey: "name")
                    newTrait.setValue(thisTrait, forKey: "value")
                    newTrait.setValue(newEntry, forKey: "entry")
                    
                
                    //FIXME then add trait to entry
                }
                
                self.progressViewController!.progressBar.incrementBy(lineCount)
              
            }



            moc.save(errorPtr)
        }
        
        
        self.contentViewController?.dismissViewController(self.progressViewController!)
        
        
    }
    
    func progressViewControllerDidCancel(progressViewController: PlexusProgressPanel) {
        println("Cancelled progress")
        self.contentViewController?.dismissViewController(self.progressViewController!)
    }

}
