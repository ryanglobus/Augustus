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
    
    fileprivate let log = AULog.instance
//    var dateViews: [AUEventView] = []
    var monthYearLabel: NSTextField?
    var popoverViewController: PopoverViewController?
    var selectedEventField: AUEventField?
    var addEventButton: NSButton?
    fileprivate var progressIndicator: NSProgressIndicator?
    fileprivate var datePicker: NSDatePicker?
    fileprivate var scrollView: NSScrollView?
    fileprivate var calendarView: AUCalendarView?
    fileprivate var numLoadEventTasks = 0
    var week: AUWeek = AUWeek() {
        didSet {
            self.refresh(newWeek: true)
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let window = NSApplication.shared().windows[0] // TODO bold assumption
        window.delegate = self
        
        if (self.scrollView == nil) {
            self.scrollView = NSScrollView(frame: self.view.frame)
            self.scrollView?.hasVerticalScroller = true
            self.scrollView?.documentView = NSView(frame: self.scrollView!.frame)
        }
        
        self.calendarView = AUCalendarView(frame: self.view.frame, week: AUWeek())
        self.calendarView?.auDelegate = self
        self.view.addSubview(self.calendarView!)
        
        self.unselect()
        self.refresh(newWeek: true) // TODO needed?
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AUModel.notificationName), object: nil, queue: nil) { (notification: Notification) in
            self.log.debug("refresh!")
            DispatchQueue.main.async {
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
                    self.progressIndicator?.isHidden = true
                }
                if let datePicker = view as? NSDatePicker {
                    datePicker.dateValue = Date() // now
                    self.datePicker = datePicker
                }
            }
        }
        
        // setting titleVisibility to Hidden doesn't resize window/view properly
        // so must manually reduce window height
        let viewFrame = self.view.frame
        var windowFrame_ = self.view.window?.frame
        windowFrame_?.size.height -= 32 // the height of the title we're about to remove
        self.view.window?.titleVisibility = .hidden
        if let windowFrame = windowFrame_ {
            self.view.window?.setFrame(windowFrame, display: true, animate: true)
        }
        if let window = self.view.window {
            // must manually call windowWillResize, since setFrame will not
            _ = self.windowWillResize(window, to: viewFrame.size)
        }
        self.view.setFrameOrigin(viewFrame.origin)
        self.view.setFrameSize(viewFrame.size)
        self.popoverViewController = PopoverViewController.newInstance()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        if let calendarView = self.calendarView {
            let heightDiff = frameSize.height - sender.frame.height
            let newCalendarViewSize = NSSize(width: sender.frame.width, height: calendarView.frame.height + heightDiff)
            calendarView.setFrameSize(newCalendarViewSize)
        }
        return frameSize
    }
    

    
    // TODO unselect when add event
    func selectEventField(_ eventField: AUEventField) {
        self.selectedEventField?.selected = false
        eventField.selected = true
        self.selectedEventField = eventField
    }
    
    func selectEventView(_ eventView: AUEventView) {
        self.unselect()
        self.popoverViewController?.close(eventView)
//        self.popoverViewController?.date = dateView.date // TODO make this do something
    }
    
    func unselect() { // TODO better, call more often
        self.selectedEventField?.selected = false
        self.selectedEventField = nil
    }
    
    func requestEditEventField(_ eventField: AUEventField) { // TODO actually edit event
        self.selectEventField(eventField)

        let rect = NSRect(origin: CGPoint.zero, size: eventField.frame.size)
        self.popoverViewController?.popover?.show(relativeTo: rect, of: eventField, preferredEdge: NSRectEdge.maxX)
        self.popoverViewController?.setModeToEdit(eventField.eventValue)
    }
    
    // TODO don't show datePicker
    func requestNewEventForDateLabel(_ dateLabel: AUDateLabel) {
        // TODO unselect?
        let rect = NSRect(origin: CGPoint.zero, size: dateLabel.frame.size)
        self.popoverViewController?.popover?.show(relativeTo: rect, of: dateLabel, preferredEdge: .maxY)
        self.popoverViewController?.setModeToAdd()
        self.popoverViewController?.date = dateLabel.date
    }
    
    func requestNewEventForEventView(_ eventView: AUEventView) {
        if let dateLabel = self.calendarView?.dateLabelForEventView(eventView) {
            self.requestNewEventForDateLabel(dateLabel)
        }
    }
    
    @IBAction
    func previousWeek(_ sender: AnyObject?) {
        self.unselect()
        self.week = week.plusNumWeeks(-1)
    }
    
    @IBAction
    func previousMonth(_ sender: AnyObject?) {
        self.unselect()
        self.week = week.plusNumMonths(-1)
    }
    
    @IBAction
    func nextWeek(_ sender: AnyObject?) {
        self.unselect()
        self.week = week.plusNumWeeks(1)
    }
    
    @IBAction
    func nextMonth(_ sender: AnyObject?) {
        self.unselect()
        self.week = week.plusNumMonths(1)
    }
    
    @IBAction
    func todaysWeek(_ sender: AnyObject?) {
        self.unselect()
        self.week = AUWeek()
    }
    
    @IBAction
    func goToDate(_ sender: AnyObject?) {
        self.unselect()
        if let datePicker = self.datePicker {
            self.week = AUWeek(containingDate: datePicker.dateValue)
        }
    }
    
    @IBAction
    func requestNewEvent(_ sender: AnyObject?) {
        if let view = self.addEventButton {
            // must show first for NSDatePicker to be created for setDate:
            self.popoverViewController?.popover?.show(relativeTo: view.frame, of: view, preferredEdge: NSRectEdge.maxY)
            self.popoverViewController?.setModeToAdd()
            self.popoverViewController?.date = self.week.firstDate
        }
    }
    
    
    
    
    // MENU ACTIONS
    
    @IBAction
    func edit(_ sender: AnyObject?) {
        if let eventField = self.selectedEventField {
            self.requestEditEventField(eventField)
        }
    }
    
    func delete(_ sender: AnyObject?) {
        if let event = self.selectedEventField?.eventValue {
            AUModel.eventStore.removeEvent(event)
            self.unselect()
        }
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.title {
        case "New Event...":
            return true
        case "Edit Event...", "Delete":
            return self.selectedEventField != nil
        default:
            return super.validateMenuItem(menuItem)
        }
    }
    
    fileprivate func drawMonthYearLabel() {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        self.monthYearLabel?.stringValue = df.string(from: week.firstDate as Date)
    }
    
    fileprivate func refresh(newWeek: Bool = false) {
        self.drawMonthYearLabel()
        if newWeek {
            self.calendarView?.week = self.week
            self.calendarView?.eventsForWeek = [:]
        }
        let week = self.week
        self.numLoadEventTasks += 1
        self.progressIndicator?.startAnimation(self)
        self.progressIndicator?.isHidden = false
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let weekEvents = AUModel.eventStore.eventsForWeek(week)
            DispatchQueue.main.async {
                self.calendarView?.eventsForWeek = weekEvents
                self.numLoadEventTasks -= 1
                if self.numLoadEventTasks == 0 {
                    self.progressIndicator?.isHidden = true
                    self.progressIndicator?.stopAnimation(self)
                }
            }
        }
    }


}

