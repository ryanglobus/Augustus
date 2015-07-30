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
    static let size = CGSize(width: AUDateView.width, height: AUDateViewLabel.size.height + AUDateViewEvents.size.height)
    
    let viewLabel: AUDateViewLabel
    let viewEvents: AUDateViewEvents
    
    init(date: NSDate, events: [AUEvent], origin: CGPoint) {
        self.viewLabel = AUDateViewLabel(date: date, origin: CGPoint(x: 0, y: AUDateViewEvents.size.height))
        self.viewEvents = AUDateViewEvents(events: events, origin: origin)
        
        let frame = NSRect(origin: origin, size: AUDateView.size)
        super.init(frame: frame)
        
        self.addSubview(viewLabel)
        self.addSubview(viewEvents)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        self.viewEvents.drawRect(dirtyRect) // TODO this is definitely wrong
    }
    
}
