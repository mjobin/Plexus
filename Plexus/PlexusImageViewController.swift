//
//  PlexusImageViewController.swift
//  Plexus
//
//  Created by matt on 10/23/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import Quartz
import AppKit

class PlexusImageViewController: NSViewController {
 
    var moc : NSManagedObjectContext!
    
    dynamic var entryTreeController : NSTreeController!
    @IBOutlet var imageController : NSArrayController!
    @IBOutlet var imageBrowser: IKImageBrowserView!
    
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        
        
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        imageBrowser.setDelegate(self)
        

    }
    
    @IBAction func addImages(sender: AnyObject){

        
        var errorPtr : NSErrorPointer = nil
        
        let op:NSOpenPanel = NSOpenPanel()
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true
       // op.allowedFileTypes = ["csv"]
        op.runModal()
        
        var inFile = op.URL
        
        op.orderOut(self)
        op.close()
        
        
        if (inFile != nil){ // operate on iput file
            
            var newImage : Image = Image(entity: NSEntityDescription.entityForName("Image", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc)
            newImage.setValue(inFile!.lastPathComponent, forKey: "imageName")
            
            var newRep : NSData = NSData(contentsOfURL: inFile!)!
            newImage.setValue(newRep, forKey: "imageRepresentation")
        
            
            imageController.addObject(newImage)
            
            moc.save(errorPtr)
            
        }
    }
    /*
    override func numberOfItemsInImageBrowser(view: IKImageBrowserView) -> Int {
        //return imageController.
    }
    override func imageBrowser(view: IKImageBrowserView, itemAtIndex index: Int) -> AnyObject {
        return imageContro
    }
    */
    
}
