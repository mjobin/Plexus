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
    
    
    var entryViewController : PlexusEntryViewController? = nil
    var modelViewController : PlexusModelViewController? = nil
    var entryDetailViewController : PlexusEntryDetailViewController? = nil
    var modelDetailViewController :  PlexusModelDetailViewController? = nil
    
    @objc dynamic var entryController : NSArrayController!
    @objc dynamic var modelTreeController : NSTreeController!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        modelViewController = children[0] as? PlexusModelViewController
        entryViewController = children[1] as? PlexusEntryViewController
        entryDetailViewController = children[2] as? PlexusEntryDetailViewController
        modelDetailViewController = children[3] as? PlexusModelDetailViewController



        let modelListViewItem = self.splitViewItems[0] // 0 is left pane
        modelListViewItem.isCollapsed = false

        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        entryController = entryViewController?.entryController
        entryDetailViewController!.entryController = self.entryController
        
        modelTreeController = modelViewController?.modelTreeController
        modelDetailViewController!.modelTreeController = self.modelTreeController
        entryViewController!.modelTreeController = self.modelTreeController
        
    }
    
    

    
    func  toggleModels(_ x:NSToolbarItem){
        
        let modelListViewItem = self.splitViewItems[0] // 0 is left pane
        modelListViewItem.animator().isCollapsed = !modelListViewItem.isCollapsed
        
    }
    

    
  
    override func splitViewWillResizeSubviews(_ aNotification: Notification){
     //   println(aNotification)
    }

    override func splitViewDidResizeSubviews(_ aNotification: Notification){
       // println(aNotification)
    }
    
}
