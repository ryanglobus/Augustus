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
    
    fileprivate struct AUEventInEK: AUEvent {
        let id: String
        let description: String
        let date: Date
        let creationDate: Date?
        
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
                    return NSColor.black
                }
            }
            set {
                AUCoreData.instance?.setColor(newValue, forEvent: self)
            }
        }
    }
    
    fileprivate let log = AULog.instance
    fileprivate let ekStore: EKEventStore
    // TODO below use ekStore?
    fileprivate(set) var permission: AUEventStorePermission // TODO listen for changes
    fileprivate var ekCalendar_: EKCalendar?
    
    init() {
        self.ekStore = EKEventStore()
        self.permission = .pending
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.EKEventStoreChanged, object: nil, queue: nil) { (notification: Notification) in
            self.log.debug("Notification from EventKit")
            NotificationCenter.default.post(name: Notification.Name(rawValue: AUModel.notificationName), object: self)
        }
        
        self.ekStore.requestAccess(to: EKEntityType.event, completion: {(success: Bool, error: Error?) in
            // TODO refactor
            // TODO test all scenarios (a lot!)
            
            defer {
                // notify listeners of model change
                self.log.debug("send notification")
                NotificationCenter.default.post(name: Notification.Name(rawValue: AUModel.notificationName), object: self)
            }
            
            guard success else {
                self.permission = .denied
                self.log.warn("request to access EKEntityTypeEvents denied")
                self.log.warn(error?.localizedDescription)
                // TODO gracefully handle this
                return
            }
            
            self.permission = .granted
            self.log.info("request to access EKEntityTypeEvents granted")
            
            // look for calendar
            // TODO remember calendar
            let calendars = self.ekStore.calendars(for: EKEntityType.event)
            
            // look for calendar
            for calendar in calendars {
                // TODO make sure iCloud source
                if calendar.title == "Augustus" { // TODO or unique identifier?
                    self.ekCalendar_ = calendar
                    self.log.info("Found calendar with id \(calendar.calendarIdentifier)")
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
                if source.sourceType.rawValue == EKSourceType.calDAV.rawValue &&
                    source.title.lowercased() == "icloud"{
                        // TODO more robust way to get iCloud, since user can edit this
                        ekSource_ = source
                        break
                }
            }
            
            guard let ekSource = ekSource_ else {
                self.log.error("Failed to find source to create calendar")
                return
            }
            
            // actually create the calendar for the ekSource
            let calendar = EKCalendar(for: EKEntityType.event, eventStore: self.ekStore)
            calendar.title = "Augustus" // TODO dup String
            calendar.source = ekSource
            do {
                try self.ekStore.saveCalendar(calendar, commit: true)
                self.ekCalendar_ = calendar
                self.log.info("Created calendar with id \(calendar.calendarIdentifier)")
            } catch let error as NSError {
                self.log.error("Failed to create calendar")
                self.log.error(error.debugDescription)
            }

        })
    }
    
    /// returns true upon success, false upon failure
    func addEventOnDate(_ date: Date, description: String) -> AUEvent? {
        if self.permission != .granted {
            return nil
        }
        if let calendar = self.ekCalendar_ {
            let event = EKEvent(eventStore: self.ekStore)
            event.startDate = AUModel.beginningOfDate(date)
            event.endDate = event.startDate.addingTimeInterval(AUModel.oneHour)
            event.isAllDay = true
            event.title = description
            event.calendar = calendar
            do {
                try self.ekStore.save(event, span: EKSpan.thisEvent, commit: true)
                return AUEventInEK(ekEvent: event)
            } catch let error as NSError {
                self.log.error(error.debugDescription)
                return nil
            }
        }
        return nil
    }
    
    /// returns true if an event is removed, false upon failure or if no event is removed
    func removeEvent(_ event: AUEvent) -> Bool {
        if self.permission != .granted {
            return false
        }
        if let ekEvent = self.ekStore.event(withIdentifier: event.id) {
            let success: Bool
            do {
                try self.ekStore.remove(ekEvent, span: EKSpan.thisEvent, commit: true)
                success = true
            } catch let error as NSError {
                self.log.error(error.debugDescription)
                success = false
            }
            return success
        }
        return false
    }
    
    /// returns true upon success, false upon failure (e.g., event is not in the AUEventStore)
    func editEvent(_ event: AUEvent, newDate: Date, newDescription: String) -> Bool {
        if self.permission != .granted {
            return false
        }
        if let ekEvent = self.ekStore.event(withIdentifier: event.id) {
            // TODO below is dup code
            ekEvent.startDate = AUModel.beginningOfDate(newDate)
            ekEvent.endDate = ekEvent.startDate.addingTimeInterval(AUModel.oneHour)
            ekEvent.isAllDay = true
            ekEvent.title = newDescription
            let success: Bool
            do {
                try self.ekStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
                success = true
            } catch let error as NSError {
                self.log.error(error.debugDescription)
                success = false
            }
            return success
        }
        return false
    }
    
    func eventsForDate(_ date: Date) -> [AUEvent] {
        if self.permission != .granted {
            return [] // TODO return nil?
        }
        if let calendar = self.ekCalendar_ {
            let start = AUModel.beginningOfDate(date)
            let end = start.addingTimeInterval(AUModel.oneDay)
            let predicate = self.ekStore.predicateForEvents(withStart: start, end: end, calendars: [calendar])
            let ekEvents = self.ekStore.events(matching: predicate)
            return ekEvents.map({AUEventInEK(ekEvent: $0)})
        }
        return []
    }
}
