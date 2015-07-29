//
//  ViewController.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addDateViews()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func addDateViews() {
        let frameHeight = self.view.frame.height
        let subViewHeight = AUDateView.size.height
        let today = NSDate()
        let week = AUWeek(containingDate: today)
        var i = 0
        for date in week.dates() {
            let y = Double(frameHeight) - Double(subViewHeight) * Double(i + 1)
            println(y)
            let origin = CGPoint(x: 0, y: y)
            self.view.addSubview(AUDateView(date: date, origin: origin))
            i++
        }
    }


}

