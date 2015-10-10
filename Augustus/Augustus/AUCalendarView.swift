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
    
    private var dateLabels: [AUDateViewLabel]
    private let log = AULog.instance
    
    init(frame frameRect: NSRect, week: AUWeek) {
        self.week = week
        self.dateLabels = []
        super.init(frame: frameRect)
        
        // set up date labels
        var previousLabel_: AUDateViewLabel? = nil
        for date in self.week.dates() {
            let label = AUDateViewLabel(date: date)
            self.dateLabels.append(label)
            self.addSubview(label)
            
            // add constraints
            label.translatesAutoresizingMaskIntoConstraints = false
            let xConstraint: NSLayoutConstraint
            if let previousLabel = previousLabel_ {
                xConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: previousLabel, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0)
            } else {
                xConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
            }
            let constraints = [
                // x
                xConstraint,
                // y
                NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0),
                // width
                NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Width, multiplier: CGFloat(1.0) / CGFloat(self.week.dates().count), constant: 0),
                // height uses intrinsic size
            ]
            self.addConstraints(constraints)
            
            previousLabel_ = label
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
