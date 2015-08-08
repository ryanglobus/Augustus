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
        log.info?("did finish launching")
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        log.info?("will terminate")
    }


}

