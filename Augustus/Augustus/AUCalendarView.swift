//
//  AUCalendarView.swift
//  Augustus
//
//  Created by Ryan Globus on 9/29/15.
//  Copyright © 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class AUCalendarView: NSView {
    
    private let eventViewCollection: AUEventViewCollection
    private var dateLabels: [AUDateLabel]
    private let scrollView: NSScrollView
    private let log = AULog.instance
    
    var auDelegate: AUCalendarViewDelegate? {
        didSet { self.didSetAuDelegate() }
    }
    
    var week: AUWeek {
        didSet { self.didSetWeek(oldValue: oldValue) }
    }
    
    // TODO below is wonky
    /// denormalized from week property; set week first
    var eventsForWeek: [NSDate: [AUEvent]] {
        didSet { self.didSetEventsForWeek() }
    }
    
    init(frame frameRect: NSRect, week: AUWeek) {
        self.eventViewCollection = AUEventViewCollection()
        self.week = week
        self.dateLabels = []
        self.scrollView = NSScrollView()
        self.eventsForWeek = [:]
        super.init(frame: frameRect)
        
        self.addDateLabels()
        self.setupScrollView(firstLabel: self.dateLabels[0])
    }
    
    func dateLabelForEventView(eventView: AUEventView) -> AUDateLabel? {
        let eventViews = self.eventViewCollection.eventViews
        guard eventViews.count == AUWeek.numDaysInWeek && self.dateLabels.count == AUWeek.numDaysInWeek else {
            self.log.error("There are only \(eventViews.count) event views and only \(self.dateLabels.count) date labels, when there should be \(AUWeek.numDaysInWeek) of each")
            return nil
        }
        
        
        for i in 0..<(AUWeek.numDaysInWeek) {
            let currEventView = eventViews[i]
            if currEventView == eventView {
                return self.dateLabels[i]
            }
        }
        
        return nil
    }
    
    private func didSetWeek(oldValue oldValue: AUWeek) {
        if oldValue != self.week {
            for i in 0..<self.dateLabels.count {
                self.dateLabels[i].date = self.week[i]
                self.dateLabels[i].needsDisplay = true
            }
        }
    }
    
    private func didSetEventsForWeek() {
        var events: [[AUEvent]] = []
        for date in self.week.dates() {
            if let dateEvents = self.eventsForWeek[date] {
                events.append(dateEvents)
            } else {
                events.append([])
            }
        }
        self.eventViewCollection.events = events
    }
    
    private func didSetAuDelegate() {
        for dateLabel in self.dateLabels {
            dateLabel.auDelegate = self.auDelegate
        }
        self.eventViewCollection.auDelegate = self.auDelegate
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
                NSLayoutConstraint(item: label, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: CGFloat(1.0) / CGFloat(AUWeek.numDaysInWeek), constant: 0),
                // height uses intrinsic size
            ]
            self.addConstraints(constraints)
            
            previousLabel_ = label
        }
    }
    
    private func setupScrollView(firstLabel label: AUDateLabel) { // TODO kinda dumb, but forces date labels to be initialized first
        self.scrollView.documentView = self.eventViewCollection
        self.scrollView.hasVerticalScroller = true
        self.addSubview(self.scrollView)
        self.addScrollViewConstraints(firstLabel: label)
        self.addEventViewCollectionConstraints()
    }
    
    private func addScrollViewConstraints(firstLabel label: AUDateLabel) {
        let leftConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .Top, relatedBy: .Equal, toItem: label, attribute: .Bottom, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: 0)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([leftConstraint, topConstraint, bottomConstraint, widthConstraint])
    }
    
    private func addEventViewCollectionConstraints() {
        let leftConstraint = NSLayoutConstraint(item: self.eventViewCollection, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: self.eventViewCollection, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
        // TODO below is too wide
        let widthConstraint = NSLayoutConstraint(item: self.eventViewCollection, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: self.eventViewCollection, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: self.scrollView, attribute: .Height, multiplier: 1, constant: 0)
        eventViewCollection.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([leftConstraint, topConstraint, widthConstraint, heightConstraint])
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private class AUEventViewCollection : NSView { // TODO move to AUEventView.swift?
    private var eventViews: [AUEventView]
    private let log = AULog.instance
    
    var auDelegate: AUEventViewCollectionDelegate? {
        didSet { self.didSetAuDelegate() }
    }
    
    var events: [[AUEvent]] {
        didSet { self.didSetEvents() }
    }
    
    init() {
        self.eventViews = []
        self.events = []
        super.init(frame: NSRect())
        self.addEventViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func didSetAuDelegate() {
        for eventView in self.eventViews {
            eventView.auDelegate = self.auDelegate
        }
    }
    
    private func didSetEvents() {
        guard self.eventViews.count == AUWeek.numDaysInWeek && self.events.count == AUWeek.numDaysInWeek else {
            self.log.error("There are only \(self.eventViews.count) event views and only \(self.events.count) event arrays, when there should be \(AUWeek.numDaysInWeek) of each")
            return
        }
        
        for i in 0..<(AUWeek.numDaysInWeek) {
            self.eventViews[i].events = events[i]
        }
    }
    
    private func addEventViews() {
        var constraints: [NSLayoutConstraint] = []
        var previousEventView_: AUEventView? = nil
        for i in 1...AUWeek.numDaysInWeek {
            let eventView = AUEventView(withRightBorder: i < AUWeek.numDaysInWeek)
            self.addSubview(eventView)
            eventView.translatesAutoresizingMaskIntoConstraints = false
            addConstraintsToEventView(eventView, withPreviousEventView_: previousEventView_)
            
            let heightConstraint = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: eventView, attribute: .Height, multiplier: 1, constant: 0)
            heightConstraint.priority = NSLayoutPriorityRequired
            constraints.append(heightConstraint)
            
            previousEventView_ = eventView
            self.eventViews.append(eventView)
        }
        self.addConstraints(constraints)
    }
    
    private func addConstraintsToEventView(eventView: AUEventView, withPreviousEventView_: AUEventView?) {
        let xConstraint: NSLayoutConstraint
        if let previousEventView = withPreviousEventView_ {
            xConstraint = NSLayoutConstraint(item: eventView, attribute: .Left, relatedBy: .Equal, toItem: previousEventView, attribute: .Right, multiplier: 1, constant: 0)
        } else {
            xConstraint = NSLayoutConstraint(item: eventView, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0)
        }
        let yConstraint = NSLayoutConstraint(item: eventView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: eventView, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: CGFloat(1.0) / CGFloat(AUWeek.numDaysInWeek), constant: 0)
        let minHeightConstraint = NSLayoutConstraint(item: eventView, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: self, attribute: .Height, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint, yConstraint, widthConstraint, minHeightConstraint])
    }
}

@objc protocol AUEventViewCollectionDelegate: AUEventViewDelegate {}

@objc protocol AUCalendarViewDelegate: AUDateLabelDelegate, AUEventViewCollectionDelegate {}


