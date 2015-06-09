//
//  PlexusNotesViewController.swift
//  Plexus
//
//  Created by matt on 6/8/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusNotesViewController: NSViewController {
    
    var moc : NSManagedObjectContext!
    
    dynamic var entryTreeController : NSTreeController!
    
    @IBOutlet var textView: NSTextView!
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        moc = appDelegate.managedObjectContext
        
        
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    /*
    @IBAction func addImages(sender: AnyObject){
        
        
        var errorPtr : NSErrorPointer = nil
        
        let op:NSOpenPanel = NSOpenPanel()
        op.allowsMultipleSelection = false
        op.canChooseDirectories = false
        op.canChooseFiles = true

        op.runModal()
        
        var inFile = op.URL
        
        op.orderOut(self)
        op.close()
        
        
        if (inFile != nil){ // operate on iput file
            
            let newImage : NSImage = NSImage(contentsOfURL: inFile!)!
            let newTAC = NSTextAttachmentCell(imageCell: newImage)
            var newTA = NSTextAttachment()
            newTA.attachmentCell = newTAC
            textView.textStorage?.appendAttributedString(NSAttributedString(attachment: newTA))
            
           
            
            
            moc.save(errorPtr)
            
        }
    }
    */

    
}
