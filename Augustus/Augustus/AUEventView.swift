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
    
    fileprivate let log = AULog.instance
    let withRightBorder: Bool
    var auDelegate: AUEventViewDelegate? {
        didSet { self.didSetAuDelegate() }
    }
    fileprivate var bottomConstraint_: NSLayoutConstraint?
    fileprivate var eventViews: [AUEventField] = [] // TODO rename
    
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
    
    fileprivate func didSetEvents(_ oldValue: [AUEvent]) {
        let sortedEvents = self.events.sorted() {(lhs: AUEvent, rhs: AUEvent) -> Bool in
            var compareResult = ComparisonResult.orderedSame
            if let lhsCreationDate = lhs.creationDate, let rhsCreationDate = rhs.creationDate {
                compareResult = lhsCreationDate.compare(rhsCreationDate as Date)
            }
            if compareResult == .orderedSame {
                compareResult = lhs.description.compare(rhs.description)
            }
            return compareResult == .orderedAscending
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
            let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: lastEventField, attribute: .bottom, multiplier: 1, constant: 0)
            self.addConstraint(bottomConstraint)
            self.bottomConstraint_ = bottomConstraint
        }
        self.needsDisplay = true
    }
    
    fileprivate func didSetAuDelegate() {
        for eventField in self.eventViews {
            eventField.auDelegate = self.auDelegate
        }
    }
    
    fileprivate func addEventFieldConstraints(_ eventField: AUEventField, previousEventField_: AUEventField?) {
        let topConstraint: NSLayoutConstraint
        if let previousEventField = previousEventField_ {
            topConstraint = NSLayoutConstraint(item: eventField, attribute: .top, relatedBy: .equal, toItem: previousEventField, attribute: .bottom, multiplier: 1, constant: 20)
        } else {
            topConstraint = NSLayoutConstraint(item: eventField, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        }
        
        let leftConstraint = NSLayoutConstraint(item: eventField, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: eventField, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        
        eventField.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([leftConstraint, rightConstraint, topConstraint])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if self.withRightBorder {
            self.drawBorders()
        }
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        if theEvent.clickCount == 2 {
            self.auDelegate?.requestNewEventForEventView?(self)
        } else {
            self.auDelegate?.selectEventView?(self)
        }
    }
    
    fileprivate func drawBorders() {
        let path = NSBezierPath()
        // border to the right
        path.move(to: NSPoint(x: self.frame.width, y: 0))
        path.line(to: NSPoint(x: self.frame.width, y: self.frame.height))
        path.lineWidth = 2
        path.stroke()
    }
    
}

@objc protocol AUEventViewDelegate: AUEventFieldDelegate {
    @objc optional func selectEventView(_ eventView: AUEventView)
    
    @objc optional func requestNewEventForEventView(_ eventView: AUEventView)
}
