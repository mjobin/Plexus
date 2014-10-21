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
    var datasetObject : NSManagedObject? = nil
    
   //@IBOutlet var datasetController : NSArrayController?
    dynamic var datasetController : NSArrayController!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        splitView.setPosition(splitView.frame.width/2, ofDividerAtIndex: 1) //initial set up leave it 50/50 for now
        splitView.adjustSubviews()
        
       // let wc = view.window!.windowController
        /*
        let window = self.view.window as NSWindow
        println(window)
        let wc = window.windowController
        
        println("mwc from msvc")
       // println(mainWindowController)
        println(wc)
        */
        
        entryViewController = childViewControllers[0] as? PlexusEntryViewController
        

        

        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        entryViewController!.datasetController = self.datasetController
       // println(self.datasetController)
       // println(entryViewController!.datasetController)
    }
    
    
    func  toggleModels(x:NSToolbarItem){
        println("Toggle models Tapped: \(x)")
        
       // println(self.splitViewItems.count)
        
        
        var modelListViewItem = self.splitViewItems[3] as NSSplitViewItem  // 3 is right pane
        
        modelListViewItem.animator().collapsed = !modelListViewItem.collapsed
        

        
        
        

        
    }
    
    func  chkDataset(x:NSToolbarItem){
        println("MAIN SPLIT VIEW CONTROLLER:")
        println(datasetController)
        println(datasetController!.selectionIndexes)
        println(datasetController!.selection)
        println(datasetController!.selectedObjects)
        
        entryViewController!.chkDataset(x)
        
    }
    
}
