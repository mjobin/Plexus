//
//  PlexusMainWindowController.swift
//  Plexus
//
//  Created by matt on 10/1/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusMainWindowController: NSWindowController {
    
    

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func  copyDataset(x:NSToolbarItem){
        println("copy dataset Tapped: \(x)")
        
    }
    
    @IBAction func  toggleModels(x:NSToolbarItem){
        println("Toggle models Tapped: \(x)")

        
        
        
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

}
