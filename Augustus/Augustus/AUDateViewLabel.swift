//
//  AUDateViewLabel.swift
//  Augustus
//
//  Created by Ryan Globus on 7/19/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa
import AppKit

class AUDateViewLabel: NSView {
    
    let date: NSDate
    static let size = CGSize(width: AUDateView.width, height: 50)
    
    init(date: NSDate, origin: CGPoint) {
        let frame = NSRect(origin: origin, size: AUDateViewLabel.size)
        self.date = date
        super.init(frame: frame)
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
        path.lineToPoint(NSPoint(x: AUDateViewLabel.size.width, y: 0))
        // border to the right
        path.lineToPoint(NSPoint(x: AUDateViewLabel.size.width, y: AUDateViewLabel.size.height))
        path.lineWidth = 2
        path.stroke()
    }
    
    private func drawDayOfMonth() {
        let dayOfMonth = AUModel.calendar.component(NSCalendarUnit.CalendarUnitDay, fromDate: self.date)
        let dayOfMonthAttributes = [NSFontAttributeName: NSFont.boldSystemFontOfSize(20)]
        dayOfMonth.description.drawAtPoint(CGPoint(x: 0, y: 0), withAttributes: dayOfMonthAttributes)
    }
    
    private func drawDayOfWeek() {
        let dayOfWeek = AUModel.calendar.component(NSCalendarUnit.CalendarUnitWeekday, fromDate: self.date)
        let dayOfWeekAttributes = [NSFontAttributeName: NSFont.systemFontOfSize(18)]
        AUDateViewLabel.nameForDayOfWeek(dayOfWeek)?.drawAtPoint(CGPoint(x: 0, y: 25), withAttributes: dayOfWeekAttributes)
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
                println("Invalid day of week: %i", dayOfWeek)
                return nil
        }
    }
    
}