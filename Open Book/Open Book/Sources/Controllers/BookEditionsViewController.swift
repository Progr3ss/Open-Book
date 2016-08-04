//
//  BookEditionsViewController.swift
//  Open Book
//
//  Created by martin chibwe on 7/26/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreData

class BookEditionsViewController: UIViewController {
    var bookIdentifier: String!
    var editions = [String]()
    
    var managedObjectContext: NSManagedObjectContext!
    
    @IBOutlet weak var editionsTableView: UITableView!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show edition" {
            let edition = editions[editionsTableView.indexPathForSelectedRow!.row]
            let vc = segue.destinationViewController as! BookDetailViewController
            vc.editionIdentifier = edition
            vc.managedObjectContext = managedObjectContext
        }
    }
}

extension BookEditionsViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return editions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("book edition cell", forIndexPath: indexPath)
        cell.textLabel?.text = editions[indexPath.row]
        return cell
    }
}
