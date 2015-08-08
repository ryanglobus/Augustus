//
//  AUEventStoreInEK.swift
//  Augustus
//
//  Created by Ryan Globus on 8/7/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Foundation
import EventKit

class AUEventStoreInEK : AUEventStore {
    
    private let log = AULog.instance
    private let ekStore: EKEventStore
    private(set) var permission: AUEventStorePermission // TODO listen for changes
    private var ekCalendar: EKCalendar?
    
    init() {
        self.ekStore = EKEventStore()
        self.permission = .Pending
        self.ekStore.requestAccessToEntityType(EKEntityTypeEvent, completion: {(success: Bool, error: NSError!) in
            // TODO refactor
            // TODO test all scenarios (a lot!)
            if success {
                self.permission = .Granted
                self.log.info?("request to access EKEntityTypeEvents granted")
                
                // look for calendar
                // TODO remember calendar
                if let calendars = self.ekStore.calendarsForEntityType(EKEntityTypeEvent) as? [EKCalendar] {
                    
                    // look for calendar
                    for calendar in calendars {
                        // TODO make sure iCloud source
                        if calendar.title == "Augustus" { // TODO or unique identifier?
                            self.ekCalendar = calendar
                            self.log.info?("Found calendar with id \(calendar.calendarIdentifier)")
                            break
                        }
                    }
                    
                    // if calendar not found, create it
                    if self.ekCalendar == nil {
                        // get ekSource for new calendar
                        var ekSource: EKSource? = nil
                        if let sources = self.ekStore.sources() as? [EKSource] {
                            for source in sources {
                                if source.sourceType.value == EKSourceTypeCalDAV.value &&
                                    source.title.lowercaseString == "icloud"{
                                    // TODO more robust way to get iCloud, since user can edit this
                                        ekSource = source
                                        break
                                }
                            }
                        }
                        
                        // actually create the calendar for the ekSource
                        if ekSource != nil {
                            let calendar = EKCalendar(forEntityType: EKEntityTypeEvent, eventStore: self.ekStore)
                            calendar.title = "Augustus" // TODO dup String
                            calendar.source = ekSource
                            let error = NSErrorPointer()
                            if self.ekStore.saveCalendar(calendar, commit: true, error: error) {
                                self.ekCalendar = calendar
                                self.log.info?("Created calendar with id \(calendar.calendarIdentifier)")
                            } else {
                                self.log.error?("Failed to create calendar")
                                self.log.error?(error.debugDescription)
                            }
                        } else {
                            self.log.error?("Failed to find source to create calendar")
                        }
                    }
                    
                } else {
                    self.log.error?("Failed to get list of calendars from store")
                }
                
                
                
            } else {
                self.permission = .Denied
                self.log.warn?("request to access EKEntityTypeEvents denied")
                self.log.warn?(error?.description)
                // TODO gracefully handle this
            }
            
            // notify listeners of model change
            self.log.debug?("send notification")
            NSNotificationCenter.defaultCenter().postNotificationName(AUModel.notificationName, object: self)
        })
    }
    
    /// returns true upon success, false upon failure
    func addEventOnDate(date: NSDate, description: String) -> Bool {
        // TODO
        return false
    }
    
    /// returns true if an event is removed, false upon failure or if no event is removed
    func removeEvent(event: AUEvent) -> Bool {
        // TODO
        return false
    }
    
    /// returns true upon success, false upon failure (e.g., event is not in the AUEventStore)
    func editEvent(event: AUEvent, newDate: NSDate, newDescription: String) -> Bool {
        // TODO
        return false
    }
    
    func eventsForDate(date: NSDate) -> [AUEvent] {
        // TODO
        return []
    }
    
    func eventsForWeek(week: AUWeek) -> [NSDate: [AUEvent]] {
        // TODO
        return [:]
    }
}
