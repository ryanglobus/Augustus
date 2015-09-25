//
//  AUEventStoreInEK.swift
//  Augustus
//
//  Created by Ryan Globus on 8/7/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Foundation
import EventKit
import Cocoa

class AUEventStoreInEK : AUEventStore {
    
    private struct AUEventInEK: AUEvent {
        let id: String
        let description: String
        let date: NSDate
        let creationDate: NSDate?
        
        init(ekEvent: EKEvent) {
            self.id = ekEvent.eventIdentifier
            self.description = ekEvent.title
            self.date = ekEvent.startDate // TODO handle multi-day events
            self.creationDate = ekEvent.creationDate
        }
        
        var color: NSColor {
            get {
                if let color = AUCoreData.instance?.colorForAUEvent(self) {
                    return color
                } else {
                    return NSColor.blackColor()
                }
            }
            set {
                AUCoreData.instance?.setColor(newValue, forEvent: self)
            }
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
        
        NSNotificationCenter.defaultCenter().addObserverForName(EKEventStoreChangedNotification, object: nil, queue: nil) { (notification: NSNotification) in
            self.log.debug?("Notification from EventKit")
            NSNotificationCenter.defaultCenter().postNotificationName(AUModel.notificationName, object: self)
        }
        
        self.ekStore.requestAccessToEntityType(EKEntityType.Event, completion: {(success: Bool, error: Optional<NSError>) in
            // TODO refactor
            // TODO test all scenarios (a lot!)
            
            defer {
                // notify listeners of model change
                self.log.debug?("send notification")
                NSNotificationCenter.defaultCenter().postNotificationName(AUModel.notificationName, object: self)
            }
            
            guard success else {
                self.permission = .Denied
                self.log.warn?("request to access EKEntityTypeEvents denied")
                self.log.warn?(error?.description)
                // TODO gracefully handle this
                return
            }
            
            self.permission = .Granted
            self.log.info?("request to access EKEntityTypeEvents granted")
            
            // look for calendar
            // TODO remember calendar
            let calendars = self.ekStore.calendarsForEntityType(EKEntityType.Event)
            
            // look for calendar
            for calendar in calendars {
                // TODO make sure iCloud source
                if calendar.title == "Augustus" { // TODO or unique identifier?
                    self.ekCalendar_ = calendar
                    self.log.info?("Found calendar with id \(calendar.calendarIdentifier)")
                    break
                }
            }
            
            // if found calendar, can return
            guard self.ekCalendar_ == nil else {
                return
            }
            
            
            // calendar not found, create it
            // get ekSource for new calendar
            var ekSource_: EKSource? = nil
            for source in self.ekStore.sources {
                if source.sourceType.rawValue == EKSourceType.CalDAV.rawValue &&
                    source.title.lowercaseString == "icloud"{
                        // TODO more robust way to get iCloud, since user can edit this
                        ekSource_ = source
                        break
                }
            }
            
            guard let ekSource = ekSource_ else {
                self.log.error?("Failed to find source to create calendar")
                return
            }
            
            // actually create the calendar for the ekSource
            let calendar = EKCalendar(forEntityType: EKEntityType.Event, eventStore: self.ekStore)
            calendar.title = "Augustus" // TODO dup String
            calendar.source = ekSource
            do {
                try self.ekStore.saveCalendar(calendar, commit: true)
                self.ekCalendar_ = calendar
                self.log.info?("Created calendar with id \(calendar.calendarIdentifier)")
            } catch let error as NSError {
                self.log.error?("Failed to create calendar")
                self.log.error?(error.debugDescription)
            }

        })
    }
    
    /// returns true upon success, false upon failure
    func addEventOnDate(date: NSDate, description: String) -> AUEvent? {
        if self.permission != .Granted {
            return nil
        }
        if let calendar = self.ekCalendar_ {
            let event = EKEvent(eventStore: self.ekStore)
            event.startDate = AUModel.beginningOfDate(date)
            event.endDate = event.startDate.dateByAddingTimeInterval(AUModel.oneHour)
            event.allDay = true
            event.title = description
            event.calendar = calendar
            do {
                try self.ekStore.saveEvent(event, span: EKSpan.ThisEvent, commit: true)
                return AUEventInEK(ekEvent: event)
            } catch let error as NSError {
                self.log.error?(error.debugDescription)
                return nil
            }
        }
        return nil
    }
    
    /// returns true if an event is removed, false upon failure or if no event is removed
    func removeEvent(event: AUEvent) -> Bool {
        if self.permission != .Granted {
            return false
        }
        if let ekEvent = self.ekStore.eventWithIdentifier(event.id) {
            let success: Bool
            do {
                try self.ekStore.removeEvent(ekEvent, span: EKSpan.ThisEvent, commit: true)
                success = true
            } catch let error as NSError {
                self.log.error?(error.debugDescription)
                success = false
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
            let success: Bool
            do {
                try self.ekStore.saveEvent(ekEvent, span: EKSpan.ThisEvent, commit: true)
                success = true
            } catch let error as NSError {
                self.log.error?(error.debugDescription)
                success = false
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
            let ekEvents = self.ekStore.eventsMatchingPredicate(predicate)
            return ekEvents.map({AUEventInEK(ekEvent: $0)})
        }
        return []
    }
}
