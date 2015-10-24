//
//  AUCalendarView.swift
//  Augustus
//
//  Created by Ryan Globus on 9/29/15.
//  Copyright © 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class AUCalendarView: NSView {
    
    var week: AUWeek {
        didSet {
            if oldValue != self.week {
                for i in 0..<self.dateLabels.count {
                    self.dateLabels[i].date = self.week[i]
                    self.dateLabels[i].needsDisplay = true
                }
            }
        }
    }
    
    private var dateLabels: [AUDateLabel]
    private var scrollView: NSScrollView
    private let log = AULog.instance
    
    init(frame frameRect: NSRect, week: AUWeek) {
        self.week = week
        self.dateLabels = []
        self.scrollView = NSScrollView()
        super.init(frame: frameRect)
        
        self.addDateLabels()
        self.setupScrollView(firstLabel: self.dateLabels[0])
    }
    
    private func addDateLabels() {
        var previousLabel_: AUDateLabel? = nil
        for date in self.week.dates() {
            let label = AUDateLabel(date: date)
            self.dateLabels.append(label)
            self.addSubview(label)
            
            // add constraints
            label.translatesAutoresizingMaskIntoConstraints = false
            let xConstraint: NSLayoutConstraint
            if let previousLabel = previousLabel_ {
                xConstraint = NSLayoutConstraint(item: label, attribute: .Left, relatedBy: .Equal, toItem: previousLabel, attribute: .Right, multiplier: 1, constant: 0)
            } else {
                xConstraint = NSLayoutConstraint(item: label, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0)
            }
            let constraints = [
                // x
                xConstraint,
                // y
                NSLayoutConstraint(item: label, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0),
                // width
                NSLayoutConstraint(item: label, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: CGFloat(1.0) / CGFloat(self.week.dates().count), constant: 0),
                // height uses intrinsic size
            ]
            self.addConstraints(constraints)
            
            previousLabel_ = label
        }
    }
    
    private func setupScrollView(firstLabel label: AUDateLabel) { // TODO kinda dumb, but forces date labels to be initialized first
        let eventViewCollection = AUEventViewCollection()
        self.scrollView.documentView = eventViewCollection
        self.scrollView.hasVerticalScroller = true
        self.addSubview(self.scrollView)
        
        
        let leftConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .Top, relatedBy: .Equal, toItem: label, attribute: .Bottom, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: 0)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([leftConstraint, topConstraint, bottomConstraint, widthConstraint])
        
        // TODO below should be separate method
        let xleftConstraint = NSLayoutConstraint(item: eventViewCollection, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0)
        let xtopConstraint = NSLayoutConstraint(item: eventViewCollection, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
        // TODO below is too wide
        let xwidthConstraint = NSLayoutConstraint(item: eventViewCollection, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: 0)
        eventViewCollection.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([xleftConstraint, xtopConstraint, xwidthConstraint])
        
//        let leftConstraint = NSLayoutConstraint(item: self.scrollView.contentView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
//        let topConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.scrollView.contentView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0) // TODO isn't this swapped?
//        let widthConstraint = NSLayoutConstraint(item: self.scrollView.contentView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
//        let bottomConstraint = NSLayoutConstraint(item: self.scrollView.contentView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
//        
//        self.addConstraints([leftConstraint, topConstraint, widthConstraint, bottomConstraint])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private class AUEventViewCollection : NSView { // TODO move to AUEventView.swift?
    private var eventViews: [AUEventView]
    
    init() {
        self.eventViews = []
        super.init(frame: NSRect())
        self.addEventViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addEventViews() {
        var constraints: [NSLayoutConstraint] = []
        for i in 1...AUWeek.numDaysInWeek {
            let eventView = AUEventView(origin: CGPoint.zero, withRightBorder: i < AUWeek.numDaysInWeek)
            self.addSubview(eventView)
            
            let heightConstraint = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: eventView, attribute: .Height, multiplier: 1, constant: 0)
            heightConstraint.priority = NSLayoutPriorityRequired
            constraints.append(heightConstraint)
        }
        let asShortAsPossibleConstraint = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .Height, multiplier: 0, constant: 0)
        asShortAsPossibleConstraint.priority = NSLayoutPriorityFittingSizeCompression // TODO ?
        constraints.append(asShortAsPossibleConstraint)
        self.addConstraints(constraints)
    }
}
