//
//  PlexusMainSplitViewController.swift
//  Plexus
//
//  Created by matt on 10/1/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa


class PlexusMainSplitViewController: NSSplitViewController {
    
    
    var mainWindowController : PlexusMainWindowController? = nil
    var entryViewController : PlexusEntryViewController? = nil
    var modelViewController : PlexusModelViewController? = nil
    var entryTabViewController : PlexusEntryTabViewController? = nil
    var modelTabViewController :  PlexusModelTabViewController? = nil
    
    dynamic var datasetController : NSArrayController!
    dynamic var entryTreeController : NSTreeController!
    dynamic var modelTreeController : NSTreeController!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        splitView.setPosition(splitView.frame.width/2, ofDividerAtIndex: 1) //initial set up leave it 50/50 for now
        splitView.adjustSubviews()
        

        
        entryViewController = childViewControllers[0] as? PlexusEntryViewController
        entryTabViewController = childViewControllers[1] as? PlexusEntryTabViewController
        modelTabViewController = childViewControllers[2] as? PlexusModelTabViewController
        modelViewController = childViewControllers[3] as? PlexusModelViewController
        
        

        

        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        entryViewController!.datasetController = self.datasetController
        modelViewController!.datasetController = self.datasetController
        
        entryTreeController = entryViewController?.entryTreeController
        entryTabViewController!.entryTreeController = self.entryTreeController
        
        modelTreeController = modelViewController?.modelTreeController
        modelTabViewController!.modelTreeController = self.modelTreeController
        

    }
    
    
    func  toggleModels(x:NSToolbarItem){
        println("Toggle models Tapped: \(x)")
        
       // println(self.splitViewItems.count)
        
        
        var modelListViewItem = self.splitViewItems[3] as NSSplitViewItem  // 3 is right pane
        
        modelListViewItem.animator().collapsed = !modelListViewItem.collapsed
        

        
    }
    

    
}
