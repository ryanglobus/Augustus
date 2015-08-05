//
//  AUEventField.swift
//  Augustus
//
//  Created by Ryan Globus on 8/2/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class AUEventField: NSTextField {
    
    var eventValue: AUEvent {
        didSet {
            self.stringValue = self.eventValue.description
        }
    }
    var selected = false {
        didSet {
            if (self.selected != oldValue) {
                let textColor = self.textColor
                self.textColor = self.backgroundColor
                self.backgroundColor = textColor
                self.drawsBackground = true
                self.needsDisplay = true // TODO needed?
            }
        }
    }
    var auDelegate: AUEventFieldDelegate? {
        get {
            return self.delegate as? AUEventFieldDelegate
        } set {
            self.delegate = newValue
        }
    }
    
    init(frame frameRect: NSRect, event: AUEvent) {
        self.eventValue = event
        super.init(frame: frameRect)
        self.stringValue = self.eventValue.description // TODO dup code
        self.font = NSFont.systemFontOfSize(18)
        self.editable = false
        self.bezeled = false
        self.drawsBackground = false
        self.selectable = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(theEvent: NSEvent) { // or mouse up?
        if theEvent.clickCount == 2 {
            self.auDelegate?.requestEdit?(self)
        } else {
            self.auDelegate?.select?(self)
        }
    }
    
}

@objc protocol AUEventFieldDelegate : NSTextFieldDelegate {
    optional func select(eventField: AUEventField)
    
    optional func requestEdit(eventField: AUEventField)
}
