//
//  AppDelegate.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let log = AULog.instance


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        // TODO make below queue proper UI queue/execute in UI queue
        // TODO test below
        // TODO is below even needed?
        self.alertIfEventStorePermissionDenied()
        NSNotificationCenter.defaultCenter().addObserverForName(AUModel.notificationName, object: nil, queue: nil, usingBlock: { (notification: NSNotification) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                self.alertIfEventStorePermissionDenied()
            }
            
        })
        log.info?("did finish launching")
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        log.info?("will terminate")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    private func alertIfEventStorePermissionDenied() {
        if AUModel.eventStore.permission == .Denied {
            let alert = NSAlert()
            alert.addButtonWithTitle("Go to System Preferences...")
            alert.addButtonWithTitle("Quit")
            alert.messageText = "Please grant Augustus access to your calendars."
            alert.informativeText = "You must grant Augustus access to your calendars in order to see or create events. To do so, go to System Preferences. Select Calendars in the left pane. Then, in the center pane, click the checkbox next to Augustus. Then restart Augustus."
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            let response = alert.runModal()
            if response == NSAlertFirstButtonReturn {
                let scriptSource = "tell application \"System Preferences\"\n" +
                    "set securityPane to pane id \"com.apple.preference.security\"\n" +
                    "tell securityPane to reveal anchor \"Privacy\"\n" +
                    "set the current pane to securityPane\n" +
                    "activate\n" +
                    "end tell"
                let script = NSAppleScript(source: scriptSource)
                let error = AutoreleasingUnsafeMutablePointer<NSDictionary?>()
                self.log.info?("About to go to System Preferences")
                if script?.executeAndReturnError(error) == nil {
                    self.log.error?(error.debugDescription)
                }
                // TODO now what?
            } else {
                NSApplication.sharedApplication().terminate(self)
            }
        }
    }


}

