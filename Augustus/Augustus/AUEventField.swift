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
                self.drawsBackground = self.selected
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
    
    init(origin: CGPoint, width: CGFloat, event: AUEvent) {
        self.eventValue = event
        let font = NSFont.systemFontOfSize(18)
//        event.description.sizeWithWidth(200, andFont: font)
        
        // TODO make below method
        // TODO below doesn't work for "Woah it's the 12th"
        let storage = NSTextStorage(string: event.description)
        let container = NSTextContainer(containerSize: NSSize(width: width, height: CGFloat.max))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        storage.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, storage.length))
        container.lineFragmentPadding = 0.0
        layoutManager.glyphRangeForTextContainer(container)
        let height = layoutManager.usedRectForTextContainer(container).size.height + font.pointSize / 3 // add font.pointSize / 2 for letters like 'y' and 'g'
        
        let frame = NSRect(origin: origin, size: CGSize(width: width, height: height))
        super.init(frame: frame)
        self.stringValue = self.eventValue.description // TODO dup code
        self.font = font
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
