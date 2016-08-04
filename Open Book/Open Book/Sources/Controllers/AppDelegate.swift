//
//  AppDelegate.swift
//  Open Book
//
//  Created by martin chibwe on 7/12/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
    
    var coreDataStack = CoreDataStack()
    var managedObjectContext: NSManagedObjectContext {
        return coreDataStack.managedObjectContext
    }

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let tabBarController = window!.rootViewController as! UITabBarController
        let booksNavVC = tabBarController.viewControllers![0] as! UINavigationController
        let booksVC = booksNavVC.topViewController! as! BooksViewController
        booksVC.managedObjectContext = managedObjectContext
        let detailedNavVC = tabBarController.viewControllers![1] as! UINavigationController
        let detailVC = detailedNavVC.topViewController! as! FeaturedBooksViewController
        detailVC.managedObjectContext = managedObjectContext
        
        
        let searchNavVC = tabBarController.viewControllers![2] as! UINavigationController
        let searchVC = searchNavVC.topViewController! as! BooksSearchViewController
        searchVC.managedObjectContext = managedObjectContext
        
		return true
	}

	func applicationWillTerminate(application: UIApplication) {
        coreDataStack.saveMainContext()
	}
}
