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
    static let width = CGFloat(150)
    static let heightForEvents = CGFloat(50)
    // TODO 450 const in multiple places
    static let size = CGSize(width: AUEventView.width, height: 50 + AUEventView.heightForEvents)
    
    private let log = AULog.instance
    let withRightBorder: Bool
//    let viewLabel: AUDateViewLabel
    var auDelegate: AUEventViewDelegate?
    var eventFieldDelegate: AUEventFieldDelegate? {
        didSet {
            for eventView in self.eventViews {
                eventView.auDelegate = self.eventFieldDelegate
            }
        }
    }
    
    var events: [AUEvent] = [] {
        didSet {
            events.sortInPlace() {(lhs: AUEvent, rhs: AUEvent) -> Bool in
                var compareResult = NSComparisonResult.OrderedSame
                if let lhsCreationDate = lhs.creationDate, rhsCreationDate = rhs.creationDate {
                    compareResult = lhsCreationDate.compare(rhsCreationDate)
                }
                if compareResult == .OrderedSame {
                    compareResult = lhs.description.compare(rhs.description)
                }
                return compareResult == .OrderedAscending
            }
            self.eventViews = events.map({ (event) -> AUEventField in
                // TODO fix height constraint
                let eventField = AUEventField(origin: CGPoint.zero, width: AUEventView.size.width, event: event)
                eventField.auDelegate = self.eventFieldDelegate
                return eventField
            })
        }
    }
    
    var height: CGFloat {
        get {
            return self.frame.height
        }
        set {
            let delta = newValue - self.height
            self.setFrameSize(NSSize(width: self.frame.width, height: newValue))
            for subview in self.subviews {
                    subview.setFrameOrigin(NSPoint(x: subview.frame.origin.x, y: subview.frame.origin.y + delta))
            }
        }
    }
    
    var desiredHeight: CGFloat {
        get {
            let eventHeight = eventViews.reduce(0) {(totalHeight, eventView) in
                return totalHeight + eventView.frame.height + AUEventView.eventMargin
            }
            return max(eventHeight + 0/*self.viewLabel.frame.height*/, AUEventView.size.height)
        }
    }
    
    private var eventViews: [AUEventField] = [] {
        didSet(oldEventViews) {
            for oldView in oldEventViews {
                oldView.removeFromSuperview()
            }
            
            var y = self.frame.height// - self.viewLabel.frame.height
            for view in self.eventViews {
                y -= view.frame.size.height + AUEventView.eventMargin
                view.frame.origin.y = y
                self.addSubview(view)
            }
        }
    }
    
    
    init(origin: CGPoint, withRightBorder: Bool = true) {
//        self.viewLabel = AUDateViewLabel(date: date, origin: CGPoint(x: 0, y: AUDateView.heightForEvents))
        self.withRightBorder = withRightBorder
        
        let frame = NSRect(origin: origin, size: AUEventView.size)
        super.init(frame: frame)
        
        //self.addSubview(viewLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        if self.withRightBorder {
            self.drawBorders()
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        if theEvent.clickCount == 2 {
            self.auDelegate?.requestNewEventForDateView?(self)
        } else {
            self.auDelegate?.selectDateView?(self)
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

@objc protocol AUEventViewDelegate {
    optional func selectDateView(dateView: AUEventView)
    
    optional func requestNewEventForDateView(dateView: AUEventView)
}
