//
//  Book.swift
//  Open Book
//
//  Created by martin chibweon 7/24/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import Foundation
import CoreData
import Alamofire

class Book: NSManagedObject, ManagedObject {
    @NSManaged var title: String?
    @NSManaged var authors: String?
    @NSManaged var identifier: String
    @NSManaged var url: NSURL
    @NSManaged var cover: NSData?
    
    private var request: Request?
    
    override class func contextShouldIgnoreUnmodeledPropertyChanges() -> Bool {
        return false
    }
    
    enum State {
        case Downloaded(localUrl: NSURL)
        case InProgress(request: Request, totalBytes: Int64, readBytes: Int64)
        case Fault
    }
    
    private(set) var state: State = .Fault {
        willSet {
            willChangeValueForKey("state")
        }
        didSet {
            didChangeValueForKey("state")
        }
    }
    
    private var fileManager: NSFileManager {
        return NSFileManager.defaultManager()
    }
    
    static private var temporaryDirectory: NSURL = {
        let directory = NSURL(fileURLWithPath:  NSTemporaryDirectory())
        let privateDirectory = directory.URLByAppendingPathComponent("books")
        try! NSFileManager().createDirectoryAtURL(privateDirectory, withIntermediateDirectories: true, attributes: nil)
        return privateDirectory
    }()
    
    private var temporaryUrl: NSURL {
        return Book.temporaryDirectory.URLByAppendingPathComponent(identifier)
    }
    
    static private var booksDirectoryURL: NSURL = {
        let documents = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        let booksUrl = documents.URLByAppendingPathComponent("books")
        try! NSFileManager().createDirectoryAtURL(booksUrl, withIntermediateDirectories: true, attributes: nil)
        return booksUrl
    }()
    
    private var localUrl: NSURL {
        return Book.booksDirectoryURL.URLByAppendingPathComponent(identifier)
    }
    
    func startDownloading() {
        guard case .Fault = state else { return }
        
        let request = Alamofire.download(.GET, url) { _, _ in
            return self.temporaryUrl
        }
        .progress { _, totalBytesRead, totalBytes in
            dispatch_async(dispatch_get_main_queue()) {
                self.updateProgressInfo(totalBytesRead, totalBytes: totalBytes)
            }
        }
        .response { _, _, _, error in
            if let urlError = error as? NSURLError where urlError == .Cancelled {
                return
            }
            
            self.finishDownloadingWithError(error)
        }
        
        state = .InProgress(request: request, totalBytes: -1, readBytes: 0)
    }
    
    private func updateProgressInfo(totalBytesRead: Int64, totalBytes: Int64) {
        guard case let .InProgress(request, _, _) = state else { return }
        
        state = .InProgress(request: request, totalBytes: totalBytes, readBytes: totalBytesRead)
    }
    
    private func finishDownloadingWithError(error: NSError?) {
        guard case .InProgress = state else { return }
        
        if error != nil {
            state = .Fault
            return
        }
        
        do {
            try fileManager.removeItemAtURL(localUrl)
        }
        catch {}
        
        try! fileManager.moveItemAtURL(temporaryUrl, toURL: localUrl)
        
        state = .Downloaded(localUrl: localUrl)
    }
    
    func stopDownloading() {
        guard case let .InProgress(request, _, _) = state else { return }
        request.cancel()
        
        state = .Fault
    }
    
    override func awakeFromFetch() {
        super.awakeFromFetch()
        
        if fileManager.fileExistsAtPath(localUrl.path!) {
            state = .Downloaded(localUrl: localUrl)
        }
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        
        if case let .InProgress(request, _, _) = state {
            request.cancel()
        }
    }
}
