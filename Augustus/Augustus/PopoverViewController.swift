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
        case addMode, editMode
    }
    
    var date: Date? {
        get {
            return self.datePicker?.dateValue
        } set {
            if let nval = newValue {
                self.datePicker?.dateValue = nval
            }
        }
    }
    
    var color: NSColor? {
        get {
            return self.colorPicker?.color
        } set {
            if let nval = newValue {
                self.colorPicker?.color = nval
            }
        }
    }
    
    fileprivate(set) var event: AUEvent?
    var mode: Mode {
        get {
            if event == nil {
                return .addMode
            } else {
                return .editMode
            }
        }
    }
    
    @IBOutlet weak var eventDescriptionField: NSTextField?
    @IBOutlet weak var datePicker: NSDatePicker?
    var popover: NSPopover? = nil // TODO hack
    @IBOutlet weak var addEventButton: NSButton? // TODO rename
    @IBOutlet weak var colorPicker: NSColorWell?

    static func newInstance() -> PopoverViewController? { // TODO hack
        let pvc = PopoverViewController(nibName: "PopoverViewController", bundle: Bundle(identifier: "Augustus"))
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
    
    @IBAction func addEvent(_ sender: AnyObject) { // TODO rename
        if let description = eventDescriptionField?.stringValue {
            if !description.isEmpty { // TODO strip whitespace too
                if let date = datePicker?.dateValue {
                    switch self.mode {
                    case .addMode:
                        var event = AUModel.eventStore.addEventOnDate(date, description: description)
                        if let color = self.color {
                            event?.color = color
                        }
                    case .editMode:
                        if var event = self.event {
                            AUModel.eventStore.editEvent(event, newDate: date, newDescription: description)
                            if let color = self.color {
                                event.color = color
                            }
                        }
                    }
                }
            }
        }
        self.close(sender)
    }
    
    @IBAction func close(_ sender: AnyObject) {
        self.popover?.performClose(self) // TODO close color palette as well
        NSColorPanel.shared().close()
    }
    
    func setModeToAdd() {
        self.event = nil
        self.eventDescriptionField?.stringValue = ""
        self.addEventButton?.title = "Add Event" // TODO dup String from IB
    }
    
    func setModeToEdit(_ event: AUEvent) {
        self.event = event
        self.date = event.date as Date
        self.eventDescriptionField?.stringValue = event.description
        self.color = event.color
        self.addEventButton?.title = "Edit Event"
    }
    
}
