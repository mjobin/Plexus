//
//  PlexusMapViewController.swift
//  Plexus
//
//  Created by matt on 11/10/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa
import MapKit

class PlexusMapViewController: NSViewController {
    
    var moc : NSManagedObjectContext!
    
    dynamic var entryTreeController : NSTreeController!
    
    @IBOutlet var mapView : MKMapView!
    @IBOutlet var entryObject : NSObjectController!
    
    required init?(coder aDecoder: NSCoder)
    {
        
        let appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        moc = appDelegate.managedObjectContext
        
        
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        


        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        
        let mapEntries : [Entry] = entryTreeController.selectedObjects as [Entry]
        if(mapEntries.count > 0){
            let mapEntry : Entry =  mapEntries[0]
            
            var location = CLLocationCoordinate2D(
                latitude: mapEntry.latitude,
                longitude: mapEntry.longitude
            )
            var span = MKCoordinateSpanMake(1, 1)
            var region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            
            mapView.addAnnotation(MKPlacemark(coordinate: location, addressDictionary:nil))
            
            

            
        }
        
        
    }
    
}
