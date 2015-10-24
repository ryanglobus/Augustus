//
//  AUDateViewLabel.swift
//  Augustus
//
//  Created by Ryan Globus on 7/19/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa
import AppKit

class AUDateLabel: NSView {
    
    var date: NSDate
    override var intrinsicContentSize: NSSize {
        return CGSize(width: AUEventView.width, height: 50)
    }
    
    convenience init(date: NSDate) {
        self.init(date: date, frame: NSRect())
    }
    
    init(date: NSDate, frame frameRect: NSRect) {
        self.date = date
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        NSGraphicsContext.currentContext()?.saveGraphicsState()
        
        // Drawing code here.
        self.drawBorders()
        self.drawDayOfMonth()
        self.drawDayOfWeek()
        
        NSGraphicsContext.currentContext()?.restoreGraphicsState()
    }
    
    // TODO fonts and placement are not robust
    private func drawBorders() {
        let path = NSBezierPath()
        // border below
        path.moveToPoint(NSPoint(x: 0, y: 0))
        path.lineToPoint(NSPoint(x: self.frame.width, y: 0))
        path.lineWidth = 2
        path.stroke()
    }
    
    private func drawDayOfMonth() {
        let dayOfMonth = AUModel.calendar.component(NSCalendarUnit.Day, fromDate: self.date).description
        let dayOfMonthAttributes = [NSFontAttributeName: NSFont.boldSystemFontOfSize(20)]
        let dayOfMonthLabel = NSAttributedString(string: dayOfMonth, attributes: dayOfMonthAttributes)
        let x = (self.frame.width - dayOfMonthLabel.size().width) / 2.0
        dayOfMonthLabel.drawAtPoint(CGPoint(x: x, y: 0))
    }
    
    private func drawDayOfWeek() {
        let dayOfWeekNumber = AUModel.calendar.component(NSCalendarUnit.Weekday, fromDate: self.date)
        if let dayOfWeek = AUDateLabel.nameForDayOfWeek(dayOfWeekNumber) {
            let dayOfWeekAttributes = [NSFontAttributeName: NSFont.systemFontOfSize(18)]
            let dayOfWeekLabel = NSAttributedString(string: dayOfWeek, attributes: dayOfWeekAttributes)
            let x = (self.frame.width - dayOfWeekLabel.size().width) / 2.0
            dayOfWeekLabel.drawAtPoint(CGPoint(x: x, y: 25))
        }
    }
    
    private static func nameForDayOfWeek(dayOfWeek: Int) -> String? {
        // TODO not robust
        switch(dayOfWeek) {
            case 1: return "Sunday"
            case 2: return "Monday"
            case 3: return "Tuesday"
            case 4: return "Wednesday"
            case 5: return "Thursday"
            case 6: return "Friday"
            case 7: return "Saturday"
            default:
                Swift.print("Invalid day of week: %i", dayOfWeek)
                return nil
        }
    }
    
}
