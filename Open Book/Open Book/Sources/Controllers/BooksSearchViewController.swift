//
//  BooksSearchViewController.swift
//  Open Book
//
//  Created by martin chibwe on 7/23/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import UIKit

import Alamofire
import AlamofireImage
import SwiftyJSON
import CoreData

class BooksSearchViewController: UIViewController {
    
    var bookDescriptions = [BookSearchDescription]()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    let imageDownloader = ImageDownloader()
    
    var statusController: StatusViewController!
    
    var lastMessage: String?
    
    var managedObjectContext: NSManagedObjectContext!
    
    @IBOutlet weak var tableView: UITableView!
    
    var booksSearchRequest: Request?
    var searchIsInProgress: Bool {
        return booksSearchRequest != nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .Minimal
        searchController.hidesNavigationBarDuringPresentation = false
        
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
        
        let identifier = String(StatusViewController.self)
        statusController = storyboard!.instantiateViewControllerWithIdentifier(identifier) as! StatusViewController
        
        
        addChildViewController(statusController)
        tableView.backgroundView = statusController.view
        statusController.didMoveToParentViewController(self)
    }
    
    func cancelSearching() {
        booksSearchRequest?.cancel()
        booksSearchRequest = nil
    }
    
    func updateUI() {
        var text: String?
        var showIndicator = false
        var showStatusView = false
        
        if searchIsInProgress {
            text = "Loading..."
            showIndicator = true
            showStatusView = true
        } else if bookDescriptions.count == 0 {
            text = lastMessage
            showStatusView = true
        }
        
        statusController.showActivity = showIndicator
        statusController.status = text
        
        tableView.separatorStyle = showStatusView ? .None : .SingleLine
    }
    
    func startSearchingForQuery(query: String) {
        cancelSearching()
        
        bookDescriptions.removeAll()
        tableView.reloadData()
        
        booksSearchRequest = Alamofire.request(Router.Search(query: query))
            .validate().responseJSON { response in
            
            guard !response.cancelled else { return }
            
            switch response.result {
            case .Success(let jsonObject):
                let json = JSON(jsonObject)
                if let books = OpenLibraryParser.bookDescriptionsFormJSON(json) {
                    let bookDescriptions: [BookSearchDescription] = books.flatMap { book in
                        guard let title = book.title, identifier = book.identifier else { return nil }
                        return BookSearchDescription(title: title,
                            author: book.authorNames.map { $0.joinWithSeparator(", ") } ?? "",
                            identifier: identifier,
                            editionKeys: book.editionKeys ?? [],
                            coverId: book.coverId,
                            cover: nil)
                    }
                    
                    self.bookDescriptions = bookDescriptions
                    if self.bookDescriptions.count == 0 {
                        self.lastMessage = "No results for \"\(query)\""
                    }
                } else {
                    self.bookDescriptions = []
                    self.lastMessage = "Cannot load results"
                }
            case .Failure(let error):
                print("search failed with error: \(error)")
                self.lastMessage = "Cannot search"
            }
            
            self.booksSearchRequest = nil
            self.tableView.reloadData()
            self.updateUI()
        }
        
        updateUI()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show editions" {
            let vc = segue.destinationViewController as! BookEditionsViewController
            let book = bookDescriptions[tableView.indexPathForSelectedRow!.row]
            vc.bookIdentifier = book.identifier
            vc.editions = book.editionKeys
            vc.managedObjectContext = managedObjectContext
        } else if segue.identifier == "status" {
            statusController = segue.destinationViewController as! StatusViewController
        }
    }
}

extension BooksSearchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookDescriptions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("book cell", forIndexPath: indexPath) as! BookTableViewCell
        let book = bookDescriptions[indexPath.row]
        cell.titleLabel.text = book.title
        cell.authorLabel.text = book.author
        cell.coverImageView.image = book.cover
        return cell
    }
}

extension BooksSearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let bookDescription = bookDescriptions[indexPath.row]
        
        guard bookDescription.cover == nil else { return }
        
        guard let coverId = bookDescription.coverId, let coverUrl = bookDescription.coverUrl else { return }
        guard let url = NSURL(string: coverUrl) else { return }
        let urlRequest = NSURLRequest(URL: url)
        
        imageDownloader.downloadImage(URLRequest: urlRequest) { response in
            switch response.result {
            case .Success(let image):
                for (row, description) in self.bookDescriptions.enumerate() {
                    guard description.coverId == coverId else { continue }
                    self.bookDescriptions[row].cover = image
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: .Automatic)
                }
            default:
                print("Cannot load image for url: \(url)")
            }
        }
    }
}

extension BooksSearchViewController: UISearchBarDelegate {
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        if let query = searchController.searchBar.text where !query.isEmpty {
            startSearchingForQuery(query)
        }
        
        return true
    }
}

class BookTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
}
