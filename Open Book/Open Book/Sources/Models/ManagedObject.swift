//
//  ManagedObject.swift
//  Open Book
//
//  Created by martin chibwe on 7/23/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import Foundation
import CoreData

protocol ManagedObject {
    associatedtype ManagedObjectType = Self
}

extension ManagedObject where Self: NSManagedObject {
    static func createInContext(context: NSManagedObjectContext) -> Self {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! Self
    }
    
    static var entityName: String {
        return NSStringFromClass(Self).componentsSeparatedByString(".").last!
    }
}
