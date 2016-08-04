//
//  UIView+Extensions.swift
//  Open Book
//
//  Created by martin chibwe on 7/23/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import UIKit

extension UIView {
    func unmasked() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
}