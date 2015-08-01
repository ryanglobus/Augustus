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
                let date = week[i]
                let view = dateViews[i]
                view.date = date
                view.events = calendar.eventsForDate(date)
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
    
    private func addDateViews() { // dup code here?
        let frameHeight = self.view.frame.height
        var i = 0
        let dates = self.week.dates()
        for date in dates {
            let x = Double(AUDateViewLabel.size.width) * Double(i)
            let origin = CGPoint(x: x, y: 0)
            let events = self.calendar.eventsForDate(date)
            let withRightBorder = (i != dates.count - 1)
            let view = AUDateView(date: date, origin: origin, withRightBorder: withRightBorder)
            self.view.addSubview(view)
            view.events = events
            self.dateViews.append(view)
            i++
        }
    }


}

