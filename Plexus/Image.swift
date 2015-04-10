//
//  Image.swift
//  Plexus
//
//  Created by matt on 10/23/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Foundation
import CoreData

class Image: NSManagedObject {

    @NSManaged var imageName: String
    //@NSManaged var imageRepresentation: NSData
    @NSManaged var entry: Entry

}
