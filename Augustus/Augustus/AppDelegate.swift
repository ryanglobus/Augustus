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


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        // TODO make below queue proper UI queue/execute in UI queue
        // TODO test below
        // TODO is below even needed?
        self.alertIfEventStorePermissionDenied()
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AUModel.notificationName), object: nil, queue: nil, using: { (notification: Notification) -> Void in
            DispatchQueue.main.async {
                self.alertIfEventStorePermissionDenied()
            }
            
        })
        log.info("did finish launching")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        log.info("will terminate")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    fileprivate func alertIfEventStorePermissionDenied() {
        if AUModel.eventStore.permission == .denied {
            let alert = NSAlert()
            alert.addButton(withTitle: "Go to System Preferences...")
            alert.addButton(withTitle: "Quit")
            alert.messageText = "Please grant Augustus access to your calendars."
            alert.informativeText = "You must grant Augustus access to your calendars in order to see or create events. To do so, go to System Preferences. Select Calendars in the left pane. Then, in the center pane, click the checkbox next to Augustus. Then restart Augustus."
            alert.alertStyle = NSAlertStyle.warning
            let response = alert.runModal()
            if response == NSAlertFirstButtonReturn {
                let scriptSource = "tell application \"System Preferences\"\n" +
                    "set securityPane to pane id \"com.apple.preference.security\"\n" +
                    "tell securityPane to reveal anchor \"Privacy\"\n" +
                    "set the current pane to securityPane\n" +
                    "activate\n" +
                    "end tell"
                let script = NSAppleScript(source: scriptSource)
                let error: AutoreleasingUnsafeMutablePointer<NSDictionary?>? = nil
                self.log.info("About to go to System Preferences")
                if script?.executeAndReturnError(error) == nil {
                    self.log.error(error.debugDescription)
                }
                // TODO now what?
            } else {
                NSApplication.shared().terminate(self)
            }
        }
    }


}

