//
//  FeaturedBooksViewController.swift
//  Open Book
//
//  Created by martin chibwe on 7/14/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import SwiftyJSON
import CoreData

struct SubjectRequest {
    let name: String
    let localizedTitle: String
}

protocol SubjectDelegate: class {
    func subjectImageDownloader(subject: Subject) -> ImageDownloader?
    func subject(subject: Subject, didLoadCoverForBookAtIndex index: Int)
}

class Subject {
    let localizedTitle: String
    let bookControllers: [BookController]
    
    weak var delegate: SubjectDelegate?
    
    init(localizedTitle: String, books: [OpenLibraryParser.Book]) {
        self.localizedTitle = localizedTitle
        bookControllers = books.map(BookController.init)
        for bookController in bookControllers {
            bookController.delegate = self
        }
    }
}

extension Subject: BookControllerDelegate {
    func bookControllerDidDownloadCover(bookController: BookController) {
        guard let index = bookControllers.indexOf({ $0 === bookController }) else {
            return
        }
        
        delegate?.subject(self, didLoadCoverForBookAtIndex: index)
    }
    
    func bookControllerImageDownloader(bookController: BookController) -> ImageDownloader? {
        return delegate?.subjectImageDownloader(self)
    }
}

protocol BookControllerDelegate: class {
    func bookControllerImageDownloader(bookController: BookController) -> ImageDownloader?
    func bookControllerDidDownloadCover(bookController: BookController)
}

class BookController {
    var title: String? { return book.title }
    var authors: [String]? { return book.authors }
    
    let book: OpenLibraryParser.Book
    weak var delegate: BookControllerDelegate?
    
    private(set) var cover: UIImage?
    private var coverReceipt: RequestReceipt?
    
    init(book: OpenLibraryParser.Book) {
        self.book = book
    }
	
	
    
    func startLoadingCoverIfAvailable() {
        guard coverReceipt == nil && cover == nil else { return }
        guard let coverId = book.coverId else { return }
        guard let delegate = self.delegate else { return }
        guard let url = NSURL(string: "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg") else { return }
        
        let downloader = delegate.bookControllerImageDownloader(self)
        let request = NSURLRequest(URL: url)
        coverReceipt = downloader?.downloadImage(URLRequest: request) {
            response in
            
            self.coverReceipt = nil
            
            switch response.result {
            case .Success(let image):
                self.cover = image
                delegate.bookControllerDidDownloadCover(self)
            case .Failure(let error):
				
                print("Cannot download image with error: \(error)")
            }
        }
    }
}

class FeaturedBooksViewController: UIViewController {
    
    enum State {
        case Loading
        case Loaded
        case Failed
    }
    
    var subjects = [Subject]()
    var state = State.Failed {
        didSet {
            if isViewLoaded() {
                updateUI()
            }
        }
    }
    
    var subjectRequests = [SubjectRequest]()
    
    var imageDownloader = ImageDownloader()
    
    var statusController: StatusViewController!
    var managedObjectContext: NSManagedObjectContext!
    
    @IBOutlet weak var subjectsTableView: UITableView!
	
	
	
	func displayFailure(){
		
		let alert = UIAlertController(title: "Under Maintenance", message: "The Site will be back up shortly. Come back later", preferredStyle: UIAlertControllerStyle.Alert)
		
		alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
		
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
    func startLoadingNextSubjectOrFinish() {
        guard let subjectRequest = subjectRequests.first else {
            state = .Loaded
            for subject in self.subjects {
                subject.delegate = self
            }
            subjectsTableView.reloadData()
            return
        }
        
        subjectRequests.removeFirst()
        
        let localRequest = Alamofire.request(Router.Subject(subjectRequest.name))
        localRequest.responseJSON { response in
            var shouldContinue = false
            switch response.result {
            case .Success(let value):
                let json = JSON(value)
                guard let books = OpenLibraryParser.bookDescriptionsFormSubjectJSON(json) else {
                    break
                }
                
                self.subjects.append(Subject(localizedTitle: subjectRequest.localizedTitle, books: books))
                shouldContinue = true
            case .Failure(let error):
				self.displayFailure()
                print("Cannot load books with error: \(error)")
            }
            
            if shouldContinue {
                self.startLoadingNextSubjectOrFinish()
            } else {
                self.state = .Failed
                self.subjects.removeAll()
                self.subjectRequests.removeAll()
            }
        }
    }
    
    func reloadSubjects() {
        state = .Loading
        
        subjects.removeAll()
        
        subjectRequests = [
            SubjectRequest(name: "history", localizedTitle: "History"),
            SubjectRequest(name: "philosophy", localizedTitle: "Philosophy"),
            SubjectRequest(name: "science_fiction", localizedTitle: "Science Fiction"),
            SubjectRequest(name: "fiction", localizedTitle: "Fiction"),
            SubjectRequest(name: "romance", localizedTitle: "Romance"),
            SubjectRequest(name: "drama", localizedTitle: "Drama"),
        ]
        
        startLoadingNextSubjectOrFinish()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if state == .Failed {
            reloadSubjects()
        }
        
        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let identifier = String(StatusViewController.self)
        statusController = storyboard!.instantiateViewControllerWithIdentifier(identifier) as! StatusViewController
        
        addChildViewController(statusController)
        subjectsTableView.backgroundView = statusController.view
        statusController.didMoveToParentViewController(self)
    }
    
    func updateUI() {
        var text: String?
        var showIndicator = false
        var showStatusView = false
        
        switch state {
        case .Failed:
			
            text = "Cannot load featured books"
            showStatusView = true
        case .Loading:
            text = "Loading..."
            showIndicator = true
            showStatusView = true
        case .Loaded:
            break
        }
        
        statusController.showActivity = showIndicator
        statusController.status = text
        
        subjectsTableView.separatorStyle = showStatusView ? .None : .SingleLine
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "show book detail" {
            let cell = sender! as! BookCollectionViewCell
            let bookController = subjects[cell.subjectIndex].bookControllers[cell.bookIndex]
            
            let vc = segue.destinationViewController as! BookDetailViewController
            vc.editionIdentifier = bookController.book.lendingEdition
            vc.managedObjectContext = managedObjectContext
        }
    }
}

extension FeaturedBooksViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subjects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("subject cell", forIndexPath: indexPath) as! SubjectTableViewCell
        
        let subject = subjects[indexPath.row]
        cell.subjectTitleLabel.text = subject.localizedTitle
        
        return cell
    }
}

extension FeaturedBooksViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let subjectCell = cell as! SubjectTableViewCell
        
        subjectCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
    }
}

extension FeaturedBooksViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subjects[collectionView.tag].bookControllers.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("book cell", forIndexPath: indexPath) as! BookCollectionViewCell
        
        let bookController = subjects[collectionView.tag].bookControllers[indexPath.item]
        cell.titleLabel.text = bookController.title
        cell.authorLabel.text = bookController.authors?.joinWithSeparator(", ")
        
        return cell
    }
}

extension FeaturedBooksViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let bookController = subjects[collectionView.tag].bookControllers[indexPath.item]
        
        let bookCell = cell as! BookCollectionViewCell
        bookCell.coverImageView.image = bookController.cover
        bookCell.bookIndex = indexPath.item
        bookCell.subjectIndex = collectionView.tag
        bookController.startLoadingCoverIfAvailable()
    }
}

extension FeaturedBooksViewController: UICollectionViewDelegateFlowLayout {}

extension FeaturedBooksViewController: SubjectDelegate {
    func subjectImageDownloader(subject: Subject) -> ImageDownloader? {
        return imageDownloader
    }
    
    func subject(subject: Subject, didLoadCoverForBookAtIndex index: Int) {
        guard let subjectIndex = subjects.indexOf({ $0 === subject}) else {
            return
        }
        
        guard let subjectCell = subjectsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: subjectIndex, inSection: 0)) as? SubjectTableViewCell else { return }
        
        guard let bookCell = subjectCell.booksCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) as? BookCollectionViewCell else { return }
        
        bookCell.coverImageView.image = subject.bookControllers[index].cover
    }
}

class SubjectTableViewCell: UITableViewCell {
    @IBOutlet weak var subjectTitleLabel: UILabel!
    @IBOutlet weak var booksCollectionView: UICollectionView!
    
    func setCollectionViewDataSourceDelegate
        <D: protocol<UICollectionViewDataSource, UICollectionViewDelegate>>
        (dataSourceDelegate: D, forRow row: Int) {
        
        booksCollectionView.delegate = dataSourceDelegate
        booksCollectionView.dataSource = dataSourceDelegate
        booksCollectionView.tag = row
        booksCollectionView.reloadData()
    }
}

class BookCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    
    var subjectIndex = 0
    var bookIndex = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        coverImageView.layer.borderColor =
            UIColor.lightGrayColor().colorWithAlphaComponent(0.5).CGColor
        coverImageView.layer.borderWidth = 1.0
    }
}
