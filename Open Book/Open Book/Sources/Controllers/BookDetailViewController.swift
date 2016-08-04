//
//  BookDetailViewController.swift
//  Open Book
//
//  Created by martin chibweon 7/25/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import SwiftyJSON
import CoreData

private struct BookInfo {
    var title: String?
    var authors: [String]?
    struct DownloadInfo {
        let url: NSURL
        let format: String
    }
    var downloadInfo: DownloadInfo?
}

private protocol Section {
    var title: String { get }
    func contentView() -> UIView
}

private struct DescriptionSection: Section {
    let title = "Book Description"
    var description: String
    private func contentView() -> UIView {
        let label = UILabel().unmasked()
        label.text = description
        label.font = UIFont.systemFontOfSize(12)
        label.textColor = UIColor.darkGrayColor()
        label.numberOfLines = 0
        
        return label
    }
}

private struct InfoSection: Section {
    let title = "Information"
    var infos: [(caption: String, value: String)]
    
    private func contentView() -> UIView {
        let stackView = UIStackView().unmasked()
        stackView.axis = .Vertical
        stackView.spacing = 6

        for info in infos {
            let font = UIFont.systemFontOfSize(12)
            let captionLabel = UILabel().unmasked()
            captionLabel.text = info.caption
            captionLabel.widthAnchor.constraintEqualToConstant(70).active = true
            captionLabel.font = font
            captionLabel.textColor = UIColor.lightGrayColor()
            captionLabel.textAlignment = .Right

            let valueLabel = UILabel().unmasked()
            valueLabel.text = info.value
            valueLabel.font = font
            valueLabel.numberOfLines = 0

            let cell = UIStackView(arrangedSubviews: [captionLabel, valueLabel])
            cell.alignment = .Leading
            cell.axis = .Horizontal
            cell.spacing = 10
            stackView.addArrangedSubview(cell)
        }
        
        return stackView
    }
}

class BookDetailViewController: UIViewController {

    var editionIdentifier: String!
    var managedObjectContext: NSManagedObjectContext!
    
    private typealias OLParser = OpenLibraryParser
    
    private enum State {
        case Initial
        case Loading
        case Loaded
        case Failed
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var separatorViewHeight: NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    
    private var statusViewController: StatusViewController!
    private var requests = [Request]()
    private var state: State = .Initial
    
    private var book: Book?
    
    private var bookDetails: OLParser.BookEditionDetails?
    private var bookData: OLParser.BookEditionData?
    
    private var bookInfo: BookInfo?
    
    private var sections = [Section]()
    
    private var bookObserver: BookObserver!
    
    var documentInteractionController: UIDocumentInteractionController?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        switch state {
        case .Initial:
            startLoadingBookInfo()
        default:
            break;
        }
        
        bookObserver = BookObserver(identifier: editionIdentifier, context: managedObjectContext)
        book = bookObserver.requestBook()
        
        bookObserver.onInsert { [unowned self] book in
            self.book = book
            self.updateUI()
        }
        
        bookObserver.onChange { [unowned self] book in
            self.updateUI()
        }
        
        bookObserver.onDelete { [unowned self] book in
            self.book = nil
            self.updateUI()
        }
        
        updateUI()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        bookObserver?.unsubscribeFromNotifications()
        bookObserver = nil
    }
    
    private func startLoadingBookInfo() {
        
        state = .Loading
        
        let detailsRequester = Router.BookEditionDetails(editionIdentifier: editionIdentifier)
        let detailsRequest = Alamofire.request(detailsRequester)
            .validate()
            .responseJSON { response in
                
            guard !response.cancelled else { return }
            
            switch response.result {
            case .Success(let value):
                let json = JSON(value)
                
                let details = OLParser.BookEditionDetails(json: json, identifier: self.editionIdentifier)
                self.consumeBookDetails(details)
                
            case .Failure(let error):
                self.finishLoadingWithError(error)
            }
        }
        
        let dataRequester = Router.BookEditionData(editionIdentifier: editionIdentifier)
        let dataRequest = Alamofire.request(dataRequester)
            .validate()
            .responseJSON { response in
                
            guard !response.cancelled else { return }
                
            switch response.result {
            case .Success(let value):
                let json = JSON(value)
                
                let data = OLParser.BookEditionData(json: json, identifier: self.editionIdentifier)
                self.consumeBookData(data)
                
            case .Failure(let error):
                self.finishLoadingWithError(error)
            }
        }
        
        requests = [detailsRequest, dataRequest]
        
        updateUI()
    }
    
    private func consumeBookData(data: OLParser.BookEditionData) {
        bookData = data
        
        if bookDetails != nil {
            finishLoading()
        }
    }
    
    private func consumeBookDetails(details: OLParser.BookEditionDetails) {
        bookDetails = details
        if bookData != nil {
            finishLoading()
        }
    }
    
    private func finishLoadingWithError(error: NSError) {
        // TODO: handle error?
        state = .Failed
        updateUI()
    }
    
    private func finishLoading() {
        cancelAllRequests()
        state = .Loaded
        
        var infos: [(caption: String, value: String)] = []
        
        if let publishingDate = bookDetails?.publishingDate {
            infos.append(("Published", publishingDate))
        }
        
        if let subjects = bookDetails?.subjects where subjects.count > 0 {
            infos.append(("Subjects", subjects.joinWithSeparator(", ")))
        }
        
        if let genres = bookDetails?.genres where genres.count > 0 {
            infos.append(("Genres", genres.joinWithSeparator(", ")))
        }
        
        if let numberOfPages = bookDetails?.numberOfPages {
            infos.append(("Pages", "\(numberOfPages)"))
        }
        
        let formatTypes = Set((bookData?.formats ?? []).map({ $0.type })).sort()
        if formatTypes.count > 0 {
            infos.append(("Formats", formatTypes.joinWithSeparator(", ")))
        }
        
        let authors: [String] = (bookDetails?.authors.flatMap({ $0.name }) ?? [])
        
        var downloadInfo: BookInfo.DownloadInfo?
        if let formats = bookData?.formats {
            let epubs = formats.filter { $0.type == "epub" }
            let pdfs = formats.filter { $0.type == "pdf" }
            
            let docs = epubs + pdfs
            if let format = docs.first, let url = NSURL(string: format.url) {
                downloadInfo = BookInfo.DownloadInfo(url: url, format: format.type)
            }
        }
        
        bookInfo = BookInfo(title: bookDetails?.title, authors: authors, downloadInfo: downloadInfo)
        
        if let coverId = bookDetails?.coverIds?.first {
            let coverUrl = Router.Cover(id: coverId, size: .Medium).URLRequest.URL!
            coverView.af_setImageWithURL(coverUrl)
        }
        
        sections = []
        
        if let description = bookDetails?.description {
            sections.append(DescriptionSection(description: description))
        }
        
        if infos.count > 0 {
            sections.append(InfoSection(infos: infos))
        }
        
        tableView.reloadData()
        
        updateUI()
    }
    
    private func cancelAllRequests() {
        for request in requests {
            request.cancel()
        }
        
        requests.removeAll()
    }
    
    private func updateUI() {
        
        guard isViewLoaded() else { return }
        
        var activityIndicatorVisible = false
        var status: String?
        var isSeparatorVisible = false
        
        switch state {
        case .Initial:
            break
        case .Loading:
            status = "Loading..."
            activityIndicatorVisible = true
        case .Loaded:
            isSeparatorVisible = true
        case .Failed:
            status = "Cannot load book info"
        }
        
        statusViewController.showActivity = activityIndicatorVisible
        statusViewController.status = status
        
        titleLabel.text = bookInfo?.title
        authorLabel.text = bookInfo?.authors?.joinWithSeparator(", ")
        
        tableView.separatorStyle = status != nil ? .None : .SingleLine
        separatorView.hidden = !isSeparatorVisible
        
        let buttonTitle: String
        (buttonTitle, downloadButton.enabled) = {
            guard let book = self.book else {
                if let info = bookInfo?.downloadInfo {
                    return ("Get \(info.format)", true)
                }
                return ("N/A", false)
            }
            
            switch book.state {
            case .Fault:
                return ("Download", true)
            case .InProgress:
                return ("Downloading...", false)
            case .Downloaded:
                return ("Open", true)
            }
        }()
        
        downloadButton.setTitle(buttonTitle, forState: .Normal)
        downloadButton.hidden = !(state == .Loaded)
        
        (downloadProgressView.progress, downloadProgressView.hidden) = {
            guard let book = self.book else { return (0, true) }
            
            guard case let .InProgress(_, totalBytes, totalBytesRead) = book.state else { return (0, true) }
            
            guard totalBytes > 0 else { return (0, false) }
            
            return (Float(totalBytesRead) / Float(totalBytes), false)
        }()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let identifier = String(StatusViewController.self)
        statusViewController = storyboard!.instantiateViewControllerWithIdentifier(identifier) as! StatusViewController
        
        addChildViewController(statusViewController)
        tableView.backgroundView = statusViewController.view
        statusViewController.didMoveToParentViewController(self)
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        separatorViewHeight.constant = 1.0 / traitCollection.displayScale
    }
    
    @IBAction func startDownloading(sender: UIButton) {
        if let book = self.book, case let .Downloaded(localUrl) = book.state {
            let controller = UIDocumentInteractionController(URL: localUrl)
            controller.delegate = self
            controller.presentOpenInMenuFromRect(CGRect.zero, inView: self.view, animated: true)
            self.documentInteractionController = controller
            return
        }
        
        guard let url = bookInfo?.downloadInfo?.url else { return }
        
        let book = Book.createInContext(managedObjectContext)
        book.identifier = editionIdentifier
        book.title = bookInfo?.title
        book.authors = bookInfo?.authors?.joinWithSeparator(", ")
        book.url = url
        if let image = coverView.image {
            book.cover = UIImagePNGRepresentation(image)
        }
        
        try! book.managedObjectContext?.save()
        book.startDownloading()
    }
}

extension BookDetailViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! SectionTableViewCell
        let section = sections[indexPath.row]
        cell.titleLabel.text = section.title
        let contentView = section.contentView().unmasked()
        for subview in cell.containerView.subviews {
            subview.removeFromSuperview()
        }
        
        cell.containerView.addArrangedSubview(contentView)
        
        return cell
    }
}

extension BookDetailViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerDidDismissOpenInMenu(controller: UIDocumentInteractionController) {
        documentInteractionController?.delegate = nil
        documentInteractionController = nil
    }
}

class SectionTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerView: UIStackView!
}
