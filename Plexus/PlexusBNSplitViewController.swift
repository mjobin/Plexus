//
//  PlexusBNSplitViewController.swift
//  Plexus
//
//  Created by matt on 1/4/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusBNSplitViewController: NSSplitViewController {
    
    
    var moc : NSManagedObjectContext!
    dynamic var modelTreeController : NSTreeController!
    
    @IBOutlet dynamic var nodesController : NSArrayController!
    
    var bnViewController : PlexusBNViewController? = nil
    var bnSingleViewController : PlexusBNSingleNodeViewController? = nil
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //listen more messages about toggling single node window
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "toggleSingleNodeView", name: "edu.scu.Plexus.toggleSingleNode", object: nil)
        
        // Do view setup here.
        bnViewController = childViewControllers[0] as? PlexusBNViewController
        bnSingleViewController = childViewControllers[1] as? PlexusBNSingleNodeViewController
        


        
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        
        
        bnViewController!.modelTreeController = self.modelTreeController
        bnViewController!.nodesController = self.nodesController
        
         bnSingleViewController!.modelTreeController = self.modelTreeController
         bnSingleViewController!.nodesController = self.nodesController
        
       // println("bnsvc: \(self.view.constraints)")
        
        var singleNodeViewItem = self.splitViewItems[1] as NSSplitViewItem  // 1 is lower pane
        singleNodeViewItem.animator().collapsed = false
        self.splitView.setPosition((view.frame.height/2), ofDividerAtIndex: 0)
        self.splitView.adjustSubviews()


    }

    
    func toggleSingleNodeView(){
        println("splitview  \(self.splitView.frame)")
        
        var singleNodeViewItem = self.splitViewItems[1] as NSSplitViewItem  // 1 is lower pane
        
        
/*
        
        singleNodeViewItem.animator().collapsed = false
        self.splitView.setPosition((view.frame.height/2), ofDividerAtIndex: 0)
        self.splitView.adjustSubviews()

        println("toggle to \(view.frame.height/2) and collapse is now \(singleNodeViewItem.collapsed)")
        
*/
        

        
        println("collapse is first \(singleNodeViewItem.collapsed)")
        singleNodeViewItem.animator().collapsed = !singleNodeViewItem.collapsed
        
        
        if(singleNodeViewItem.collapsed == false){
        self.splitView.setPosition((view.frame.height/2), ofDividerAtIndex: 0)
             println("toggle to \(view.frame.height/2) and collapse is now \(singleNodeViewItem.collapsed)")
            self.splitView.adjustSubviews()
        }
        


    }
}
