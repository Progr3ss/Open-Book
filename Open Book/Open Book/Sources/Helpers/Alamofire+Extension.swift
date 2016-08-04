//
//  Alamofire+Extension.swift
//  Open Book
//
//  Created by martin chibwe on 7/12/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import Alamofire

extension Response {
    var cancelled: Bool {
        switch self.result {
        case .Failure(let error):
            if let urlError = error as? NSURLError where urlError == .Cancelled {
                return true
            } else {
                return false
            }
        case .Success(_):
            return false
        }
    }
}
