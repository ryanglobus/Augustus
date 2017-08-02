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
    
    var date: Date
    var auDelegate: AUDateLabelDelegate?
    override var intrinsicContentSize: NSSize {
        return CGSize(width: 0, height: 50)
    }
    
    convenience init(date: Date) {
        self.init(date: date, frame: NSRect())
    }
    
    init(date: Date, frame frameRect: NSRect) {
        self.date = date
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSGraphicsContext.current()?.saveGraphicsState()
        
        // Drawing code here.
        self.drawBorders()
        self.drawDayOfMonth()
        self.drawDayOfWeek()
        
        NSGraphicsContext.current()?.restoreGraphicsState()
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        if theEvent.clickCount == 2 {
            self.auDelegate?.requestNewEventForDateLabel?(self)
        } else {
            self.auDelegate?.selectDateLabel?(self)
        }
    }
    
    // TODO fonts and placement are not robust
    fileprivate func drawBorders() {
        let path = NSBezierPath()
        // border below
        path.move(to: NSPoint(x: 0, y: 0))
        path.line(to: NSPoint(x: self.frame.width, y: 0))
        path.lineWidth = 2
        path.stroke()
    }
    
    fileprivate func drawDayOfMonth() {
        let dayOfMonth = (AUModel.calendar as NSCalendar).component(NSCalendar.Unit.day, from: self.date).description
        let dayOfMonthAttributes = [NSFontAttributeName: NSFont.boldSystemFont(ofSize: 20)]
        let dayOfMonthLabel = NSAttributedString(string: dayOfMonth, attributes: dayOfMonthAttributes)
        let x = (self.frame.width - dayOfMonthLabel.size().width) / 2.0
        dayOfMonthLabel.draw(at: CGPoint(x: x, y: 0))
    }
    
    fileprivate func drawDayOfWeek() {
        let dayOfWeekNumber = (AUModel.calendar as NSCalendar).component(NSCalendar.Unit.weekday, from: self.date)
        let dayOfWeek = AUModel.calendar.weekdaySymbols[dayOfWeekNumber - 1]
        let dayOfWeekAttributes = [NSFontAttributeName: NSFont.systemFont(ofSize: 18)]
        let dayOfWeekLabel = NSAttributedString(string: dayOfWeek, attributes: dayOfWeekAttributes)
        let x = (self.frame.width - dayOfWeekLabel.size().width) / 2.0
        dayOfWeekLabel.draw(at: CGPoint(x: x, y: 25))
    }
    
}

@objc protocol AUDateLabelDelegate {
    @objc optional func selectDateLabel(_ dateLabel: AUDateLabel)
    
    @objc optional func requestNewEventForDateLabel(_ dateLabel: AUDateLabel)
}
