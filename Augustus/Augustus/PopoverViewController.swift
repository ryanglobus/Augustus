//
//  PopoverViewController.swift
//  Augustus
//
//  Created by Ryan Globus on 8/1/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class PopoverViewController: NSViewController, NSTextFieldDelegate {

    
    var eventDescription: String? {
        get {
            return self.eventDescriptionField?.stringValue
        } set {
            if let nval = newValue {
                self.eventDescriptionField?.stringValue = nval
            }
        }
    }
    @IBOutlet weak var eventDescriptionField: NSTextField?
    @IBOutlet weak var datePicker: NSDatePicker?
    var popover: NSPopover? = nil // TODO hack
    @IBOutlet weak var addEventButton: NSButton?

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
        if let addEventButtonCell = self.addEventButton?.cell() as? NSButtonCell {
            self.view.window?.setDefaultButtonCell(addEventButtonCell)
        }
    }
    
    @IBAction func addEvent(sender: AnyObject) {
        if let description = eventDescriptionField?.stringValue {
            if !description.isEmpty { // TODO strip whitespace too
                if let date = datePicker?.dateValue {
                    AUModel.eventStore.addEventOnDate(date, description: description)
                    NSNotificationCenter.defaultCenter().postNotificationName(AUModel.notificationName, object: self)
                }
            }
        }
        self.close(sender)
        // TODO close popover on click too
    }
    
    @IBAction func close(sender: AnyObject) {
        self.popover?.performClose(self)
    }
    
    
    func setDate(date: NSDate) { // TODO make computed property
        datePicker?.dateValue = date
    }
}
