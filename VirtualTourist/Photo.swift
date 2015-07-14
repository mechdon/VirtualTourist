//
//  Photo.swift
//  VirtualTourist
//
//  Created by Gerard Heng on 11/6/15.
//  Copyright (c) 2015 gLabs. All rights reserved.
//

// Import UIKit
import UIKit

// Import CoreData
import CoreData

// Make Photo available to Objective-C code
@objc(Photo)

// Make Photo a subclass of NSManagedObject
class Photo : NSManagedObject {
    
    struct Keys {
        static let Title = "title"
        static let Owner = "owner"
        static let ImagePath = "imagePath"
        static let Data = "data"
        static let Pin = "pin"
    }
    
    // Promotion of simple properties to Core Data attributes
    @NSManaged var title: String
    @NSManaged var owner: String?
    @NSManaged var imagePath: String?
    @NSManaged var data: NSData?
    @NSManaged var pin: Pin?
    
    // Standard Core Data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Dictionary
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        imagePath = dictionary[Keys.ImagePath] as? String
        title = dictionary[Keys.Title] as! String
        owner = dictionary[Keys.Owner] as? String
        pin = dictionary[Keys.Pin] as? Pin
    }
    
    // Image Cache
    var image: UIImage? {
        get {
            return FlickrDB.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            FlickrDB.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
        }
    }

}
