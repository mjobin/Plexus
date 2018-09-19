//
//  NSTreeControllerExtensions.swift
//  Plexus
//
//  Created by matt on 9/19/18.
//  Copyright © 2018 Santa Clara University. All rights reserved.
//

import Foundation


extension NSTreeController {
    
    func indexPathOfModel(model:Model) -> NSIndexPath? {
        return self.indexPathOfModel(model: model, nodes: (self.arrangedObjects as AnyObject).children)
    }
    
    func indexPathOfModel(model:Model, nodes:[NSTreeNode]!) -> NSIndexPath? {
        for node in nodes {
            if (model == node.representedObject as! NSObject)  {
                return node.indexPath as NSIndexPath
            }
            if (node.children != nil) {
                if let path:NSIndexPath = self.indexPathOfModel(model: model, nodes: node.children)
                {
                    return path
                }
            }
        }
        return nil
    }
}
