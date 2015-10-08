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
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()


        
    }
    
@IBAction func newDataset (sender: AnyObject){
            let newDataset : Dataset = Dataset(entity: NSEntityDescription.entityForName("Dataset", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
    
    
    newDataset.setValue("new", forKey: "name")
    newDataset.setValue(NSDate(), forKey: "dateCreated")
    
    
    datasetController.insert(newDataset)
    

}
    
@IBAction func removeDataset (sender: AnyObject) {
    
   // let errorPtr : NSErrorPointer = nil
    

    if(datasetController.arrangedObjects.count > 1){
        var delDatasets = datasetController.selectedObjects as! [Dataset]
        let delDataset: Dataset = delDatasets[0]
    
        datasetController.removeObject(delDataset)
        
        do {
            try self.moc.save()
        } catch let error as NSError {
            print(error)
        }
    }
}
        
    
    
@IBAction func copyDataset (sender: AnyObject){
    
    //let errorPtr : NSErrorPointer = nil

    
        
        let oldDatasets : [Dataset] = datasetController.selectedObjects as! [Dataset]
        let oldDataset : Dataset = oldDatasets[0]

    
    
        let newDataset : Dataset = Dataset(entity: NSEntityDescription.entityForName("Dataset", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
    
    let copyName : String = oldDataset.name + " copy"
    
        newDataset.setValue(copyName, forKey: "name")

        let oldEntries  = oldDataset.entry.allObjects as! [Entry]
        for oldEntry : Entry in oldEntries {

            if(oldEntry.parent.count == 0){
                
                let noParent : NSSet = NSSet()
                
                print(oldEntry.name)
                
                recurEntry(oldDataset, newDataset: newDataset, inEntry: oldEntry, parent: noParent)
            }

        }
    
    datasetController.addObject(newDataset)
    do {
        try self.moc.save()
    } catch let error as NSError {
        print(error)
    }
  
        
    }
    
    
    
    func recurEntry(inDataset: Dataset, newDataset: Dataset, inEntry : Entry, parent: NSSet){
        
        
        
        let newEntry : Entry = Entry(entity: NSEntityDescription.entityForName("Entry", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
        
        

        newEntry.setValue(inEntry.name, forKey: "name")
        newEntry.setValue("Entry", forKey: "type")
        newEntry.setValue(newDataset, forKey: "dataset")
        newDataset.addEntryObject(newEntry)
        
        print(newEntry.name)
        
        //Set parents and children

        if(parent.count > 0){
            
            let theParents : [Entry]  = parent.allObjects as! [Entry]
            let theParent : Entry = theParents[0] as Entry
            newEntry.setValue(theParent, forKey: "parent")
            print("parent \(theParent.name)")
            theParent.addChildObject(newEntry)

        }
        
        else {
            newEntry.setValue(nil, forKey: "parent")
        }
        
        let oldTraits  = inEntry.trait.allObjects as! [Trait]
        for oldTrait : Trait in oldTraits {
            let newTrait : Trait = Trait(entity: NSEntityDescription.entityForName("Trait", inManagedObjectContext: self.moc)!, insertIntoManagedObjectContext: self.moc)
            newTrait.setValue(oldTrait.name, forKey: "name")
            newTrait.setValue(oldTrait.traitValue, forKey: "traitValue")
            newTrait.setValue(newEntry, forKey: "entry")
            newEntry.addTraitObject(newTrait)
        }
        
        let newParent  = NSMutableSet()
        newParent.addObject(newEntry)
        
        if(inEntry.children.count > 0){
            let childEntries  = inEntry.children.allObjects as! [Entry]
            for kid : Entry in childEntries{
                recurEntry(inDataset, newDataset: newDataset, inEntry: kid, parent: newParent)
            }
            
        }

    }
}


