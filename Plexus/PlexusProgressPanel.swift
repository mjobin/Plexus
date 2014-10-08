//
//  PlexusProgressPanel.swift
//  Plexus
//
//  Created by matt on 10/8/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa

protocol ProgressViewControllerDelegate : class {
    func progressViewControllerDidCancel(progressViewController: PlexusProgressPanel)
}

class PlexusProgressPanel: NSViewController {
    
    @IBOutlet weak var progressBar: NSProgressIndicator!
    weak var delegate : ProgressViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.progressBar.usesThreadedAnimation = true
        
    }
    
    override func viewWillAppear() {
        self.progressBar.startAnimation(self)
    }
    
    override func viewWillDisappear() {
        self.progressBar.stopAnimation(self)
    }
    
    @IBAction func cancelButton(sender: AnyObject) {
        
        self.delegate?.progressViewControllerDidCancel(self)
    }
    
}
