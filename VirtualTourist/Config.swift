//
//  Config.swift
//  VirtualTourist
//
//  Created by Gerard Heng on 11/6/15.
//  Copyright (c) 2015 gLabs. All rights reserved.
//

import Foundation

//#MARK: - Files Support
private let _documentsDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
private let _fileURL: NSURL = _documentsDirectoryURL.URLByAppendingPathComponent("Flickr-Context")

class Config: NSObject {
    
    func save() {
        NSKeyedArchiver.archiveRootObject(self, toFile: _fileURL.path!)
    }
    
    class func unarchivedInstance() -> Config? {
        
        if NSFileManager.defaultManager().fileExistsAtPath(_fileURL.path!) {
            return NSKeyedUnarchiver.unarchiveObjectWithFile(_fileURL.path!) as? Config
        } else {
            return nil
        }
    }
    
    
    
}

