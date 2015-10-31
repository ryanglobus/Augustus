//
//  WindowController.swift
//  Augustus
//
//  Created by Ryan Globus on 10/31/15.
//  Copyright © 2015 Ryan Globus. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        self.shouldCascadeWindows = false
        self.window?.setFrameAutosaveName("AugustusMainWindow")
        
        super.windowDidLoad()
    }

}
