//
//  OpenLibraryRouter.swift
//  Open Book
//
//  Created by martin chibwe on 7/21/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import Alamofire

enum Router: URLRequestConvertible {
    enum CoverSize: String {
        case Large = "L"
        case Medium = "M"
        case Small = "S"
    }
    
    case BookEditionDetails(editionIdentifier: String)
    case BookEditionData(editionIdentifier: String)
    case Subject(String)
    case Search(query: String)
    case Cover(id: Int, size: CoverSize)
    
    // MARK: URLRequestConvertible
    
    var URLRequest: NSMutableURLRequest {
        let result: (path: String, parameters: [(String, String)]) = {
            switch self {
            case BookEditionDetails(let editionIdentifier):
                return ("/api/books", parametersForBook(editionIdentifier, jscmd: "details"))
            case BookEditionData(let editionIdentifier):
                return ("/api/books", parametersForBook(editionIdentifier, jscmd: "data"))
            case Subject(let subject):
                return ("/subjects/\(subject).json", [("details", "true")])
            case Search(let query):
                return ("/search.json", [("q", query), ("has_fulltext", "true")])
            case let Cover(id, size):
                return ("/b/id/\(id)-\(size.rawValue).jpg", [])
            }
        }()
        
        let urlComponents = NSURLComponents()
        urlComponents.scheme = Router.scheme
        urlComponents.host = host
        urlComponents.path = result.path
        if result.parameters.count > 0 {
            urlComponents.queryItems = result.parameters.map { key, value in
                NSURLQueryItem(name: key, value: value)
            }
        }
        
        let url = urlComponents.URL!
        return NSMutableURLRequest(URL: url)
    }
    
    private static let mainHost = "openlibrary.org"
    private static let coversHost = "covers.openlibrary.org"
    
    private var host: String {
        switch self {
        case Cover:
            return Router.coversHost
        default:
            return Router.mainHost
        }
    }
    
    private static let scheme = "https"
    
    private func parametersForBook(identifier: String, jscmd: String) -> [(String, String)] {
        return [
            ("bibkeys", "OLID:\(identifier)"),
            ("format", "json"),
            ("jscmd", "\(jscmd)")
        ]
    }
}