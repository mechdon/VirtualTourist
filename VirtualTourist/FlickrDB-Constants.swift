//
//  FlickrDB-Constants.swift
//  VirtualTourist
//
//  Created by Gerard Heng on 11/6/15.
//  Copyright (c) 2015 gLabs. All rights reserved.
//

import Foundation

extension FlickrDB {
    
    struct Constants {
    
        // MARK: - URLs
        static let ApiKey = "d7b01f0e272612f3124911a335fb2c05"
        static let BaseUrl = "https://api.flickr.com/services/rest/"
        static let Extras: String = "url_m"
        static let MethodName = "flickr.photos.search"
    }
    
    struct Resources {
        static let Extras = "url_m"
        static let SafeSearch = "1"
        static let DataFormat = "json"
        static let NoJsonCallBack = "1"
        static let PerPage = 18
    }
}