//
//  ViewController.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSWindowDelegate, AUEventFieldDelegate, AUDateViewDelegate {
    
    var dateViews: [AUDateView] = []
    var monthYearLabel: NSTextField?
    var popoverViewController: PopoverViewController?
    var selectedEventField: AUEventField?
//    var addEventButton: NSButton?
    var week: AUWeek = AUWeek() {
        didSet {
            self.refresh()
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var window = NSApplication.sharedApplication().windows[0] as? NSWindow
        window?.delegate = self
        
        AUModel.eventStore.addEventOnDate(NSDate(), description: "Today is a great day!")
        AUModel.eventStore.addEventOnDate(NSDate(), description: "Get ready for tomorrow")
        self.addDateViews()
        self.unselect()
        // TODO make below queue proper UI queue
        NSNotificationCenter.defaultCenter().addObserverForName(AUModel.notificationName, object: nil, queue: nil, usingBlock: { (notification: NSNotification!) -> Void in
                self.refresh()
            })
    }
    
    override func viewWillAppear() {
        // TODO use IBOutlet
        // get toolbar outlets
        if let items = self.view.window?.toolbar?.items {
            for item in items {
                let view = (item as? NSToolbarItem)?.view
                if let textField = view as? NSTextField {
                    if "toolbar-month-year-label" == textField.identifier {
                        self.monthYearLabel = textField
                        self.drawMonthYearLabel()
                    }
                }
//                if let button = view as? NSButton {
//                    if "add-event-button" == button.identifier {
//                        self.addEventButton = button
//                    }
//                }
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
    
    func unselect() { // TODO better, call more often
        self.selectedEventField?.selected = false
        self.selectedEventField = nil
    }
    
    func requestEdit(eventField: AUEventField) { // TODO actually edit event
        self.select(eventField)

        let rect = NSRect(origin: CGPoint.zeroPoint, size: eventField.frame.size)
        self.popoverViewController?.popover?.showRelativeToRect(rect, ofView: eventField, preferredEdge: NSMaxXEdge)
        self.popoverViewController?.setModeToEdit(eventField.eventValue)
    }
    
    func requestNewEvent(dateView: AUDateView) {
        // TODO unselect?
        let dateViewLabel = dateView.viewLabel
        let rect = NSRect(origin: CGPoint.zeroPoint, size: dateViewLabel.frame.size)
        self.popoverViewController?.popover?.showRelativeToRect(rect, ofView: dateViewLabel, preferredEdge: NSMaxYEdge)
        self.popoverViewController?.setModeToAdd()
        self.popoverViewController?.date = dateView.date
    }
    
    @IBAction
    func previousWeek(sender: AnyObject?) {
        self.week = week.plusNumWeeks(-1)
    }
    
    @IBAction
    func nextWeek(sender: AnyObject?) {
        self.week = week.plusNumWeeks(1)
    }
    
    @IBAction
    func todaysWeek(sender: AnyObject?) {
        self.week = AUWeek()
    }
    
    @IBAction
    func addEventButton(sender: AnyObject?) {
        if let view = sender as? NSView {
            // must show first for NSDatePicker to be created for setDate:
            self.popoverViewController?.popover?.showRelativeToRect(view.frame, ofView: view, preferredEdge: NSMaxYEdge)
            self.popoverViewController?.setModeToAdd()
            self.popoverViewController?.date = self.week.firstDate
        }
    }
    
    
    
    
    // MENU ACTIONS
    
    func delete(sender: AnyObject?) {
        if let event = self.selectedEventField?.eventValue {
            AUModel.eventStore.removeEvent(event)
            // TODO should notifications be in model itself?
            NSNotificationCenter.defaultCenter().postNotificationName(AUModel.notificationName, object: self)
            self.unselect()
        }
    }
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        if menuItem.title == "Delete" {
            return self.selectedEventField != nil
        }
        
        return super.validateMenuItem(menuItem)
    }
    
    
    
    
    
    
    
    private func addDateViews() { // dup code here?
        let frameHeight = self.view.frame.height
        var i = 0
        let dates = self.week.dates()
        for date in dates {
            let x = Double(AUDateViewLabel.size.width) * Double(i)
            let origin = CGPoint(x: x, y: 0)
            let events = AUModel.eventStore.eventsForDate(date)
            let withRightBorder = (i != dates.count - 1)
            let view = AUDateView(controller: self, date: date, origin: origin, withRightBorder: withRightBorder)
            view.auDelegate = self
            self.view.addSubview(view)
            view.events = events
            self.dateViews.append(view)
            i++
        }
    }
    
    private func drawMonthYearLabel() {
        let df = NSDateFormatter()
        df.dateFormat = "MMMM yyyy"
        self.monthYearLabel?.stringValue = df.stringFromDate(week.firstDate)
    }
    
    private func refresh() {
        self.drawMonthYearLabel()
        for i in 0..<AUWeek.numDaysInWeek {
            let date = week[i]
            let view = dateViews[i]
            view.date = date
            view.events = AUModel.eventStore.eventsForDate(date)
        }
    }


}

