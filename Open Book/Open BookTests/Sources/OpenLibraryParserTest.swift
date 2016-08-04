//
//  OpenLibraryParserTest.swift
//  Open Book
//
//  Created by martin chibwe on 7/12/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import Open_Book

class OpenLibraryParserTest: XCTestCase {
    
    typealias OLParser = OpenLibraryParser
    
    func jsonNamed(name: String) -> JSON {
        let url = NSBundle(forClass: self.dynamicType).URLForResource(name, withExtension: "json")!
        let jsonData = NSData(contentsOfURL: url)!
        return JSON(data: jsonData)
    }
    
    func testSubjectParsing() {
        let fictionJson = jsonNamed("fiction")
        
        guard let books = OLParser.bookDescriptionsFormSubjectJSON(fictionJson) else {
            XCTFail("")
            return
        }
        
        XCTAssertEqual(12, books.count)
        XCTAssertEqual("Odyssey", books[0].title)
        XCTAssertEqual(6412687, books[0].coverId)
        XCTAssertTrue(books[0].authors! == ["Homer"])
    }
    
    func testBookDetailsParsing() {
        let bookDetailsJson = jsonNamed("booksDetails")
        let details = OLParser.BookEditionDetails(json: bookDetailsJson, identifier: "OL7099227M")
        
        XCTAssertTrue(details.authors.flatMap({ author in author.name }) == ["Matthew Arnold"])
        XCTAssertEqual("1882", details.publishingDate)
        XCTAssertEqual("Culture and anarchy", details.title)
        XCTAssertEqual("https://covers.openlibrary.org/b/id/5619538-S.jpg", details.thumbnailUrl)
    }
    
    func testBookDataParsing() {
        let bookDataJson = jsonNamed("booksData")
        let data = OLParser.BookEditionData(json: bookDataJson, identifier: "OL7099227M")
        
        XCTAssertEqual(4, data.subjects.flatMap({ $0.name }).count)
    }
}
