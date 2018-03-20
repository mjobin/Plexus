//
//  PlexusMainSplitViewController.swift
//  Plexus
//
//  Created by matt on 10/1/14.
//  Copyright (c) 2014 Matthew Jobin. All rights reserved.
//

import Cocoa


class PlexusMainSplitViewController: NSSplitViewController {
    
    
    var mainWindowController : PlexusMainWindowController? = nil
    
    var structureViewController : PlexusStructureViewController? = nil
    
    var entryViewController : PlexusEntryViewController? = nil
    var modelViewController : PlexusModelViewController? = nil
    var entryDetailViewController : PlexusEntryDetailViewController? = nil
    var modelDetailViewController :  PlexusModelDetailViewController? = nil
    
    dynamic var entryTreeController : NSTreeController!
    dynamic var modelTreeController : NSTreeController!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        structureViewController = childViewControllers[0] as? PlexusStructureViewController
        entryViewController = childViewControllers[1] as? PlexusEntryViewController
        entryDetailViewController = childViewControllers[2] as? PlexusEntryDetailViewController
        modelDetailViewController = childViewControllers[3] as? PlexusModelDetailViewController
        modelViewController = childViewControllers[4] as? PlexusModelViewController
        
        
        let structureListViewItem = self.splitViewItems[0] // 0 is left pane
        structureListViewItem.isCollapsed = true

        let modelListViewItem = self.splitViewItems[4] // 4 is right pane
        modelListViewItem.isCollapsed = true

        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        
        entryTreeController = entryViewController?.entryTreeController
        entryDetailViewController!.entryTreeController = self.entryTreeController
        
        modelTreeController = modelViewController?.modelTreeController
        modelDetailViewController!.modelTreeController = self.modelTreeController
        structureViewController!.modelTreeController = self.modelTreeController
        entryViewController!.modelTreeController = self.modelTreeController
        

    }
    
    
    func  toggleStructures(_ x:NSToolbarItem) {
 
        let structureListViewItem = self.splitViewItems[0] // 0 is left pane
        structureListViewItem.animator().isCollapsed = !structureListViewItem.isCollapsed
        
    }
    
    func  toggleModels(_ x:NSToolbarItem){
        
        let modelListViewItem = self.splitViewItems[4] // 4 is right pane
        modelListViewItem.animator().isCollapsed = !modelListViewItem.isCollapsed
        
    }
    

    
  
    override func splitViewWillResizeSubviews(_ aNotification: Notification){
     //   println(aNotification)
    }

    override func splitViewDidResizeSubviews(_ aNotification: Notification){
       // println(aNotification)
    }
    
}
