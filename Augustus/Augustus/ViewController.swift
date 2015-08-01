//
//  ViewController.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var calendar: AUCalendar = AUCalendarInMemory()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.calendar.addEvent(AUEvent(description: "Today is a great day!", date: NSDate()))
        self.calendar.addEvent(AUEvent(description: "Get ready for tomorrow", date: NSDate()))
        self.addDateViews()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func addDateViews() {
        let frameHeight = self.view.frame.height
//        let subViewHeight = AUDateViewLabel.size.height
        let today = NSDate()
        let week = AUWeek(containingDate: today)
        var i = 0
        let dates = week.dates()
        for date in dates {
//            let y = Double(frameHeight) - Double(subViewHeight) * Double(i + 1)
            let y = 0.0
            let x = Double(AUDateViewLabel.size.width) * Double(i)
            let origin = CGPoint(x: x, y: y)
            let events = self.calendar.eventsForDate(date)
            let withRightBorder = (i != dates.count - 1)
            let view = AUDateView(date: date, origin: origin, withRightBorder: withRightBorder)
            self.view.addSubview(view)
            view.addEvents(events)
            i++
        }
    }


}

