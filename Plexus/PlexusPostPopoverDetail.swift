//
//  PlexusPostPopoverDetail.swift
//  Plexus
//
//  Created by matt on 10/24/17.
//  Copyright © 2017 Matthew Jobin. All rights reserved.
//

import Cocoa

class PlexusPostPopoverDetail: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    dynamic var nodesController : NSArrayController!
    dynamic var modelTreeController : NSTreeController!
    @IBOutlet var popoverView : NSView!
    @IBOutlet var popScrollView : NSScrollView!
    @IBOutlet var cptTableView : NSTableView!
    var plexusModelDetailViewController : PlexusModelDetailViewController!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        var tableWidth = 0.0
        
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        let curNode = curNodes[0]
        for curColumn in cptTableView.tableColumns{
            cptTableView.removeTableColumn(curColumn)
        }
        let theInfBy : [BNNode] = curNode.infBy(self) as! [BNNode]
        for thisInfBy in theInfBy {
            let cptcolumn = NSTableColumn(identifier: thisInfBy.name)
            cptcolumn.headerCell.stringValue = thisInfBy.name
            cptcolumn.sizeToFit()

            tableWidth += Double(cptcolumn.width)
            cptTableView.addTableColumn(cptcolumn)
            
        }
        let datacolumn = NSTableColumn(identifier: "Data")
        datacolumn.headerCell.stringValue = "CP"
        tableWidth += Double(datacolumn.width)
        cptTableView.addTableColumn(datacolumn)
        
        let tableRect = popScrollView.contentView.documentRect

        

        popoverView.setFrameSize(NSSize(width: CGFloat(tableWidth + 32), height: CGFloat(tableRect.height + 100)))
        //        popoverView.setFrameSize(NSSize(width: CGFloat(tableRect.width + 32), height: CGFloat(tableRect.height + 100)))

        popoverView.display()
    
        cptTableView.delegate = self
        cptTableView.dataSource = self
        cptTableView.reloadData()
        

        

    }
    
    
    
    //tableview data source
    
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
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var curNodes : [BNNode] = nodesController.selectedObjects as! [BNNode]
        if(curNodes.count>0) {
            let curNode = curNodes[0]
            if(tableColumn?.identifier == "Data" ){
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
                let theInfBy = curNode.infBy(self)
                var prestr = String()
                for _ in poststr.count..<theInfBy.count {
                    prestr += "0"
                }
                let str = prestr + poststr
                //print("str \(str)")
                let revstr = String(str.reversed())
                //and revrse
                let index = tableView.tableColumns.index(of: tableColumn!)
                //print ("index \(index): revstr \(revstr)")
                if ( index! > revstr.count) {
                    print ("Error. curNode \(curNode.name) infBy \(theInfBy) index \(String(describing: index)): revstr \(revstr)")
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