//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Gerard Heng on 10/6/15.
//  Copyright (c) 2015 gLabs. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    // View component outlets
    @IBOutlet weak var mapviewPhotoVC: MKMapView!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionBtn: UIBarButtonItem!
    
    //# MARK: - Declare variables
    
    var lat: Double!
    var lon: Double!
    var imageView: UIImageView!
    var startAnimate = 0
    var stopAnimate = 0
    var loadingComplete = false
    var pin: Pin!
    
    // For customisation of layouts for different screen sizes
    var w: CGFloat!
    var h: CGFloat!
    let screenWidth = UIScreen.mainScreen().bounds.width
    let screenHeight = UIScreen.mainScreen().bounds.height
    let sectionInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to show the delete icon and lower the alpha of selected cells.
    var selectedIndexes = [NSIndexPath]()
    
    // For tracking insertions, deletions and updates
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    
    //# MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set view layout for different screen sizes
        if screenWidth == 375.0 {
            w = 115
            h = 100
        } else {
            w = screenWidth / 3.4
            h = screenHeight / 6.8
        }
        
        // Show small map and annotation for top of page
        var latDelta:CLLocationDegrees = 0.1
        var lonDelta:CLLocationDegrees = 0.1
        var span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        var location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, lon)
        var region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        
        mapviewPhotoVC.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(lat, lon)
        mapviewPhotoVC.addAnnotation(annotation)
        
        
        // Set delegate and datasource for CollectionView
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
        
        // Set delegate for fetchResultsController
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        
        // Initial setting for bar button
        newCollectionBtn.title = "New Collection"
        newCollectionBtn.enabled = false
    
    }
    
    //# Mark: - Core Data Convenience. Useful for fetching, adding and saving objects
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewWillAppear(animated: Bool) {
        self.photosCollectionView = self.view.viewWithTag(1) as! UICollectionView
        
        // Start to download images only when there had been no previous images downloaded for that pin
        if pin.photos.isEmpty {
            loadNewCollection()
        } else {
            loadingCompleted()
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController.delegate = nil
    }
    
    //# MARK: -  Customisation of Collection View Layout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
         return CGSize(width: w, height: h)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // Reload photos for Collection View
    func reloadPhotos() {
        
        dispatch_async(dispatch_get_main_queue()) {
            self.photosCollectionView.reloadData()
        }
        
    }
    
    //# MARK: - NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    //#MARK: - Fetched Results Controller Delegate. The following three methods are invoked whenever changes are made to the Core Data.
    
    // Create three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // Start out with empty arrays for each change type
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    // Method is called whenever object is added, changed or deleted. The index paths are stored accordingly into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }
    
    // Method is invoked after all of the changes in the current batch have been collected into the three index path arrays (insert, delete, and upate).
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        photosCollectionView.performBatchUpdates({ () -> Void in
            for indexPath in self.insertedIndexPaths {
                self.photosCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.photosCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.photosCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
        
    }
    
    
    //# MARK: - UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        configureCell(cell, indexPath: indexPath, photo: photo)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if loadingComplete {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        updateBarButton()
        reloadPhotos()
            
        }
    }
    
    
    //# MARK: - Configure Cell
    
    func configureCell(cell: PhotoCollectionViewCell, indexPath: NSIndexPath, photo: Photo) {
        
       cell.photoImageView.image = nil
        
        if photo.image != nil {
            cell.photoImageView.image = photo.image
        }
        
        else {
            // Start animating activity indicator
            cell.activityIndicator.startAnimating()
            startAnimate+=1
            
            let task = FlickrDB.sharedInstance().taskForImage(photo.imagePath!) {
                data, error in
                
                if let downloaderror = error {
                    println("Flickr download error: \(downloaderror)")
                    // Stop animating activity indicator
                    cell.activityIndicator.stopAnimating()
                    self.stopAnimate+=1
                }
                
                if let imageData = data {
                    let image = UIImage(data: imageData)
                    dispatch_async(dispatch_get_main_queue()) {
                        photo.image = image
                        // Stop animating activity indicator
                        cell.activityIndicator.stopAnimating()
                        CoreDataStackManager.sharedInstance().saveContext()
                        self.stopAnimate+=1
                    }
                }
                self.reloadPhotos()
            }
        }
        
        // If the cell is "selected", the delete icon will be shown and image greyed out. Swift's "find" function is used to see if the indexPath is in the array.
        
        if let index = find(selectedIndexes, indexPath) {
            cell.delete.hidden = false
            cell.photoImageView.alpha = 0.5
        } else {
            cell.delete.hidden = true
            cell.photoImageView.alpha = 1.0
        }
    }
    
    // Update and enable bar button when all photos are loaded.
    func loadingCompleted() {
        loadingComplete = true
        updateBarButton()
        newCollectionBtn.enabled = true
    }
    
    // Check whether all photos have been loaded after scrolling down to bottom of page.
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if self.stopAnimate == self.startAnimate {
            loadingCompleted()
        }
    }
    
    // Update bar button text according to whether any photos are selected for deletion.
    func updateBarButton() {
        
        if selectedIndexes.count > 0 {
            newCollectionBtn.title = "Save Collection"
        } else {
            newCollectionBtn.title = "New Collection"
        }
        
    }
    
    // Bar button activation: Load new collection or Delete selected photos
    @IBAction func barButtonPressed(sender: AnyObject) {
        
        if !selectedIndexes.isEmpty {
            deleteSelection()
        } else {
            loadNewCollection()
        }
    }
    
    // Delete selected photos
    func deleteSelection() {
        var selectedPhotos = [Photo]()
        for indexPath in selectedIndexes {
            selectedPhotos.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in selectedPhotos {
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        selectedIndexes = [NSIndexPath]()
        updateBarButton()
    }
    
    // Load new photos from Flickr
    func loadNewCollection() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        
        FlickrDB.sharedInstance().getFlickrImagesFromLocation(lat, longitude: lon) { result, error in
            
            if let error = error {
                println("error")
                
            } else {
                
                if let receivedDictionary = result.valueForKey("photos") as? [String: AnyObject] {
                    
                    if let photosArray = receivedDictionary["photo"] as? [[String: AnyObject]] {
                        
                        if photosArray.isEmpty {
                            
                            // Show alert message to show that there are no photos from this location
                            self.showAlertMsg("No Photos", errorMsg: "There are no photos from this location!")
                            
                        } else {
                        
                        // Parse th array of photos dictionaries
                        for (var i=0; i<photosArray.count; i++) {
                            
                            let receivedDictionary = photosArray[i] as [String: AnyObject]
                            
                            let photoTitle = receivedDictionary["title"] as? String
                            let imagePath = receivedDictionary["url_m"] as? String
                            let owner = receivedDictionary["owner"] as? String
                            
                            let photoInfo: [String: AnyObject] = [
                                Photo.Keys.Title : photoTitle!,
                                Photo.Keys.ImagePath : imagePath!,
                                Photo.Keys.Owner : owner!,
                                Photo.Keys.Pin : self.pin
                            ]
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                Photo(dictionary: photoInfo, context: self.sharedContext)
                            }
                          }
                        }
                    }
                }
            }
        }
    }
    
    // Show Alert Method
    func showAlertMsg(errorTitle: String, errorMsg: String) {
        var title = errorTitle
        var errormsg = errorMsg
        
        NSOperationQueue.mainQueue().addOperationWithBlock{ var alert = UIAlertController(title: title, message: errormsg, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    // Back button pressed. Return to MapView Controller
    @IBAction func backBtnActivation(sender: AnyObject) {
        self.performSegueWithIdentifier("showMapView", sender: self)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
