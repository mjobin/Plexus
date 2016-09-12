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
    
    dynamic var entryTreeController : NSTreeController!
    dynamic var modelTreeController : NSTreeController!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        structureViewController = childViewControllers[0] as? PlexusStructureViewController
        entryViewController = childViewControllers[1] as? PlexusEntryViewController
        entryDetailViewController = childViewControllers[2] as? PlexusEntryDetailViewController
        modelDetailViewController = childViewControllers[3] as? PlexusModelDetailViewController
        modelViewController = childViewControllers[4] as? PlexusModelViewController
        

        
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
    
    
    func  toggleStructures(x:NSToolbarItem){
        print("Toggle sctructures Tapped: \(x)")
        
        // println(self.splitViewItems.count)
        
        
        let structureListViewItem = self.splitViewItems[0] // 0 is left pane
        structureListViewItem.animator().collapsed = !structureListViewItem.collapsed
        
        
        
    }
    
    func  toggleModels(x:NSToolbarItem){
        print("Toggle models Tapped: \(x)")
        
       // println(self.splitViewItems.count)
        
        
        let modelListViewItem = self.splitViewItems[4] // 4 is right pane
        
        modelListViewItem.animator().collapsed = !modelListViewItem.collapsed
        

        
    }
    

    
  
    override func splitViewWillResizeSubviews(aNotification: NSNotification){
     //   println(aNotification)
    }

    override func splitViewDidResizeSubviews(aNotification: NSNotification){
       // println(aNotification)
    }
    
}
