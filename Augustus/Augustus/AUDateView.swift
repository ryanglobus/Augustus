//
//  AUDateView.swift
//  Augustus
//
//  Created by Ryan Globus on 7/19/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa
import AppKit

class AUDateView: NSView {
    
    let date: NSDate
    static let size = CGSize(width: 100, height: 100)
    
    init(date: NSDate, origin: CGPoint) {
        let frame = NSRect(origin: origin, size: AUDateView.size)
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
        NSBezierPath.strokeRect(self.frame)
        let dayOfMonth = AUModel.calendar.component(NSCalendarUnit.CalendarUnitDay, fromDate: date)
        let dayOfMonthAttributes = [NSFontAttributeName: NSFont.boldSystemFontOfSize(20)]
        dayOfMonth.description.drawAtPoint(CGPoint(x: 0, y: 0), withAttributes: dayOfMonthAttributes)
        
        NSGraphicsContext.currentContext()?.restoreGraphicsState()
    }
    
}
