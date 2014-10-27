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
    
    @IBOutlet var progressBar: NSProgressIndicator!
    @IBOutlet var progressLabel : NSTextField!
    weak var delegate : ProgressViewControllerDelegate?
    


    override func viewDidLoad() {
        super.viewDidLoad()

        self.progressBar.usesThreadedAnimation = true
        self.progressBar.indeterminate = false
        self.progressBar.minValue = 0.0
        self.progressBar.maxValue = 100.0
        self.progressBar.doubleValue = 5.5
        self.progressLabel.stringValue = "Working..."

        
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
    
    func moveBar(inc: Double) {

        progressBar.incrementBy(inc)
        progressBar.needsDisplay = true
    }
    
    func changeLabel(newLabel : String) {
        
        self.progressLabel.stringValue = newLabel
        self.progressLabel.needsDisplay = true
    }
    
}
