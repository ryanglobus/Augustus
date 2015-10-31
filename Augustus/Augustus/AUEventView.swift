//
//  AUEventView.swift
//  Augustus
//
//  Created by Ryan Globus on 7/29/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class AUEventView: NSView {
    static let eventMargin: CGFloat = 5
    
    private let log = AULog.instance
    let withRightBorder: Bool
    var auDelegate: AUEventViewDelegate? {
        didSet { self.didSetAuDelegate() }
    }
    private var bottomConstraint_: NSLayoutConstraint?
    private var eventViews: [AUEventField] = [] // TODO rename
    
    var events: [AUEvent] {
        didSet { self.didSetEvents(oldValue) }
    }
    
    
    init(withRightBorder: Bool = true) {
        self.withRightBorder = withRightBorder
        self.events = []
        super.init(frame: NSRect())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func didSetEvents(oldValue: [AUEvent]) {
        let sortedEvents = self.events.sort() {(lhs: AUEvent, rhs: AUEvent) -> Bool in
            var compareResult = NSComparisonResult.OrderedSame
            if let lhsCreationDate = lhs.creationDate, rhsCreationDate = rhs.creationDate {
                compareResult = lhsCreationDate.compare(rhsCreationDate)
            }
            if compareResult == .OrderedSame {
                compareResult = lhs.description.compare(rhs.description)
            }
            return compareResult == .OrderedAscending
        }
        
        for eventView in self.eventViews {
            eventView.removeFromSuperview()
        }
        self.eventViews = []
        var previousEventField_: AUEventField? = nil
        for event in sortedEvents {
            let eventField = AUEventField(event: event)
            eventField.auDelegate = self.auDelegate
            self.eventViews.append(eventField)
            self.addSubview(eventField)
            self.addEventFieldConstraints(eventField, previousEventField_: previousEventField_)
            previousEventField_ = eventField
        }
        
        if let bottomConstraint = self.bottomConstraint_ {
            self.removeConstraint(bottomConstraint)
        }
        if let lastEventField = previousEventField_ {
            let bottomConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .GreaterThanOrEqual, toItem: lastEventField, attribute: .Bottom, multiplier: 1, constant: 0)
            self.addConstraint(bottomConstraint)
            self.bottomConstraint_ = bottomConstraint
        }
        self.needsDisplay = true
    }
    
    private func didSetAuDelegate() {
        for eventField in self.eventViews {
            eventField.auDelegate = self.auDelegate
        }
    }
    
    private func addEventFieldConstraints(eventField: AUEventField, previousEventField_: AUEventField?) {
        let topConstraint: NSLayoutConstraint
        if let previousEventField = previousEventField_ {
            topConstraint = NSLayoutConstraint(item: eventField, attribute: .Top, relatedBy: .Equal, toItem: previousEventField, attribute: .Bottom, multiplier: 1, constant: 20)
        } else {
            topConstraint = NSLayoutConstraint(item: eventField, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
        }
        
        let leftConstraint = NSLayoutConstraint(item: eventField, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: eventField, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0)
        
        eventField.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([leftConstraint, rightConstraint, topConstraint])
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        if self.withRightBorder {
            self.drawBorders()
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        if theEvent.clickCount == 2 {
            self.auDelegate?.requestNewEventForEventView?(self)
        } else {
            self.auDelegate?.selectEventView?(self)
        }
    }
    
    private func drawBorders() {
        let path = NSBezierPath()
        // border to the right
        path.moveToPoint(NSPoint(x: self.frame.width, y: 0))
        path.lineToPoint(NSPoint(x: self.frame.width, y: self.frame.height))
        path.lineWidth = 2
        path.stroke()
    }
    
}

@objc protocol AUEventViewDelegate: AUEventFieldDelegate {
    optional func selectEventView(eventView: AUEventView)
    
    optional func requestNewEventForEventView(eventView: AUEventView)
}
