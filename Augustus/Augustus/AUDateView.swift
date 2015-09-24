//
//  AUDateView.swift
//  Augustus
//
//  Created by Ryan Globus on 7/29/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class AUDateView: NSView {
    static let eventMargin: CGFloat = 5
    static let width = CGFloat(150)
    static let heightForEvents = CGFloat(450)
    // TODO 450 const in multiple places
    static let size = CGSize(width: AUDateView.width, height: AUDateViewLabel.size.height + AUDateView.heightForEvents)
    
    private let log = AULog.instance
    let controller: ViewController
    let withRightBorder: Bool
    let viewLabel: AUDateViewLabel
    var auDelegate: AUDateViewDelegate?
    
    var date: NSDate {
        didSet {
            viewLabel.date = self.date
            viewLabel.needsDisplay = true
        }
    }
    
    var events: [AUEvent] = [] {
        didSet {
            events.sortInPlace() {(lhs: AUEvent, rhs: AUEvent) -> Bool in
                var compareResult = NSComparisonResult.OrderedSame
                if let lhsCreationDate = lhs.creationDate, rhsCreationDate = rhs.creationDate {
                    compareResult = lhsCreationDate.compare(rhsCreationDate)
                }
                if compareResult != .OrderedSame {
                    compareResult = lhs.description.compare(rhs.description)
                }
                return compareResult == .OrderedAscending
            }
            self.eventViews = events.map({ (event) -> NSView in
                // TODO fix height constraint
                let eventField = AUEventField(origin: CGPoint.zero, width: AUDateView.size.width, event: event)
                eventField.auDelegate = self.controller
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
                return totalHeight + eventView.frame.height + AUDateView.eventMargin
            }
            return max(eventHeight + self.viewLabel.frame.height, AUDateView.size.height)
        }
    }
    
    private var eventViews: [NSView] = [] {
        didSet(oldEventViews) {
            for oldView in oldEventViews {
                oldView.removeFromSuperview()
            }
            
            var y = self.frame.height - self.viewLabel.frame.height
            for view in self.eventViews {
                y -= view.frame.size.height + AUDateView.eventMargin
                view.frame.origin.y = y
                self.addSubview(view)
            }
        }
    }
    
    
    init(controller: ViewController, date: NSDate, origin: CGPoint, withRightBorder: Bool = true) {
        self.controller = controller
        self.date = date
        self.viewLabel = AUDateViewLabel(date: date, origin: CGPoint(x: 0, y: AUDateView.heightForEvents))
        self.withRightBorder = withRightBorder
        
        let frame = NSRect(origin: origin, size: AUDateView.size)
        super.init(frame: frame)
        
        self.addSubview(viewLabel)
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
        path.moveToPoint(NSPoint(x: AUDateView.size.width, y: 0))
        path.lineToPoint(NSPoint(x: AUDateView.size.width, y: self.height - self.viewLabel.frame.height))
        path.lineWidth = 2
        path.stroke()
    }
    
}

@objc protocol AUDateViewDelegate {
    optional func selectDateView(dateView: AUDateView)
    
    optional func requestNewEventForDateView(dateView: AUDateView)
}
