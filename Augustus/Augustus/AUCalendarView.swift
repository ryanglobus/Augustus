//
//  AUCalendarView.swift
//  Augustus
//
//  Created by Ryan Globus on 9/29/15.
//  Copyright © 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class AUCalendarView: NSView {
    
    fileprivate let eventViewCollection: AUEventViewCollection
    fileprivate var dateLabels: [AUDateLabel]
    fileprivate let scrollView: NSScrollView
    fileprivate let log = AULog.instance
    
    var auDelegate: AUCalendarViewDelegate? {
        didSet { self.didSetAuDelegate() }
    }
    
    var week: AUWeek {
        didSet { self.didSetWeek(oldValue: oldValue) }
    }
    
    // TODO below is wonky
    /// denormalized from week property; set week first
    var eventsForWeek: [Date: [AUEvent]] {
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
    
    func dateLabelForEventView(_ eventView: AUEventView) -> AUDateLabel? {
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
    
    fileprivate func didSetWeek(oldValue: AUWeek) {
        if oldValue != self.week {
            for i in 0..<self.dateLabels.count {
                self.dateLabels[i].date = self.week[i]
                self.dateLabels[i].needsDisplay = true
            }
        }
    }
    
    fileprivate func didSetEventsForWeek() {
        var events: [[AUEvent]] = []
        for date in self.week.dates() {
            if let dateEvents = self.eventsForWeek[date as Date] {
                events.append(dateEvents)
            } else {
                events.append([])
            }
        }
        self.eventViewCollection.events = events
    }
    
    fileprivate func didSetAuDelegate() {
        for dateLabel in self.dateLabels {
            dateLabel.auDelegate = self.auDelegate
        }
        self.eventViewCollection.auDelegate = self.auDelegate
    }
    
    fileprivate func addDateLabels() {
        var previousLabel_: AUDateLabel? = nil
        for date in self.week.dates() {
            let label = AUDateLabel(date: date)
            self.dateLabels.append(label)
            self.addSubview(label)
            
            // add constraints
            label.translatesAutoresizingMaskIntoConstraints = false
            let xConstraint: NSLayoutConstraint
            if let previousLabel = previousLabel_ {
                xConstraint = NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: previousLabel, attribute: .right, multiplier: 1, constant: 0)
            } else {
                xConstraint = NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
            }
            let constraints = [
                // x
                xConstraint,
                // y
                NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
                // width
                NSLayoutConstraint(item: label, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: CGFloat(1.0) / CGFloat(AUWeek.numDaysInWeek), constant: 0),
                // height uses intrinsic size
            ]
            self.addConstraints(constraints)
            
            previousLabel_ = label
        }
    }
    
    fileprivate func setupScrollView(firstLabel label: AUDateLabel) { // TODO kinda dumb, but forces date labels to be initialized first
        self.scrollView.documentView = self.eventViewCollection
        self.scrollView.hasVerticalScroller = true
        self.addSubview(self.scrollView)
        self.addScrollViewConstraints(firstLabel: label)
        self.addEventViewCollectionConstraints()
    }
    
    fileprivate func addScrollViewConstraints(firstLabel label: AUDateLabel) {
        let leftConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .top, relatedBy: .equal, toItem: label, attribute: .bottom, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: self.scrollView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([leftConstraint, topConstraint, bottomConstraint, widthConstraint])
    }
    
    fileprivate func addEventViewCollectionConstraints() {
        let leftConstraint = NSLayoutConstraint(item: self.eventViewCollection, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: self.eventViewCollection, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let scrollerWidth = self.scrollView.verticalScroller?.frame.width ?? CGFloat(0)
        let widthConstraint = NSLayoutConstraint(item: self.eventViewCollection, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: -1 * scrollerWidth)
        let heightConstraint = NSLayoutConstraint(item: self.eventViewCollection, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: self.scrollView, attribute: .height, multiplier: 1, constant: 0)
        eventViewCollection.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([leftConstraint, topConstraint, widthConstraint, heightConstraint])
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private class AUEventViewCollection : NSView { // TODO move to AUEventView.swift?
    fileprivate var eventViews: [AUEventView]
    fileprivate let log = AULog.instance
    
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
    
    fileprivate func didSetAuDelegate() {
        for eventView in self.eventViews {
            eventView.auDelegate = self.auDelegate
        }
    }
    
    fileprivate func didSetEvents() {
        guard self.eventViews.count == AUWeek.numDaysInWeek && self.events.count == AUWeek.numDaysInWeek else {
            self.log.error("There are only \(self.eventViews.count) event views and only \(self.events.count) event arrays, when there should be \(AUWeek.numDaysInWeek) of each")
            return
        }
        
        for i in 0..<(AUWeek.numDaysInWeek) {
            self.eventViews[i].events = events[i]
        }
    }
    
    fileprivate func addEventViews() {
        var constraints: [NSLayoutConstraint] = []
        var previousEventView_: AUEventView? = nil
        for i in 1...AUWeek.numDaysInWeek {
            let eventView = AUEventView(withRightBorder: i < AUWeek.numDaysInWeek)
            self.addSubview(eventView)
            eventView.translatesAutoresizingMaskIntoConstraints = false
            addConstraintsToEventView(eventView, withPreviousEventView_: previousEventView_)
            
            let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: eventView, attribute: .height, multiplier: 1, constant: 0)
            heightConstraint.priority = NSLayoutPriorityRequired
            constraints.append(heightConstraint)
            
            previousEventView_ = eventView
            self.eventViews.append(eventView)
        }
        self.addConstraints(constraints)
    }
    
    fileprivate func addConstraintsToEventView(_ eventView: AUEventView, withPreviousEventView_: AUEventView?) {
        let xConstraint: NSLayoutConstraint
        if let previousEventView = withPreviousEventView_ {
            xConstraint = NSLayoutConstraint(item: eventView, attribute: .left, relatedBy: .equal, toItem: previousEventView, attribute: .right, multiplier: 1, constant: 0)
        } else {
            xConstraint = NSLayoutConstraint(item: eventView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        }
        let yConstraint = NSLayoutConstraint(item: eventView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: eventView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: CGFloat(1.0) / CGFloat(AUWeek.numDaysInWeek), constant: 0)
        let minHeightConstraint = NSLayoutConstraint(item: eventView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint, yConstraint, widthConstraint, minHeightConstraint])
    }
}

@objc protocol AUEventViewCollectionDelegate: AUEventViewDelegate {}

@objc protocol AUCalendarViewDelegate: AUDateLabelDelegate, AUEventViewCollectionDelegate {}


