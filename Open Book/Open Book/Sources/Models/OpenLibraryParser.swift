//
//  OpenLibraryParser.swift
//  Open Book
//
//  Created by martin chibwe on 7/29/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import Foundation
import SwiftyJSON

class OpenLibraryParser {
    
    struct Book {
        let title: String?
        let authorNames: [String]?
        let authors: [String]?
        let editionKeys: [String]?
        let identifier: String?
        let coverId: Int?
        let publicScan: Bool?
        let lendingEdition: String?
        let coverEdition: String?
        
        init(json: JSON) {
            title = json["title"].string
            authorNames = (json["author_name"].array ?? []).map { $0.string! }
            authors = (json["authors"].array ?? []).flatMap { $0["name"].string } 
            editionKeys = (json["edition_key"].array ?? []).map { $0.string! }
            identifier = json["key"].string
            coverId = json["cover_i"].int ?? json["cover_id"].int
            publicScan = json["public_scan_b"].bool
            lendingEdition = json["lending_edition"].string
            coverEdition = json["cover_edition_key"].string
        }
    }
    
    struct BookEditionDetails {
        struct Language {
            let key: String?
            
            init(json: JSON) {
                key = json["key"].string
            }
        }
        
        struct Author {
            let name: String?
            
            init(json: JSON) {
                name = json["name"].string
            }
        }
        
        let title: String?
        let numberOfPages: Int?
        let languages: [Language]
        let authors: [Author]
        let publishingDate: String?
        let thumbnailUrl: String?
        let subjects: [String]?
        let description: String?
        let coverIds: [Int]?
        let genres: [String]?
        
        init(json: JSON, identifier: String) {
            let object = json["OLID:\(identifier)"]
            thumbnailUrl = object["thumbnail_url"].string
            
            let details = object["details"]
            title = details["title"].string
            numberOfPages = details["number_of_pages"].int
            languages = (details["languages"].array ?? []).map(Language.init)
            publishingDate = details["publish_date"].string
            authors = (details["authors"].array ?? []).map(Author.init)
            subjects = details["subjects"].array?.flatMap { $0.string }
            description = details["description"]["value"].string
            coverIds = details["covers"].array?.flatMap { $0.int }
            genres = details["genres"].array?.flatMap { $0.string }
        }
    }
    
    struct BookEditionData {
        struct Subject {
            let name: String?
            
            init(json: JSON) {
                name = json["name"].string
            }
        }
        
        struct Format {
            let type: String
            let url: String
        }
        
        let subjects: [Subject]
        let formats: [Format]
        
        init(json: JSON, identifier: String) {
            let data = json["OLID:\(identifier)"]
            subjects = (data["subjects"].array ?? []).map(Subject.init)
            formats = (data["ebooks"].array?.first?["formats"].dictionary ?? [:]).map({ type, formatJson in
                return Format(type: type, url: formatJson["url"].string!)
            })
        }
    }
    
    class func bookDescriptionsFormJSON(json: JSON) -> [Book]? {
        guard let docs = json["docs"].array else { return nil }
        
        return docs.map { Book(json: $0) }
    }
    
    class func bookDescriptionsFormSubjectJSON(json: JSON) -> [Book]? {
        guard let works = json["works"].array else { return nil }
        
        return works.map { Book(json: $0) }
    }
}