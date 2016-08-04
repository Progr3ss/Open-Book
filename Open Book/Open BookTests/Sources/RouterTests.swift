//
//  RouterTests.swift
//  Open Book
//
//  Created by martin chibwe on 7/12/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import XCTest
@testable import Open_Book

class RouterTests: XCTestCase {
    func testRouterDetails() {
        let url = Router.BookEditionDetails(editionIdentifier: "OL7099227M").URLRequest.URL!
        XCTAssertEqual("https://openlibrary.org/api/books?bibkeys=OLID:OL7099227M&format=json&jscmd=details", url.absoluteString)
    }
    
    func testRouterData() {
        let url = Router.BookEditionData(editionIdentifier: "OL7099227M").URLRequest.URL!
        XCTAssertEqual("https://openlibrary.org/api/books?bibkeys=OLID:OL7099227M&format=json&jscmd=data", url.absoluteString)
    }
    
    func testSubject() {
        let url = Router.Subject("history").URLRequest.URL!
        XCTAssertEqual("https://openlibrary.org/subjects/history.json?details=true", url.absoluteString)
    }
    
    func testSearch() {
        let url = Router.Search(query: "home").URLRequest.URL!
        XCTAssertEqual("https://openlibrary.org/search.json?q=home&has_fulltext=true", url.absoluteString)
    }
    
    func testCover() {
        let url = Router.Cover(id: 42, size: .Medium).URLRequest.URL!
        XCTAssertEqual("https://covers.openlibrary.org/b/id/42-M.jpg", url.absoluteString)
    }
}
