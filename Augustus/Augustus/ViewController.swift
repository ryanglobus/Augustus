//
//  ViewController.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSWindowDelegate, AUEventFieldDelegate, AUDateViewDelegate {
    
    // TODO handle event modification failure
    
    private let log = AULog.instance
    var dateViews: [AUDateView] = []
    var monthYearLabel: NSTextField?
    var popoverViewController: PopoverViewController?
    var selectedEventField: AUEventField?
    var addEventButton: NSButton?
    private var scrollView: NSScrollView?
    var week: AUWeek = AUWeek() {
        didSet {
            self.refresh(newWeek: true)
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let window = NSApplication.sharedApplication().windows[0] // TODO bold assumption
        window.delegate = self
        
        if (self.scrollView == nil) {
            self.scrollView = NSScrollView(frame: self.view.frame)
            self.scrollView?.hasVerticalScroller = true
            self.scrollView?.documentView = NSView(frame: self.scrollView!.frame)
            self.view.addSubview(scrollView!)
        }
        
        self.addDateViews()
        self.unselect()
        self.refresh() // TODO needed?
        NSNotificationCenter.defaultCenter().addObserverForName(AUModel.notificationName, object: nil, queue: nil) { (notification: NSNotification) in
            self.log.debug?("refresh!")
            dispatch_async(dispatch_get_main_queue()) {
                self.refresh()
            }
        }
    }
    
    override func viewWillAppear() {
        // TODO use IBOutlet
        // get toolbar outlets
        if let items = self.view.window?.toolbar?.items {
            for item in items {
                let view = item.view
                if let textField = view as? NSTextField {
                    if "toolbar-month-year-label" == textField.identifier {
                        self.monthYearLabel = textField
                        self.drawMonthYearLabel()
                    }
                }
                if let button = view as? NSButton {
                    if "add-event-button" == button.identifier {
                        self.addEventButton = button
                    }
                }
            }
        }
        self.view.window?.titleVisibility = .Hidden
        self.popoverViewController = PopoverViewController.newInstance()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    
    // TODO unselect when add event
    func select(eventField: AUEventField) {
        self.selectedEventField?.selected = false
        eventField.selected = true
        self.selectedEventField = eventField
    }
    
    func selectDateView(dateView: AUDateView) {
        self.unselect()
        self.popoverViewController?.close(dateView)
        self.popoverViewController?.date = dateView.date // TODO make this do something
    }
    
    func unselect() { // TODO better, call more often
        self.selectedEventField?.selected = false
        self.selectedEventField = nil
    }
    
    func requestEdit(eventField: AUEventField) { // TODO actually edit event
        self.select(eventField)

        let rect = NSRect(origin: CGPoint.zero, size: eventField.frame.size)
        self.popoverViewController?.popover?.showRelativeToRect(rect, ofView: eventField, preferredEdge: NSRectEdge.MaxX)
        self.popoverViewController?.setModeToEdit(eventField.eventValue)
    }
    
    // TODO don't show datePicker
    func requestNewEventForDateView(dateView: AUDateView) {
        // TODO unselect?
        let dateViewLabel = dateView.viewLabel
        let rect = NSRect(origin: CGPoint.zero, size: dateViewLabel.frame.size)
        self.popoverViewController?.popover?.showRelativeToRect(rect, ofView: dateViewLabel, preferredEdge: NSRectEdge.MaxY)
        self.popoverViewController?.setModeToAdd()
        self.popoverViewController?.date = dateView.date
    }
    
    @IBAction
    func previousWeek(sender: AnyObject?) {
        self.unselect()
        self.week = week.plusNumWeeks(-1)
    }
    
    @IBAction
    func nextWeek(sender: AnyObject?) {
        self.unselect()
        self.week = week.plusNumWeeks(1)
    }
    
    @IBAction
    func todaysWeek(sender: AnyObject?) {
        self.unselect()
        self.week = AUWeek()
    }
    
    @IBAction
    func requestNewEvent(sender: AnyObject?) {
        if let view = self.addEventButton {
            // must show first for NSDatePicker to be created for setDate:
            self.popoverViewController?.popover?.showRelativeToRect(view.frame, ofView: view, preferredEdge: NSRectEdge.MaxY)
            self.popoverViewController?.setModeToAdd()
            self.popoverViewController?.date = self.week.firstDate
        }
    }
    
    
    
    
    // MENU ACTIONS
    
    @IBAction
    func edit(sender: AnyObject?) {
        if let eventField = self.selectedEventField {
            self.requestEdit(eventField)
        }
    }
    
    func delete(sender: AnyObject?) {
        if let event = self.selectedEventField?.eventValue {
            AUModel.eventStore.removeEvent(event)
            self.unselect()
        }
    }
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.title {
        case "New Event...":
            return true
        case "Edit Event...", "Delete":
            return self.selectedEventField != nil
        default:
            return super.validateMenuItem(menuItem)
        }
    }
    
    
    
    
    
    
    
    private func addDateViews() { // dup code here?
//        let frameHeight = self.view.frame.height
        var i = 0
        let dates = self.week.dates()
        for date in dates {
            let x = Double(AUDateViewLabel.size.width) * Double(i)
            let origin = CGPoint(x: x, y: 0)
//            let events = AUModel.eventStore.eventsForDate(date)
            let withRightBorder = (i != dates.count - 1)
            let view = AUDateView(controller: self, date: date, origin: origin, withRightBorder: withRightBorder)
            view.auDelegate = self
            if let documentView = self.scrollView?.documentView as? NSView {
//                if (view.frame.height > documentView.frame.height) { // TODO no
//                    log.debug?("Setting doc view height to \(view.frame.height)")
//                    documentView.setFrameSize(NSSize(width: documentView.frame.width, height: view.frame.height))
//                }
                documentView.addSubview(view)
            }
//            view.events = events
            self.dateViews.append(view)
            i++
        }
    }
    
    private func drawMonthYearLabel() {
        let df = NSDateFormatter()
        df.dateFormat = "MMMM yyyy"
        self.monthYearLabel?.stringValue = df.stringFromDate(week.firstDate)
    }
    
    private func refresh(newWeek newWeek: Bool = false) {
        self.drawMonthYearLabel()
        for i in 0..<AUWeek.numDaysInWeek {
            let date = week[i]
            let view = dateViews[i]
            view.date = date
            view.events = AUModel.eventStore.eventsForDate(date)
        }
        if let documentView = self.scrollView?.documentView as? NSView {
            let desiredHeight = dateViews.reduce(AUDateView.size.height) {(minHeight, dateView) in
                return max(minHeight, dateView.desiredHeight)
            }
            let delta = desiredHeight - documentView.frame.height
            
            for dateView in dateViews {
                dateView.height = desiredHeight
            }
            documentView.setFrameSize(NSSize(width: documentView.frame.width, height: desiredHeight))
            
            if let contentView = self.scrollView?.contentView {
                let y: CGFloat
                if newWeek {
                    y = documentView.frame.height - contentView.documentVisibleRect.height
                } else {
                    y = max(contentView.documentVisibleRect.origin.y + delta, 0)
                }
                // TODO only go to top if new week
                let newScrollPoint = NSPoint(x: contentView.documentVisibleRect.origin.x, y: y)
                self.scrollView?.contentView.scrollToPoint(newScrollPoint)
                self.scrollView?.reflectScrolledClipView(contentView)
            }
        }
    }


}

