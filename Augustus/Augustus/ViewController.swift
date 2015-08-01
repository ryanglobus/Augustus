//
//  ViewController.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSWindowDelegate {
    
    var calendar: AUCalendar = AUCalendarInMemory()
    var dateViews: [AUDateView] = []
    var week: AUWeek = AUWeek() {
        didSet {
            for i in 0..<AUWeek.numDaysInWeek {
                dateViews[i].date = week[i]
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var window = NSApplication.sharedApplication().windows[0] as? NSWindow
        window?.delegate = self;
        self.calendar.addEvent(AUEvent(description: "Today is a great day!", date: NSDate()))
        self.calendar.addEvent(AUEvent(description: "Get ready for tomorrow", date: NSDate()))
        self.addDateViews()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction
    func previousWeek(sender: AnyObject?) {
        self.week = week.plusNumWeeks(-1)
    }
    
    @IBAction
    func nextWeek(sender: AnyObject?) {
        self.week = week.plusNumWeeks(1)
    }
    
    @IBAction
    func todaysWeek(sender: AnyObject?) {
        self.week = AUWeek()
    }
    
    private func addDateViews() {
        let frameHeight = self.view.frame.height
//        let subViewHeight = AUDateViewLabel.size.height
        var i = 0
        let dates = self.week.dates()
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
            self.dateViews.append(view)
            i++
        }
    }


}

