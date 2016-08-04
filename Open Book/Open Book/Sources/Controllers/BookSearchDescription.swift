//
//  BookSearchDescription.swift
//  Open Book
//
//  Created by martin chibwe on 7/8/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import UIKit

struct BookSearchDescription {
    let title: String
    let author: String?
    let identifier: String
    let editionKeys: [String]
    let coverId: Int?
    
    var coverUrl: String? {
        guard let coverId = coverId else { return nil }
        return "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
    }
    
    var cover: UIImage?
}
