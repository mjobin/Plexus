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


        
    }
    
@IBAction func copyDataset (sender: AnyObject){
    
    var errorPtr : NSErrorPointer = nil
        
        let oldDatasets : [Dataset] = datasetController.selectedObjects as [Dataset]
        let oldDataset : Dataset = oldDatasets[0]
      //  println(oldDataset.name)
    
    
        var newDataset : Dataset = Dataset(entity: NSEntityDescription.entityForName("Dataset", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
    
    let copyName : String = oldDataset.name + " copy"
    
        newDataset.setValue(copyName, forKey: "name")
    
    
    

        let oldEntries  = oldDataset.entry.allObjects as [Entry]
        for oldEntry : Entry in oldEntries {
            

            if(oldEntry.parent.count == 0){
                
               // println("-------")
                
                let noParent : NSSet = NSSet()
                
                recurEntry(oldDataset, newDataset: newDataset, inEntry: oldEntry, parent: noParent)
            }
            
            


        }
    
    datasetController.addObject(newDataset)
    self.moc.save(errorPtr)
  
        
    }
    
    
    
    func recurEntry(inDataset: Dataset, newDataset: Dataset, inEntry : Entry, parent: NSSet){
        
        //Make copied Entry
        var newEntry : Entry = Entry(entity: NSEntityDescription.entityForName("Entry", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)

        newEntry.setValue(inEntry.name, forKey: "name")
        newEntry.setValue("PlexusEntry", forKey: "icon")
        newEntry.setValue(newDataset, forKey: "dataset")
        newDataset.addEntryObject(newEntry)
        
        //Set parents and children
        

        if(parent.count > 0){
            
            
            let theParents : [Entry]  = parent.allObjects as [Entry]
            let theParent : Entry = theParents[0] as Entry
            newEntry.setValue(theParent, forKey: "parent")
            theParent.addChildObject(newEntry)

        }
        
        
        
        
        
        let oldTraits  = inEntry.trait.allObjects as [Trait]
        for oldTrait : Trait in oldTraits {
            var newTrait : Trait = Trait(entity: NSEntityDescription.entityForName("Trait", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
            newTrait.setValue(oldTrait.name, forKey: "name")
            newTrait.setValue(oldTrait.value, forKey: "value")
            newTrait.setValue(newEntry, forKey: "entry")
            newEntry.addTraitObject(newTrait)
        }
        
        var newParent  = NSMutableSet()
        newParent.addObject(newEntry)
        
        if(inEntry.children.count > 0){
            
            
          //  println(inEntry.name)
            
            let childEntries  = inEntry.children.allObjects as [Entry]
            for kid : Entry in childEntries{
                recurEntry(inDataset, newDataset: newDataset, inEntry: kid, parent: newParent)
            }
            
        }

    }
}


