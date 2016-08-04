//
//  StatusViewController.swift
//  Open Book
//
//  Created by martin chibwe on 7/14/16.
//  Copyright © 2016 martin chibwe. All rights reserved.
//

import UIKit

class StatusViewController: UIViewController {
    
    var status: String? {
        didSet {
            updateStatus()
        }
    }
    
    var showActivity: Bool = false {
        didSet {
            updateActivity()
        }
    }
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var betweenConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateStatus()
        updateActivity()
    }
    
    func updateStatus() {
        guard isViewLoaded() else { return }
        
        statusLabel.text = status ?? ""
    }
    
    func updateActivity() {
        guard isViewLoaded() else { return }
        
        activityIndicator.hidden = !showActivity
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        betweenConstraint.active = showActivity
        leadingConstraint.active = !showActivity
    }
}
