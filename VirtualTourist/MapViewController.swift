//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Gerard Heng on 10/6/15.
//  Copyright (c) 2015 gLabs. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    // Outlet for MapView
    @IBOutlet weak var mapView: MKMapView!
    
    // Variables
    var pins = [Pin]()
    var photos = [Photo]()
    var lat: Double!
    var lon: Double!
    var uilpgr: UILongPressGestureRecognizer!
    
    // Struct for MapKey
    struct MapKey {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
    }
    
    //# MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set Long Press Gesture Recognizer and minimum press duration
        uilpgr = UILongPressGestureRecognizer(target: self, action: "action:")
        uilpgr.minimumPressDuration = 2.0
        
        // Set delegate for fetchResultsController
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        
        // Fetch all pins
        pins = fetchAllPins()
        
        // Set delegate for MapView
        mapView.delegate = self
        
        // Add gesture recognizer to MapView
        mapView.addGestureRecognizer(uilpgr)
        
        // Add pin annotations to MapView
        mapView.addAnnotations(pins)
        
        // Hide Navigation Bar
        navigationController?.navigationBarHidden = true
        
        // Restore Map Region if it was previously stored
        if NSUserDefaults.standardUserDefaults().doubleForKey(MapKey.Latitude) != 0 {
            restoreMapRegion()
        }
    }
    
    //# Mark: - Core Data Convenience. Useful for fetching, adding and saving objects
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.addGestureRecognizer(uilpgr)
    }
    
    // Restore Map Region using NSUserDefaults
    func restoreMapRegion() {
        var regionLat = NSUserDefaults.standardUserDefaults().doubleForKey(MapKey.Latitude)
        var regionLon = NSUserDefaults.standardUserDefaults().doubleForKey(MapKey.Longitude)
        var regionLatDelta = NSUserDefaults.standardUserDefaults().doubleForKey(MapKey.LatitudeDelta)
        var regionLonDelta = NSUserDefaults.standardUserDefaults().doubleForKey(MapKey.LongitudeDelta)
        
        mapView.setRegion(MKCoordinateRegionMake(CLLocationCoordinate2DMake(regionLat, regionLon), MKCoordinateSpanMake(regionLatDelta, regionLonDelta)), animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.removeGestureRecognizer(uilpgr)
    }
    
    // Fetch all pins
    func fetchAllPins() -> [Pin] {
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        if error != nil {
            println("Error in fetchAllPins(): \(error)")
        }
        
        return results as! [Pin]
    }
    
    // Long press gesture recognizer
    func action(gestureRecognizer:UIGestureRecognizer) {
        
        var touchPoint = gestureRecognizer.locationInView(mapView)
        
        var newCoordinate:CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        var newannotation = MKPointAnnotation()
        
        newannotation.coordinate = newCoordinate
        
        let dictionary: [String: AnyObject] = [
            Pin.Keys.Latitude: newCoordinate.latitude,
            Pin.Keys.Longitude: newCoordinate.longitude
        ]
        
        // Add pin only at the gestureRecognizer .Began state. This is to prevent duplicate pins from being added if the user continues to hold press.
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
        
        dispatch_async(dispatch_get_main_queue()){
            
            let pinToBeAdded = Pin(dictionary: dictionary, context: self.sharedContext)
            
            self.mapView.addAnnotation(pinToBeAdded)
            
            self.pins.append(pinToBeAdded)
            
            CoreDataStackManager.sharedInstance().saveContext()
            }
        }
    }
    
    //# MARK: - NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()

    
    //# MARK:- Mapview delegate methods
    
    // Pin Annotations
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView!
        
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        
        return pinView
    }
    
    // Save map region in NSUserDefaults whenever the region changes
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.latitude, forKey: MapKey.Latitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.longitude, forKey: MapKey.Longitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: MapKey.LatitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: MapKey.LongitudeDelta)
    }

    // Transit to Photo View Controller to show photos when pin is selected.
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        let photoVC = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoViewController") as! PhotoViewController
        photoVC.pin = view.annotation as! Pin
        photoVC.lat = view.annotation.coordinate.latitude
        photoVC.lon = view.annotation.coordinate.longitude
        self.navigationController?.pushViewController(photoVC, animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

