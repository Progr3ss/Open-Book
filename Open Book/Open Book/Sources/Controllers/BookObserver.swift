//
//  BookObserver.swift
//  Open Book
//
//  Created by martin chibweon 7/23/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import Foundation
import CoreData

class BookObserver {
    let identifier: String
    let moc: NSManagedObjectContext
    
    private var insertHandlers = [Handler]()
    private var changeHandlers = [Handler]()
    private var deleteHandlers = [Handler]()
    
    typealias Handler = (book: Book) -> Void
    
    init(identifier: String, context: NSManagedObjectContext) {
        self.identifier = identifier
        self.moc = context
        
        self.subscribeToNotifications()
    }
    
    func onInsert(handler: Handler) -> Self {
        insertHandlers.append(handler)
        return self
    }
    
    func onChange(handler: Handler) -> Self {
        changeHandlers.append(handler)
        return self
    }
    
    func onDelete(handler: Handler) -> Self {
        deleteHandlers.append(handler)
        return self
    }
    
    func requestBook() -> Book? {
        let request = NSFetchRequest(entityName: Book.entityName)
        request.predicate = NSPredicate(format: "identifier == %@",
                                        argumentArray: [identifier])
        let books = try! moc.executeFetchRequest(request) as! [Book]
        return books.first
    }
    
    private func filteredObjects(objects: AnyObject?) -> [Book] {
        guard let objects = objects as? Set<NSManagedObject> else { return [] }
        
        let books = objects.filter { $0.entity.name == Book.entityName } as! [Book]
        return books.filter { $0.identifier == identifier }
    }
    
    func subscribeToNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:  #selector(BookObserver.observe(_:)), name: NSManagedObjectContextObjectsDidChangeNotification, object: moc)
    }
    
    func unsubscribeFromNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @objc func observe(notification: NSNotification) {
        guard let info = notification.userInfo else { return }
        let updated = filteredObjects(info[NSUpdatedObjectsKey]);
        let deleted = filteredObjects(info[NSDeletedObjectsKey]);
        let inserted = filteredObjects(info[NSInsertedObjectsKey]);
        
        if let book = updated.first {
            for handler in changeHandlers {
                handler(book: book)
            }
        }
        
        if let book = deleted.first {
            for handler in deleteHandlers {
                handler(book: book)
            }
        }
        
        if let book = inserted.first {
            for handler in insertHandlers {
                handler(book: book)
            }
        }
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
}
