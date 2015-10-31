//
//  AUEventField.swift
//  Augustus
//
//  Created by Ryan Globus on 8/2/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class AUEventField: NSTextField {
    
    private var heightConstraint: NSLayoutConstraint?
    var eventValue: AUEvent {
        didSet {
            self.stringValue = self.eventValue.description
            self.invalidateIntrinsicContentSize()
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
    
    init(event: AUEvent) {
        self.eventValue = event
        super.init(frame: NSRect())
        
        self.stringValue = self.eventValue.description // TODO dup code
        self.font = NSFont.systemFontOfSize(18)
        self.editable = false
        self.bezeled = false
        self.drawsBackground = false
        self.selectable = false
        self.textColor = event.color
        self.cell?.wraps = true
        self.cell?.lineBreakMode = .ByWordWrapping
        self.postsFrameChangedNotifications = true
        NSNotificationCenter.defaultCenter().addObserverForName(NSViewFrameDidChangeNotification, object: self, queue: NSOperationQueue.mainQueue()) { (notification: NSNotification) in
            self.invalidateIntrinsicContentSize()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            let width = self.frame.width
            let height = self.desiredHeight()
            return CGSize(width: width, height: height)
        }
    }
    
    private func desiredHeight() -> CGFloat {
        // TODO below doesn't work for "Brunch with Rupii" (too tall)
        let font: NSFont
        if let selfFont = self.font {
            font = selfFont
        } else {
            font = NSFont.systemFontOfSize(18) // TODO dup code
        }
        
        let storage = NSTextStorage(string: self.stringValue)
        let container = NSTextContainer(containerSize: NSSize(width: self.frame.width, height: CGFloat.max))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        storage.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, storage.length))
        container.lineFragmentPadding = 3.0 // 3.0 to prevent text at same width from being cut off
        layoutManager.glyphRangeForTextContainer(container)
        let height = layoutManager.usedRectForTextContainer(container).size.height + font.pointSize / 3 // add font.pointSize / 3 for letters like 'y' and 'g'

        return height
    }

    override func mouseDown(theEvent: NSEvent) { // or mouse up?
        if theEvent.clickCount == 2 {
            self.auDelegate?.requestEditEventField?(self)
        } else {
            self.auDelegate?.selectEventField?(self)
        }
    }
    
}

@objc protocol AUEventFieldDelegate : NSTextFieldDelegate {
    optional func selectEventField(eventField: AUEventField)
    
    optional func requestEditEventField(eventField: AUEventField)
}
