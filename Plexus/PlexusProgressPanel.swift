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
    @IBOutlet var maxWork : NSTextField!
    @IBOutlet var curWork : NSTextField!
    weak var delegate : ProgressViewControllerDelegate?
    


    override func viewDidLoad() {
        super.viewDidLoad()

        self.progressBar.usesThreadedAnimation = true
        //self.progressBar.indeterminate = false
       // self.progressBar.minValue = 0.0
       // self.progressBar.maxValue = 100.0
       // self.progressBar.doubleValue = 5.5
        self.progressLabel.stringValue = "Working..."

        
    }
    
    override func viewWillAppear() {
        
        self.progressBar.startAnimation(self)
        self.view.needsDisplay = true
       //println("start")
    }
    
    override func viewWillDisappear() {
        self.progressBar.stopAnimation(self)
        //println("stop")
    }
    
    @IBAction func cancelButton(sender: AnyObject) {
        
        self.delegate?.progressViewControllerDidCancel(self)
    }
    
    func moveBar(inc: Double) {

        progressBar.incrementBy(inc)
        self.view.needsDisplay = true
    }
    
    func changeLabel(newLabel : String) {
        
        self.progressLabel.stringValue = newLabel
        self.view.needsDisplay = true
    }
    
    func changeCurWork(inc: Int) {
        print("inc \(inc)")
        ////  self.progressIndicator.doubleValue = progress.fractionCompleted
        self.curWork.integerValue = inc
        self.view.needsDisplay = true
    }
    
    func changeMaxWork(inc: Int) {
        
        self.maxWork.integerValue = inc
        self.view.needsDisplay = true
    }
    
}
