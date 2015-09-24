//
//  PopoverViewController.swift
//  Augustus
//
//  Created by Ryan Globus on 8/1/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class PopoverViewController: NSViewController, NSTextFieldDelegate {
    
    enum Mode {
        case AddMode, EditMode
    }
    
    var date: NSDate? {
        get {
            return self.datePicker?.dateValue
        } set {
            if let nval = newValue {
                self.datePicker?.dateValue = nval
            }
        }
    }
    
    private(set) var event: AUEvent?
    var mode: Mode {
        get {
            if event == nil {
                return .AddMode
            } else {
                return .EditMode
            }
        }
    }
    
    @IBOutlet weak var eventDescriptionField: NSTextField?
    @IBOutlet weak var datePicker: NSDatePicker?
    var popover: NSPopover? = nil // TODO hack
    @IBOutlet weak var addEventButton: NSButton? // TODO rename

    static func newInstance() -> PopoverViewController? { // TODO hack
        let pvc = PopoverViewController(nibName: "PopoverViewController", bundle: NSBundle(identifier: "Augustus"))
        pvc?.popover = NSPopover()
        pvc?.popover?.contentViewController = pvc
        return pvc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        self.view.window?.makeFirstResponder(self.eventDescriptionField)
        if let addEventButtonCell = self.addEventButton?.cell as? NSButtonCell {
            self.view.window?.defaultButtonCell = addEventButtonCell
        }
    }
    
    @IBAction func addEvent(sender: AnyObject) { // TODO rename
        if let description = eventDescriptionField?.stringValue {
            if !description.isEmpty { // TODO strip whitespace too
                if let date = datePicker?.dateValue {
                    switch self.mode {
                    case .AddMode:
                        AUModel.eventStore.addEventOnDate(date, description: description)
                    case .EditMode:
                        if let event = self.event {
                            AUModel.eventStore.editEvent(event, newDate: date, newDescription: description)
                        }
                    }
                }
            }
        }
        self.close(sender)
    }
    
    @IBAction func close(sender: AnyObject) {
        self.popover?.performClose(self)
    }
    
    func setModeToAdd() {
        self.event = nil
        self.eventDescriptionField?.stringValue = ""
        self.addEventButton?.title = "Add Event" // TODO dup String from IB
    }
    
    func setModeToEdit(event: AUEvent) {
        self.event = event
        self.date = event.date
        self.eventDescriptionField?.stringValue = event.description
        self.addEventButton?.title = "Edit Event"
    }
    
}
