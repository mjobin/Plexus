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
    
    var structureViewController : PlexusStructureViewController? = nil
    
    var entryViewController : PlexusEntryViewController? = nil
    var modelViewController : PlexusModelViewController? = nil
    var entryDetailViewController : PlexusEntryDetailViewController? = nil
    var modelDetailViewController :  PlexusModelDetailViewController? = nil
    
    dynamic var datasetController : NSArrayController!
    dynamic var entryTreeController : NSTreeController!
    dynamic var modelTreeController : NSTreeController!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        //splitView.setPosition(splitView.frame.width/2, ofDividerAtIndex: 1) //initial set up leave it 50/50 for now
        //splitView.adjustSubviews()
        

        structureViewController = childViewControllers[0] as? PlexusStructureViewController
        entryViewController = childViewControllers[1] as? PlexusEntryViewController
        entryDetailViewController = childViewControllers[2] as? PlexusEntryDetailViewController
        modelDetailViewController = childViewControllers[3] as? PlexusModelDetailViewController
        modelViewController = childViewControllers[4] as? PlexusModelViewController
        
        

        

        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        structureViewController!.datasetController = self.datasetController
        entryViewController!.datasetController = self.datasetController
        modelViewController!.datasetController = self.datasetController
        
        entryTreeController = entryViewController?.entryTreeController
        entryDetailViewController!.entryTreeController = self.entryTreeController
        
        modelTreeController = modelViewController?.modelTreeController
        modelDetailViewController!.modelTreeController = self.modelTreeController
        

    }
    
    
    func  toggleStructures(x:NSToolbarItem){
        println("Toggle sctructures Tapped: \(x)")
        
        // println(self.splitViewItems.count)
        
        
        var structureListViewItem = self.splitViewItems[0] as! NSSplitViewItem  // 0 is left pane
        structureListViewItem.animator().collapsed = !structureListViewItem.collapsed
        
        
        
    }
    
    func  toggleModels(x:NSToolbarItem){
        println("Toggle models Tapped: \(x)")
        
       // println(self.splitViewItems.count)
        
        
        var modelListViewItem = self.splitViewItems[4] as! NSSplitViewItem  // 4 is right pane
        
        modelListViewItem.animator().collapsed = !modelListViewItem.collapsed
        

        
    }
    

    
  
    override func splitViewWillResizeSubviews(aNotification: NSNotification){
     //   println(aNotification)
    }

    override func splitViewDidResizeSubviews(aNotification: NSNotification){
       // println(aNotification)
    }
    
}
