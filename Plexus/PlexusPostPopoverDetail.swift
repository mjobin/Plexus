//
//  PlexusPostPopoverDetail.swift
//  Plexus
//
//  Created by matt on 10/24/17.
//  Copyright © 2017 Matthew Jobin. All rights reserved.
//

import Cocoa

class PlexusPostPopoverDetail: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @objc dynamic var nodesController : NSArrayController!
    @objc dynamic var modelTreeController : NSTreeController!
    @IBOutlet var popoverView : NSView!
    @IBOutlet var popScrollView : NSScrollView!
    @IBOutlet var cptTableView : NSTableView!
    var plexusModelDetailViewController : PlexusModelDetailViewController!
    

    /**
      Calculates size from number of CPT entries needed.
     
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        var tableWidth = 0.0
        
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        let curNode = curNodes[0]
        for curColumn in cptTableView.tableColumns{
            cptTableView.removeTableColumn(curColumn)
        }
        let theUpNodes = curNode.upNodes(self)
        for thisUpNode in theUpNodes {
            let cptcolumn = NSTableColumn(identifier: convertToNSUserInterfaceItemIdentifier(thisUpNode.name))
            cptcolumn.headerCell.stringValue = thisUpNode.name
            cptcolumn.sizeToFit()

            tableWidth += Double(cptcolumn.width)
            cptTableView.addTableColumn(cptcolumn)
            
        }
        let datacolumn = NSTableColumn(identifier: convertToNSUserInterfaceItemIdentifier("Data"))
        datacolumn.headerCell.stringValue = "CP"
        tableWidth += Double(datacolumn.width)
        cptTableView.addTableColumn(datacolumn)
        
        let tableRect = popScrollView.contentView.documentRect

        

        popoverView.setFrameSize(NSSize(width: CGFloat(tableWidth + 32), height: CGFloat(tableRect.height + 100)))


        popoverView.display()
    
        cptTableView.delegate = self
        cptTableView.dataSource = self
        cptTableView.reloadData()
        

        

    }
    
    
    
        // MARK: - TableView data source

    /**
     Calculates number of rows needed from nodesController.
     
     - Parameter tableView: TableView should only be the one in the storyboard.
     
     - Returns: Number of rows needed.
     */
    func numberOfRows(in tableView: NSTableView) -> Int {
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            let curNode = curNodes[0]
            if (curNode.value(forKey: "cptArray")) == nil {
                return 0
            }
            if(plexusModelDetailViewController.cptReady[curNode] == 2){

                return curNode.cptArray.count

            }
            else {
                return 0
            }
        }
        return 0
    }
    
    
    /**
     Retrives value for TableView cell. Calculates string of T anf F's from state of upstream nodes.
     
     - Parameter tableView: TableView should only be the one in the storyboard.
     - Parameter tableColumn: Calculates CPT vlaue if column is "Data".
     - Parameter row: For referencing cptarray of the Model.
     
     - Returns: Number of rows needed.
     */
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            let curNode = curNodes[0]
            if(convertFromNSUserInterfaceItemIdentifier(tableColumn?.identifier ?? NSUserInterfaceItemIdentifier(rawValue: "None")) == "Data" ){
                let curModels : [Model] = plexusModelDetailViewController.modelTreeController.selectedObjects as! [Model]
                let curModel : Model = curModels[0]
                if curModel.complete {
                    if curNode.cptFreezeArray.count > 0 {
                        let cptarray = curNode.cptFreezeArray
                        return cptarray[row]
                    }
                        
                    else {
                        return nil
                    }
                    
                }
                else {

                    return curNode.cptArray[row]
                }
            }
            else{
                let poststr = String(row, radix: 2)
                //add chars to pad out

                let theUpNodes = curNode.upNodes(self)
                var prestr = String()
                for _ in poststr.count..<theUpNodes.count {
                    prestr += "0"
                }
                let str = prestr + poststr
                //print("str \(str)")
                let revstr = String(str.reversed())
                //and revrse
                let index = tableView.tableColumns.index(of: tableColumn!)
                //print ("index \(index): revstr \(revstr)")
                if ( index! > revstr.count) {
                    print ("Error. curNode \(curNode.name) infBy \(theUpNodes) index \(String(describing: index)): revstr \(revstr)")
                }
                let index2 = revstr.index(revstr.startIndex, offsetBy: index!)
                if(revstr[index2] == "1"){
                    return "T"
                }
                else if (revstr[index2] == "0"){
                    return "F"
                }
            }
        }
        
        return nil
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
	return NSUserInterfaceItemIdentifier(rawValue: input)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSUserInterfaceItemIdentifier(_ input: NSUserInterfaceItemIdentifier) -> String {
	return input.rawValue
}
