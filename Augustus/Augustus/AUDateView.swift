//
//  AUDateView.swift
//  Augustus
//
//  Created by Ryan Globus on 7/29/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class AUDateView: NSView {
    static let width = CGFloat(150)
    // TODO 450 const in multiple places
    static let size = CGSize(width: AUDateView.width, height: AUDateViewLabel.size.height + 450)
    
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
            self.eventViews = events.map({ (event) -> NSView in
                // TODO fix height constraint
                let frame = NSRect(x: 0, y: 0, width: AUDateView.size.width, height: 50)
                let eventField = AUEventField(frame: frame, event: event)
                eventField.auDelegate = self.controller
                return eventField
            })
        }
    }
    
    private var eventViews: [NSView] = [] {
        didSet(oldEventViews) {
            for oldView in oldEventViews {
                oldView.removeFromSuperview()
            }
            var y = AUDateView.size.height - AUDateViewLabel.size.height
            for view in self.eventViews {
                y -= view.frame.size.height + 5 // 5 for margin
                view.frame.origin.y = y
                self.addSubview(view)
            }
        }
    }
    
    
    init(controller: ViewController, date: NSDate, origin: CGPoint, withRightBorder: Bool = true) {
        self.controller = controller
        self.date = date
        self.viewLabel = AUDateViewLabel(date: date, origin: CGPoint(x: 0, y: 450))
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
            self.auDelegate?.requestNewEvent?(self)
        }
    }
    
    // TODO scroll

    
    private func drawBorders() {
        let path = NSBezierPath()
        // border to the right
        path.moveToPoint(NSPoint(x: AUDateView.size.width, y: 0))
        path.lineToPoint(NSPoint(x: AUDateView.size.width, y: 450))
        path.lineWidth = 2
        path.stroke()
    }
    
}

@objc protocol AUDateViewDelegate {
    optional func requestNewEvent(dateView: AUDateView)
}
