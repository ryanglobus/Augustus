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
    
    private struct AUEventInEK: AUEvent {
        let id: String
        let description: String
        let date: NSDate
        
        init(ekEvent: EKEvent) {
            self.id = ekEvent.eventIdentifier
            self.description = ekEvent.title
            self.date = ekEvent.startDate // TODO handle multi-day events
        }
    }
    
    private let log = AULog.instance
    private let ekStore: EKEventStore
    // TODO below use ekStore?
    private(set) var permission: AUEventStorePermission // TODO listen for changes
    private var ekCalendar_: EKCalendar?
    
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
                            self.ekCalendar_ = calendar
                            self.log.info?("Found calendar with id \(calendar.calendarIdentifier)")
                            break
                        }
                    }
                    
                    // if calendar not found, create it
                    if self.ekCalendar_ == nil {
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
                                self.ekCalendar_ = calendar
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
        NSNotificationCenter.defaultCenter().addObserverForName(EKEventStoreChangedNotification, object: nil, queue: nil) { (notification: NSNotification!) in
            self.log.debug?("Notification from EventKit")
            NSNotificationCenter.defaultCenter().postNotificationName(AUModel.notificationName, object: self)
        }
    }
    
    /// returns true upon success, false upon failure
    func addEventOnDate(date: NSDate, description: String) -> Bool {
        if self.permission != .Granted {
            return false
        }
        if let calendar = self.ekCalendar_ {
            let event = EKEvent(eventStore: self.ekStore)
            event.startDate = AUModel.beginningOfDate(date)
            event.endDate = event.startDate.dateByAddingTimeInterval(AUModel.oneHour)
            event.allDay = true
            event.title = description
            event.calendar = calendar
            let error = NSErrorPointer()
            let success = self.ekStore.saveEvent(event, span: EKSpanThisEvent, commit: true, error: error)
            if !success {
                self.log.error?(error.debugDescription)
            }
            return success
        }
        return false
    }
    
    /// returns true if an event is removed, false upon failure or if no event is removed
    func removeEvent(event: AUEvent) -> Bool {
        if self.permission != .Granted {
            return false
        }
        if let ekEvent = self.ekStore.eventWithIdentifier(event.id) {
            let error = NSErrorPointer()
            let success = self.ekStore.removeEvent(ekEvent, span: EKSpanThisEvent, commit: true, error: error)
            if !success {
                self.log.error?(error.debugDescription)
            }
            return success
        }
        return false
    }
    
    /// returns true upon success, false upon failure (e.g., event is not in the AUEventStore)
    func editEvent(event: AUEvent, newDate: NSDate, newDescription: String) -> Bool {
        if self.permission != .Granted {
            return false
        }
        if let ekEvent = self.ekStore.eventWithIdentifier(event.id) {
            // TODO below is dup code
            ekEvent.startDate = AUModel.beginningOfDate(newDate)
            ekEvent.endDate = ekEvent.startDate.dateByAddingTimeInterval(AUModel.oneHour)
            ekEvent.allDay = true
            ekEvent.title = newDescription
            let error = NSErrorPointer()
            let success = self.ekStore.saveEvent(ekEvent, span: EKSpanThisEvent, commit: true, error: error)
            if !success {
                self.log.error?(error.debugDescription)
            }
            return success
        }
        return false
    }
    
    func eventsForDate(date: NSDate) -> [AUEvent] {
        if self.permission != .Granted {
            return [] // TODO return nil?
        }
        if let calendar = self.ekCalendar_ {
            let start = AUModel.beginningOfDate(date)
            let end = start.dateByAddingTimeInterval(AUModel.oneDay)
            let predicate = self.ekStore.predicateForEventsWithStartDate(start, endDate: end, calendars: [calendar])
            if let ekEvents = self.ekStore.eventsMatchingPredicate(predicate) as? [EKEvent] {
                return ekEvents.map({AUEventInEK(ekEvent: $0)})
            }
        }
        return []
    }
}
