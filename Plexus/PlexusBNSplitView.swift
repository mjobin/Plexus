//
//  PlexusBNSplitView.swift
//  Plexus
//
//  Created by matt on 1/22/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

import Cocoa

class PlexusBNSplitView: NSSplitView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
      //  println("splitview ended lize resize with bound width \(self.bounds.width)")
    }
    
}
