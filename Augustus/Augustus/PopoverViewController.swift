//
//  PopoverViewController.swift
//  Augustus
//
//  Created by Ryan Globus on 8/1/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class PopoverViewController: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var eventDescriptionField: NSTextField?
    @IBOutlet weak var datePicker: NSDatePicker?
    var popover: NSPopover? = nil // TODO hack

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
        self.popover?.performClose(self)
        // TODO close popover on click too
    }
    
    func setDate(date: NSDate) {
        datePicker?.dateValue = date
    }
}
