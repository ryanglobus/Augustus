//
//  ViewController.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

func -(lhs: NSSize, rhs: NSSize) -> NSSize {
    return NSSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

func +(lhs: NSSize, rhs: NSSize) -> NSSize {
    return NSSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

class ViewController: NSViewController, NSWindowDelegate, AUCalendarViewDelegate {
    
    // TODO handle event modification failure
    
    private let log = AULog.instance
//    var dateViews: [AUEventView] = []
    var monthYearLabel: NSTextField?
    var popoverViewController: PopoverViewController?
    var selectedEventField: AUEventField?
    var addEventButton: NSButton?
    private var progressIndicator: NSProgressIndicator?
    private var scrollView: NSScrollView?
    private var calendarView: AUCalendarView?
    private var numLoadEventTasks = 0
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
//            self.view.addSubview(scrollView!)
        }
        
        self.calendarView = AUCalendarView(frame: self.view.frame, week: AUWeek())
        self.calendarView?.auDelegate = self
        self.view.addSubview(self.calendarView!)
        
//        self.addDateViews()
        self.unselect()
        self.refresh() // TODO needed?
        NSNotificationCenter.defaultCenter().addObserverForName(AUModel.notificationName, object: nil, queue: nil) { (notification: NSNotification) in
            self.log.debug("refresh!")
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
                if let progressIndicator = view as? NSProgressIndicator {
                    self.progressIndicator = progressIndicator
                    self.progressIndicator?.hidden = true
                }
            }
        }
        
        // setting titleVisibility to Hidden doesn't resize window/view properly
        // so must manually reduce window height
        let viewFrame = self.view.frame
        var windowFrame_ = self.view.window?.frame
        windowFrame_?.size.height -= 32 // the height of the title we're about to remove
        self.view.window?.titleVisibility = .Hidden
        if let windowFrame = windowFrame_ {
            self.view.window?.setFrame(windowFrame, display: true, animate: true)
        }
        self.view.setFrameOrigin(viewFrame.origin)
        self.view.setFrameSize(viewFrame.size)
        self.popoverViewController = PopoverViewController.newInstance()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func windowWillResize(sender: NSWindow, toSize frameSize: NSSize) -> NSSize {
        let sizeDiff = frameSize - sender.frame.size
        if let calendarView = self.calendarView {
            calendarView.setFrameSize(calendarView.frame.size + sizeDiff)
        }
        return frameSize
    }
    

    
    // TODO unselect when add event
    func selectEventField(eventField: AUEventField) {
        self.selectedEventField?.selected = false
        eventField.selected = true
        self.selectedEventField = eventField
    }
    
    func selectEventView(eventView: AUEventView) {
        self.unselect()
        self.popoverViewController?.close(eventView)
//        self.popoverViewController?.date = dateView.date // TODO make this do something
    }
    
    func unselect() { // TODO better, call more often
        self.selectedEventField?.selected = false
        self.selectedEventField = nil
    }
    
    func requestEditEventField(eventField: AUEventField) { // TODO actually edit event
        self.selectEventField(eventField)

        let rect = NSRect(origin: CGPoint.zero, size: eventField.frame.size)
        self.popoverViewController?.popover?.showRelativeToRect(rect, ofView: eventField, preferredEdge: NSRectEdge.MaxX)
        self.popoverViewController?.setModeToEdit(eventField.eventValue)
    }
    
    // TODO don't show datePicker
    func requestNewEventForDateLabel(dateLabel: AUDateLabel) {
        // TODO unselect?
        let rect = NSRect(origin: CGPoint.zero, size: dateLabel.frame.size)
        self.popoverViewController?.popover?.showRelativeToRect(rect, ofView: dateLabel, preferredEdge: .MaxY)
        self.popoverViewController?.setModeToAdd()
        self.popoverViewController?.date = dateLabel.date
    }
    
    func requestNewEventForEventView(eventView: AUEventView) {
        if let dateLabel = self.calendarView?.dateLabelForEventView(eventView) {
            self.requestNewEventForDateLabel(dateLabel)
        }
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
            self.requestEditEventField(eventField)
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
    
    private func drawMonthYearLabel() {
        let df = NSDateFormatter()
        df.dateFormat = "MMMM yyyy"
        self.monthYearLabel?.stringValue = df.stringFromDate(week.firstDate)
    }
    
    private func refresh(newWeek newWeek: Bool = false) {
        self.drawMonthYearLabel()
        self.calendarView?.week = self.week
        self.calendarView?.eventsForWeek = [:]
        let week = self.week
        self.numLoadEventTasks++
        self.progressIndicator?.startAnimation(self)
        self.progressIndicator?.hidden = false
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let weekEvents = AUModel.eventStore.eventsForWeek(week)
            dispatch_async(dispatch_get_main_queue()) {
                self.calendarView?.eventsForWeek = weekEvents
                self.numLoadEventTasks--
                if self.numLoadEventTasks == 0 {
                    self.progressIndicator?.hidden = true
                    self.progressIndicator?.stopAnimation(self)
                }
            }
        }
    }


}

