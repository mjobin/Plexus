//
//  PlexusBNSplitView.swift
//  Plexus
//
//  Created by matt on 1/22/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

import Cocoa

class PlexusBNSplitView: NSSplitView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
      //  println("splitview ended lize resize with bound width \(self.bounds.width)")
    }
    
}
