//
//  CoreDataStack.swift
//  Open Book
//
//  Created by martin chibweon 7/26/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    private let modelName = "Open_Book"
    
    private lazy var documentsDirectoryURL: NSURL = {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
    }()
    
    private lazy var dataModel: NSManagedObjectModel = {
        let url = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: url)!
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.dataModel)
        
        let url = self.documentsDirectoryURL.URLByAppendingPathComponent("\(self.modelName).sqlite")
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        try! coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return context
    }()
    
    func saveMainContext() {
        if managedObjectContext.hasChanges {
            try! managedObjectContext.save()
        }
    }
}