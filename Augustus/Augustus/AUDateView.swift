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
    var yOfLastEvent = AUDateView.size.height - AUDateViewLabel.size.height

    
    let viewLabel: AUDateViewLabel
    
    init(date: NSDate, origin: CGPoint) {
        self.viewLabel = AUDateViewLabel(date: date, origin: CGPoint(x: 0, y: 450))
        
        let frame = NSRect(origin: origin, size: AUDateView.size)
        super.init(frame: frame)
        
        self.addSubview(viewLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        self.drawBorders()
//        self.viewEvents.drawRect(dirtyRect) // TODO this is definitely wrong
    }
    
    // TODO remove
    // TODO edit
    // TODO scroll
    func addEvents(events: [AUEvent]) {
        for event in events {
//            self.events.append(event)
            // TODO fix height constant
            let eventFrame = NSRect(x: 0, y: self.yOfLastEvent, width: AUDateView.size.width, height: 50)
            let eventField = NSTextField(frame: eventFrame)
            eventField.font = NSFont.systemFontOfSize(18)
            //            eventField.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0)
            eventField.stringValue = event.description
            eventField.editable = false
            eventField.bezeled = false
            eventField.drawsBackground = false
            eventField.selectable = true // TODO not working
            
            eventField.frame.origin.y -= eventField.frame.size.height
            self.yOfLastEvent = eventField.frame.origin.y
            self.addSubview(eventField)
        }
//        self.needsDisplay = true // TODO ???
    }
    
    private func drawBorders() {
        let path = NSBezierPath()
        // border to the right
        path.moveToPoint(NSPoint(x: AUDateView.size.width, y: 0))
        path.lineToPoint(NSPoint(x: AUDateView.size.width, y: 450))
        path.lineWidth = 2
        path.stroke()
    }
    
}
