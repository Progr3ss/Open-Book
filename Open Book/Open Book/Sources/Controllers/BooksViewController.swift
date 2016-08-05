//
//  BooksViewController.swift
//  Open Book
//
//  Created by martin chibwe on 7/21/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import UIKit
import CoreData

class BooksViewController: UIViewController {
    var managedObjectContext: NSManagedObjectContext!
    
    lazy var booksController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: Book.entityName)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        request.sortDescriptors = [titleDescriptor]
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        try! controller.performFetch()
        controller.delegate = self
        return controller
    }()
    
    @IBOutlet weak var collectionView: UICollectionView!
    

    
    @IBAction func removeAllBooks() {
        guard let books = booksController.sections?[0].objects as? [Book]
            where books.count > 0 else {
            return
        }
        
        for book in books {
            managedObjectContext.deleteObject(book)
        }
        try! managedObjectContext.save()
        

    }
    
    typealias EmptyBlock = () -> ()
    private var updates = [EmptyBlock]()
}

extension BooksViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return booksController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! BookCell
        
        guard let book = booksController.sections?[indexPath.section].objects?[indexPath.row] as? Book else { fatalError("Cannot get book") }
        
        cell.titleView.text = book.title
        if let imageData = book.cover {
            cell.coverView.image = UIImage(data: imageData)
        }
        
        if case let .InProgress(_, totalBytes, bytesRead) = book.state {
            let progress: Float = {
                if totalBytes > 0 {
                    return Float(bytesRead) / Float(totalBytes)
                } else {
                    return 0
                }
            }()
            
            cell.progressView.progress = progress
            cell.progressView.hidden = false
        } else {
            cell.progressView.hidden = true
        }
       
        return cell
    }
}

extension BooksViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        updates.removeAll()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        let updatesBlock = {
            for update in self.updates {
                update()
            }
        }
        
        collectionView.performBatchUpdates(updatesBlock, completion: nil)
        updates.removeAll()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let collectionView = self.collectionView
        updates.append({
            switch type {
            case .Insert:
                return {
                    collectionView.insertItemsAtIndexPaths([newIndexPath!])
                }
            case .Update:
                return {
                    collectionView.reloadItemsAtIndexPaths([indexPath!])
                }
            case .Delete:
                return {
                    collectionView.deleteItemsAtIndexPaths([indexPath!])
                }
            case .Move:
                return {
                    collectionView.deleteItemsAtIndexPaths([indexPath!])
                    collectionView.insertItemsAtIndexPaths([newIndexPath!])
                }
            }
        }())
    }
}

class BookCell: UICollectionViewCell {
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        coverView.layer.borderColor =
            UIColor.lightGrayColor().colorWithAlphaComponent(0.5).CGColor
        coverView.layer.borderWidth = 1.0
    }
}
