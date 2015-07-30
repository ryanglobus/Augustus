//
//  AUDateViewEvents.swift
//  Augustus
//
//  Created by Ryan Globus on 7/29/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class AUDateViewEvents: NSView {
    
    let events: [AUEvent]
    static let size = CGSize(width: AUDateView.width, height: 450)
    
    init(events: [AUEvent], origin: CGPoint) {
        let frame = NSRect(origin: origin, size: AUDateViewEvents.size)
        self.events = events
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
        println(self.events.count)
        
        NSGraphicsContext.currentContext()?.restoreGraphicsState()
    }
    
    // TODO fonts and placement are not robust
    private func drawBorders() {
        let path = NSBezierPath()
        // border to the right
        path.moveToPoint(NSPoint(x: AUDateViewEvents.size.width, y: 0))
        path.lineToPoint(NSPoint(x: AUDateViewEvents.size.width, y: AUDateViewEvents.size.height))
        path.lineWidth = 2
        path.stroke()
    }
    
}
