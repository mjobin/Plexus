//
//  PlexusMainSplitViewController.swift
//  Plexus
//
//  Created by matt on 10/1/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa


class PlexusMainSplitViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        splitView.setPosition(splitView.frame.width/2, ofDividerAtIndex: 1) //initial set up leave it 50/50 for now
        splitView.adjustSubviews()
        
    }
    
    func  toggleModels(x:NSToolbarItem){
        println("Toggle models Tapped: \(x)")
        
       // println(self.splitViewItems.count)
        
        
        var modelListViewItem = self.splitViewItems[3] as NSSplitViewItem  // 3 is right pane
        
        modelListViewItem.animator().collapsed = !modelListViewItem.collapsed
        

        
        
        

        
    }
    
}
