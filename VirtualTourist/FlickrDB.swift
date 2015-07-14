//
//  FlickrDB.swift
//  VirtualTourist
//
//  Created by Gerard Heng on 11/6/15.
//  Copyright (c) 2015 gLabs. All rights reserved.
//

import Foundation

class FlickrDB : NSObject  {
    
    typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
    
    var session: NSURLSession
    
    var config = Config.unarchivedInstance() ?? Config()
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    //# MARK: - Parse data from Flickr based on Lat/Lon
    
    func getFlickrImagesFromLocation(latitude: Double, longitude: Double, completionHandler: CompletionHandler) -> NSURLSessionTask {
        
        let methodArguments = [
            "method": FlickrDB.Constants.MethodName,
            "api_key": FlickrDB.Constants.ApiKey,
            "lat": latitude,
            "lon": longitude,
            "extras": FlickrDB.Constants.Extras,
            "format": FlickrDB.Resources.DataFormat,
            "nojsoncallback": FlickrDB.Resources.NoJsonCallBack
        ]

        let urlString = FlickrDB.Constants.BaseUrl + escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        
        let request = NSURLRequest(URL: url)
                
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = FlickrDB.errorForData(data, response: response, error: downloadError)
                completionHandler(result: nil, error: newError)
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                if parsingError == nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(result: parsedResult, error: nil)
                    }
                } else {
                    completionHandler(result: nil, error: parsingError)
                }
            }
        }
        
        task.resume()
        
        return task
        
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    // Make error message based on status message from Flickr
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String : AnyObject] {
            if let errorMessage = parsedResult["status_message"] as? String {
                
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                return NSError(domain: "Flickr Error", code: 1, userInfo: userInfo)
                
            }
        }
        
        return error
    }
    
    //# MARK: - All purpose task method for images
    
    func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionTask {
        
        let url = NSURL(string: filePath)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request){
            data, response, downloadError in
            
            if let error = downloadError {
                let newError = FlickrDB.errorForData(data, response: response, error: error)
                completionHandler(imageData: data, error: newError)
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(imageData: data, error: nil)
                }
            }
        }
        task.resume()
        return task
    }

    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrDB {
    
        struct Singleton {
            static var sharedInstance = FlickrDB()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    
}