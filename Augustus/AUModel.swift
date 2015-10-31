//
//  AUModel.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Foundation
import Cocoa

struct AUModel {
    static let calendar = NSCalendar.currentCalendar()
    static let oneHour: NSTimeInterval = 60 * 60
    static let oneDay: NSTimeInterval = 60 * 60 * 24
    static let notificationName = "AUModelNotification"
    static var eventStore: AUEventStore = AUEventStoreInEK()
    
    static func beginningOfDate(date: NSDate) -> NSDate {
        let components = AUModel.calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: date)
        return AUModel.calendar.dateFromComponents(components)!
    }
}



protocol AUEvent {
    var id: String { get }
    var description: String { get }
    var date: NSDate { get }
    var creationDate: NSDate? { get }
    var color: NSColor {get set}
}

struct AUWeek { // TODO let user choose start on Sunday/Monday
    let firstDate: NSDate
    static let numDaysInWeek = 7
    
    init() {
        self.init(containingDate: NSDate())
    }
    
    init(containingDate date: NSDate) {
        var firstDate = date
        while AUModel.calendar.component(NSCalendarUnit.Weekday, fromDate: firstDate) != AUModel.calendar.firstWeekday {
            firstDate = firstDate.dateByAddingTimeInterval(-1 * AUModel.oneDay)
        }
        self.firstDate = firstDate
    }
    
    func dates() -> [NSDate] {
        var dates: [NSDate] = [firstDate]
        var date = firstDate.dateByAddingTimeInterval(AUModel.oneDay)
        while AUModel.calendar.component(NSCalendarUnit.Weekday, fromDate: date) != AUModel.calendar.firstWeekday {
            dates.append(date)
            date = date.dateByAddingTimeInterval(AUModel.oneDay)
        }
        return dates
    }
    
    func plusNumWeeks(numWeeks: Int) -> AUWeek {
        let numDays = Double(numWeeks * AUWeek.numDaysInWeek)
        let date = self.firstDate.dateByAddingTimeInterval(AUModel.oneDay * numDays)
        return AUWeek(containingDate: date)
    }
    
    subscript(index: Int) -> NSDate {
        get {
            return self.dates()[index] // TODO make more efficient
        }
    }
}

func ==(lhs: AUWeek, rhs: AUWeek) -> Bool {
    return lhs.firstDate == rhs.firstDate
}

func !=(lhs: AUWeek, rhs: AUWeek) -> Bool {
    return !(lhs == rhs)
}

enum AUEventStorePermission {
    case Granted, Pending, Denied
}

protocol AUEventStore {
    
    var permission: AUEventStorePermission { get }
    
    /// returns true upon success, false upon failure
    mutating func addEventOnDate(date: NSDate, description: String) -> AUEvent?
    
    /// returns true if an event is removed, false upon failure or if no event is removed
    mutating func removeEvent(event: AUEvent) -> Bool
    
    /// returns true upon success, false upon failure (e.g., event is not in the AUEventStore)
    mutating func editEvent(event: AUEvent, newDate: NSDate, newDescription: String) -> Bool
    
    func eventsForDate(date: NSDate) -> [AUEvent]
    
}

extension AUEventStore {
    func eventsForWeek(week: AUWeek) -> [NSDate : [AUEvent]] {
        var dateEvents = Dictionary<NSDate, Array<AUEvent>>()
        for date in week.dates() {
            dateEvents[date] = self.eventsForDate(date)
        }
        return dateEvents
    }
}


struct AUEventStoreInMemory: AUEventStore {
    private struct AUEventInMemory: AUEvent {
        let id: String
        let description: String
        let date: NSDate
        let creationDate: NSDate?
        var color: NSColor
        
        init(id: String, description: String, date: NSDate, creationDate: NSDate?) {
            self.id = id
            self.description = description
            self.date = date
            self.creationDate = creationDate
            self.color = NSColor.blackColor()
        }
    }
    
    private var dateEventDictionary = Dictionary<NSDate, Array<AUEvent>>()
    
    let permission: AUEventStorePermission = .Granted
    
    mutating func addEventOnDate(date: NSDate, description: String) -> AUEvent? {
        let event = AUEventInMemory(id: NSUUID().UUIDString, description: description, date: date, creationDate: NSDate())
        return self.addEvent(event)
    }
    
    private mutating func addEvent(event: AUEvent) -> AUEvent? {
        let date = AUModel.beginningOfDate(event.date)
        if var events = dateEventDictionary[date] {
            events.append(event)
            dateEventDictionary.updateValue(events, forKey: date)
        } else {
            dateEventDictionary.updateValue([event], forKey: date)
        }
        return event
    }
    
    // inefficient, but whatever
    mutating func editEvent(event: AUEvent, newDate: NSDate, newDescription: String) -> Bool {
        for (date, var events) in dateEventDictionary {
            for i in 0..<events.count {
                let e = events[i]
                if e.id == event.id {
                    // TODO modification while iterating?
                    let newEvent = AUEventInMemory(id: event.id, description: newDescription, date: newDate, creationDate: event.creationDate)
                    events.removeAtIndex(i)
                    if date == AUModel.beginningOfDate(newDate) { // put back in same place
                        events.insert(newEvent, atIndex: i)
                    } else { // add to another [AUEvent] in Dictionary
                        self.addEvent(newEvent)
                    }
                    dateEventDictionary[date] = events
                    return true
                }
            }
        }
        return false
    }
    
    mutating func removeEvent(event: AUEvent) -> Bool {
        for (date, var events) in dateEventDictionary {
            for i in 0..<events.count {
                if event.id == events[i].id {
                    events.removeAtIndex(i)
                    dateEventDictionary.updateValue(events, forKey: date)
                    return true
                }
            }
        }
        return false
    }
    
    func eventsForDate(var date: NSDate) -> [AUEvent] {
        date = AUModel.beginningOfDate(date)
        if let events = dateEventDictionary[date] {
            return events
        } else {
            return []
        }
    }
    
    mutating func clear() {
        dateEventDictionary.removeAll()
    }
}


